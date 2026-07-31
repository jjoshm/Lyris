import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage for the WiFi-sync pairing token.
///
/// The token is the ONLY secret protecting the E2E-encrypted sync payload,
/// so it must never sit in plaintext [SharedPreferences] (readable via ADB
/// backup or on a rooted device). It lives in the platform keystore instead:
/// Android Keystore / iOS Keychain via flutter_secure_storage.
///
/// Reads transparently migrate any legacy plaintext token left over from
/// older builds, then delete the insecure copy.
class SecureTokenStore {
  SecureTokenStore._();

  static const String _key = 'sync_auth_token';
  static const String _legacyKey = 'sync_auth_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Read the pairing token, migrating a legacy plaintext copy if present.
  static Future<String?> read() async {
    try {
      final secure = await _storage.read(key: _key);
      if (secure != null) return secure;
    } catch (e) {
      debugPrint('[SecureTokenStore] secure read failed: $e');
    }

    // Legacy migration: move plaintext SharedPreferences token into the keystore.
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null) {
        await _storage.write(key: _key, value: legacy);
        await prefs.remove(_legacyKey);
        debugPrint('[SecureTokenStore] migrated legacy token to secure storage');
        return legacy;
      }
    } catch (e) {
      debugPrint('[SecureTokenStore] legacy migration failed: $e');
    }
    return null;
  }

  /// Persist the pairing token in the platform keystore.
  static Future<void> write(String token) async {
    await _storage.write(key: _key, value: token);
    // Ensure no plaintext copy lingers from an older build.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKey);
    } catch (_) {}
  }

  /// Delete the pairing token (unpair).
  static Future<void> delete() async {
    await _storage.delete(key: _key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKey);
    } catch (_) {}
  }
}
