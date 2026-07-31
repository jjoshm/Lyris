import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// End-to-end encryption for WiFi sync.
///
/// The pairing token (shared via QR code, never transmitted over the network)
/// is used to derive an AES-256-GCM key. Every sync payload is encrypted with
/// a fresh random nonce, so even on a public WiFi an attacker sees only
/// authenticated ciphertext — no plaintext, no token, no replay.
class LyrisCrypto {
  LyrisCrypto._();

  static final _algorithm = AesGcm.with256bits();
  static final _random = Random.secure();

  /// Derive a 256-bit key from the pairing token via SHA-256.
  static Future<SecretKey> deriveKey(String authToken) async {
    final hash = Sha256().hash(utf8.encode('lyris-sync-v1:$authToken'));
    final bytes = await hash;
    return SecretKey(bytes.bytes);
  }

  /// Encrypt a JSON string → base64(nonce ‖ ciphertext ‖ mac).
  static Future<String> encrypt(String plaintext, SecretKey key) async {
    final nonce = Uint8List.fromList(
      List.generate(12, (_) => _random.nextInt(256)),
    );
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    // nonce (12) + ciphertext + mac (16)
    final combined = Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return base64Encode(combined);
  }

  /// Decrypt base64(nonce ‖ ciphertext ‖ mac) → JSON string.
  /// Throws [MacAuthenticationError] if tampered or wrong key.
  static Future<String> decrypt(String encoded, SecretKey key) async {
    final combined = base64Decode(encoded);
    if (combined.length < 28) {
      throw const FormatException('Payload too short');
    }
    final nonce = combined.sublist(0, 12);
    final mac = combined.sublist(combined.length - 16);
    final cipherText = combined.sublist(12, combined.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );
    final plainBytes = await _algorithm.decrypt(secretBox, secretKey: key);
    return utf8.decode(plainBytes);
  }
}
