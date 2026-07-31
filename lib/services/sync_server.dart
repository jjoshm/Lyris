import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'foreground_sync_service.dart';
import 'lyris_crypto.dart';
import 'secure_token_store.dart';

/// Tracker-side WiFi sync: serves cycle data over HTTP with E2E encryption.
/// mDNS broadcasting is handled by [LyrisForegroundService] (battery-aware).
///
/// Security model:
/// - The pairing token (shared via QR) is NEVER transmitted over the network.
/// - It derives an AES-256-GCM key used to encrypt every response.
/// - An attacker on the same WiFi sees only authenticated ciphertext.
/// - Fresh random nonce per response prevents replay attacks.
///
/// Singleton — survives widget disposal. Sharing state is persisted in
/// SharedPreferences so the server auto-restarts on app relaunch.
class LyrisSyncServer {
  LyrisSyncServer._();
  static final LyrisSyncServer instance = LyrisSyncServer._();

  static const String serviceType = '_lyris-sync._tcp';
  static const int port = 48291;
  static const String _prefKey = 'sync_sharing_enabled';

  HttpServer? _server;
  bool _running = false;
  String? _authToken;
  SecretKey? _encryptionKey;
  Map<String, dynamic> Function()? _dataProvider;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _pausedByConnectivity = false;

  // ─── Rate limiting ────────────────────────────────────────────────────
  static const int _maxRequestsPerMinute = 30;
  final Map<String, List<int>> _requestLog = {};

  bool get isRunning => _running;

  /// Whether the user has enabled sharing (persisted across restarts).
  static Future<bool> isSharingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Persist the sharing preference.
  static Future<void> setSharingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  /// Set the data provider callback (called from widget with Riverpod access).
  void setDataProvider(Map<String, dynamic> Function() provider) {
    _dataProvider = provider;
  }

  /// Auto-start if sharing was previously enabled. Call from app init.
  static Future<void> restoreIfEnabled() async {
    if (await isSharingEnabled()) {
      try {
        await instance.start();
      } catch (e) {
        debugPrint('[LyrisSync] Failed to restore server: $e');
      }
    }
  }

  /// Generate or retrieve the persistent auth token for pairing.
  /// Stored in the platform keystore (Android Keystore / iOS Keychain).
  static Future<String> getAuthToken() async {
    var token = await SecureTokenStore.read();
    if (token == null) {
      token = _generateToken();
      await SecureTokenStore.write(token);
    }
    return token;
  }

  /// Rotate the pairing token. Invalidates the old token — any partner
  /// still using it will fail decryption and must re-pair via QR.
  /// If the server is running, the encryption key is updated in-place.
  static Future<String> rotateToken() async {
    final token = _generateToken();
    await SecureTokenStore.write(token);
    // Update the running server so it encrypts with the new key immediately.
    final server = instance;
    if (server._running) {
      server._authToken = token;
      server._encryptionKey = await LyrisCrypto.deriveKey(token);
    }
    return token;
  }

  static String _generateToken() {
    // 256 bits of CSPRNG entropy, hex-encoded, truncated to 128 bits.
    // 128 bits is well beyond brute-force reach for a local-network token.
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  /// Start HTTP server + foreground service (mDNS broadcast).
  Future<void> start({Map<String, dynamic> Function()? dataProvider}) async {
    if (_running) return;
    if (dataProvider != null) _dataProvider = dataProvider;

    _authToken = await getAuthToken();
    _encryptionKey = await LyrisCrypto.deriveKey(_authToken!);

    // Start HTTP server (main isolate — needs Riverpod data)
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen((request) => _handleRequest(request));

    // Start foreground service (battery-aware mDNS broadcast + keeps process alive)
    await LyrisForegroundService.startTracker();

    _running = true;
    _pausedByConnectivity = false;
    await setSharingEnabled(true);
    _startConnectivityListener();
    debugPrint('[LyrisSync] Encrypted server started on port $port');
  }

  /// Stop HTTP server + foreground service.
  Future<void> stop() async {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    await LyrisForegroundService.stop();
    await _server?.close(force: true);
    _server = null;
    _encryptionKey = null;
    _running = false;
    _pausedByConnectivity = false;
    await setSharingEnabled(false);
    debugPrint('[LyrisSync] Server stopped');
  }

  // ─── WiFi-aware lifecycle ─────────────────────────────────────────────

  void _startConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasWifi = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
      if (hasWifi && _pausedByConnectivity) {
        _resumeAfterWifi();
      } else if (!hasWifi && _running && !_pausedByConnectivity) {
        _pauseForNoWifi();
      }
    });
  }

  /// WiFi lost — pause foreground service + HTTP server (saves battery).
  /// Sharing preference stays enabled so we auto-resume when WiFi returns.
  void _pauseForNoWifi() {
    _pausedByConnectivity = true;
    LyrisForegroundService.stop();
    _server?.close(force: true);
    _server = null;
    debugPrint('[LyrisSync] Paused — no WiFi');
  }

  /// WiFi restored — restart server + foreground service.
  Future<void> _resumeAfterWifi() async {
    _pausedByConnectivity = false;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server!.listen((request) => _handleRequest(request));
      await LyrisForegroundService.startTracker();
      debugPrint('[LyrisSync] Resumed — WiFi back');
    } catch (e) {
      debugPrint('[LyrisSync] Resume failed: $e');
    }
  }

  void _handleRequest(HttpRequest request) async {
    // ── Rate limiting (per source IP, sliding 60s window) ──
    final ip = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    if (_isRateLimited(ip)) {
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..write(jsonEncode({'error': 'rate_limited'}));
      await request.response.close();
      return;
    }

    // NOTE: No Access-Control-Allow-Origin header. Without CORS enabled,
    // browsers block cross-origin JS from reading responses — a malicious
    // website on the same network can't exfiltrate data via the browser.

    if (request.uri.path == '/sync') {
      // The response is encrypted with the shared pairing key.
      // Without the key (from QR pairing), the ciphertext is useless —
      // so no separate auth handshake is needed.
      final data = _dataProvider?.call() ?? {};
      data['syncedAt'] = DateTime.now().toIso8601String();

      try {
        final plaintext = jsonEncode(data);
        final encrypted = await LyrisCrypto.encrypt(plaintext, _encryptionKey!);

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'v': 2, 'e': encrypted}));
      } catch (e) {
        debugPrint('[LyrisSync] Encryption error: $e');
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({'error': 'encryption_failed'}));
      }
      await request.response.close();
    } else {
      // Every other path (including the old /ping) returns a generic 404.
      // We deliberately do NOT confirm the app identity to unauthenticated
      // probes — an attacker scanning the network learns nothing.
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'error': 'not found'}));
      await request.response.close();
    }
  }

  /// Sliding-window rate limiter. Returns true if the IP exceeded the limit.
  bool _isRateLimited(String ip) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - 60000;
    final hits = _requestLog.putIfAbsent(ip, () => []);
    hits.removeWhere((t) => t < cutoff);
    hits.add(now);
    // Periodically prune stale IPs to avoid unbounded memory growth.
    if (_requestLog.length > 256) {
      _requestLog.removeWhere((k, v) => v.isEmpty || v.last < cutoff);
    }
    return hits.length > _maxRequestsPerMinute;
  }
}
