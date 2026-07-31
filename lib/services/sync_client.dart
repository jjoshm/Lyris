import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'lyris_crypto.dart';
import 'secure_token_store.dart';

/// Partner-side WiFi sync: discovers Lyris Tracker via mDNS and fetches
/// E2E-encrypted data. The pairing token is used only to derive the
/// decryption key — it is NEVER sent over the network.
class LyrisSyncClient {
  static const String serviceType = '_lyris-sync._tcp';

  BonsoirDiscovery? _discovery;
  String? _serverHost;
  int? _serverPort;
  bool _discovering = false;

  bool get isDiscovering => _discovering;
  bool get hasServer => _serverHost != null;

  /// Save pairing info (auth token from QR code) into the platform keystore.
  static Future<void> savePairing(String authToken) async {
    await SecureTokenStore.write(authToken);
  }

  /// Get stored auth token from the platform keystore.
  static Future<String?> getAuthToken() async {
    return SecureTokenStore.read();
  }

  /// Decrypt a stored sync envelope (`{"v":2,"e":<ciphertext>}`) into the
  /// partner data map. Used to read the on-device cache, which is kept as
  /// authenticated ciphertext at rest (never plaintext). Returns null if
  /// there is no pairing token, the envelope is malformed, or the payload
  /// fails authentication (e.g. the token was rotated).
  static Future<Map<String, dynamic>?> decryptEnvelope(String envelopeJson) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) return null;
      final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
      if (envelope['v'] != 2 || envelope['e'] == null) return null;
      final key = await LyrisCrypto.deriveKey(authToken);
      final plaintext = await LyrisCrypto.decrypt(envelope['e'] as String, key);
      return jsonDecode(plaintext) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[LyrisSync] Failed to decrypt cached partner data: $e');
      return null;
    }
  }

  /// Encrypt a partner data map into a storable envelope string, using the
  /// pairing key. Used for the QR-pairing path, where the initial share
  /// arrives as plaintext (decoded locally from the code) and must be
  /// encrypted before it is cached. Returns null if not paired.
  static Future<String?> encryptEnvelope(Map<String, dynamic> data) async {
    final authToken = await getAuthToken();
    if (authToken == null) return null;
    final key = await LyrisCrypto.deriveKey(authToken);
    final ciphertext = await LyrisCrypto.encrypt(jsonEncode(data), key);
    return jsonEncode({'v': 2, 'e': ciphertext});
  }

  /// Start mDNS discovery to find the tracker on the local network.
  ///
  /// [onData] receives the decrypted partner data (for immediate display)
  /// plus the raw encrypted envelope string (for caching at rest — the
  /// cache is never stored as plaintext).
  Future<void> startDiscovery({
    required void Function(Map<String, dynamic> data, String envelopeJson) onData,
    required void Function(String error) onError,
    void Function()? onServerFound,
  }) async {
    // Reset state so repeated calls always work
    await stopDiscovery();
    _serverHost = null;
    _serverPort = null;
    _discovering = true;

    final authToken = await getAuthToken();
    if (authToken == null) {
      onError('Not paired yet. Scan the QR code first.');
      _discovering = false;
      return;
    }

    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) async {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        final service = event.service;
        if (service != null) {
          debugPrint('[LyrisSync] Found: ${service.name} — resolving…');
          await service.resolve(_discovery!.serviceResolver);
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final resolved = event.service as ResolvedBonsoirService;
        debugPrint('[LyrisSync] Resolved: ${resolved.name} at ${resolved.host}:${resolved.port}');
        _serverHost = resolved.host;
        _serverPort = resolved.port;
        onServerFound?.call();

        // Immediately fetch data
        await _fetchData(authToken, onData, onError);
      }
    });

    await _discovery!.start();
    debugPrint('[LyrisSync] Discovery started');

    // Auto-stop after 30 seconds if nothing found
    Future.delayed(const Duration(seconds: 30), () {
      if (_discovering && _serverHost == null) {
        _discovering = false;
        onError('No Lyris Tracker found on this network. Make sure both devices are on the same WiFi.');
        stopDiscovery();
      }
    });
  }

  /// Fetch and decrypt data from the discovered server.
  Future<void> _fetchData(
    String authToken,
    void Function(Map<String, dynamic> data, String envelopeJson) onData,
    void Function(String error) onError,
  ) async {
    if (_serverHost == null || _serverPort == null) return;

    try {
      final key = await LyrisCrypto.deriveKey(authToken);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(
        Uri.parse('http://$_serverHost:$_serverPort/sync'),
      );
      // No token header — the token never leaves the device.
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final envelope = jsonDecode(body) as Map<String, dynamic>;

        if (envelope['v'] == 2 && envelope['e'] != null) {
          // Encrypted payload — decrypt with shared key
          try {
            final plaintext = await LyrisCrypto.decrypt(envelope['e'] as String, key);
            final data = jsonDecode(plaintext) as Map<String, dynamic>;
            // Hand back the decrypted data AND the raw envelope so the
            // caller can cache the ciphertext verbatim (encrypted at rest).
            onData(data, body);
            debugPrint('[LyrisSync] Encrypted data received and decrypted ✓');
          } on SecretBoxAuthenticationError {
            onError('Decryption failed — pairing key mismatch. Please re-scan the QR code.');
          }
        } else {
          // v1 plaintext payloads are rejected — all sync must be encrypted.
          onError('Incompatible sync version. Please update Lyris Tracker.');
          debugPrint('[LyrisSync] REJECTED: unencrypted v1 payload');
        }
      } else {
        onError('Server error (${response.statusCode})');
      }
      client.close();
    } catch (e) {
      onError('Connection failed: $e');
    }
  }

  /// Manual refresh — always do fresh discovery (IP might have changed).
  Future<void> refresh({
    required void Function(Map<String, dynamic> data, String envelopeJson) onData,
    required void Function(String error) onError,
    void Function()? onServerFound,
  }) async {
    await startDiscovery(onData: onData, onError: onError, onServerFound: onServerFound);
  }

  /// Stop discovery.
  Future<void> stopDiscovery() async {
    await _discovery?.stop();
    _discovery = null;
    _discovering = false;
    debugPrint('[LyrisSync] Discovery stopped');
  }
}
