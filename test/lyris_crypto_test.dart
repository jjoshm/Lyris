import 'package:flutter_test/flutter_test.dart';
import 'package:lyris_tracker/services/lyris_crypto.dart';

void main() {
  group('LyrisCrypto', () {
    test('deriveKey produces consistent key from same token', () async {
      final key1 = await LyrisCrypto.deriveKey('test-token-123');
      final key2 = await LyrisCrypto.deriveKey('test-token-123');
      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();
      expect(bytes1, equals(bytes2));
    });

    test('deriveKey produces different keys for different tokens', () async {
      final key1 = await LyrisCrypto.deriveKey('token-a');
      final key2 = await LyrisCrypto.deriveKey('token-b');
      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();
      expect(bytes1, isNot(equals(bytes2)));
    });

    test('encrypt/decrypt roundtrip preserves plaintext', () async {
      final key = await LyrisCrypto.deriveKey('my-secret-token');
      const plaintext = '{"phase":"follicular","cycleDay":7,"confidence":0.85}';

      final encrypted = await LyrisCrypto.encrypt(plaintext, key);
      final decrypted = await LyrisCrypto.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('encrypt produces different ciphertext each time (random nonce)', () async {
      final key = await LyrisCrypto.deriveKey('my-secret-token');
      const plaintext = 'same message';

      final enc1 = await LyrisCrypto.encrypt(plaintext, key);
      final enc2 = await LyrisCrypto.encrypt(plaintext, key);

      // Different nonces → different ciphertext
      expect(enc1, isNot(equals(enc2)));

      // But both decrypt to the same plaintext
      expect(await LyrisCrypto.decrypt(enc1, key), equals(plaintext));
      expect(await LyrisCrypto.decrypt(enc2, key), equals(plaintext));
    });

    test('decrypt with wrong key throws SecretBoxAuthenticationError', () async {
      final key1 = await LyrisCrypto.deriveKey('correct-token');
      final key2 = await LyrisCrypto.deriveKey('wrong-token');
      const plaintext = '{"secret":"data"}';

      final encrypted = await LyrisCrypto.encrypt(plaintext, key1);

      expect(
        () => LyrisCrypto.decrypt(encrypted, key2),
        throwsA(isA<Exception>()),
      );
    });

    test('decrypt tampered ciphertext throws', () async {
      final key = await LyrisCrypto.deriveKey('my-token');
      const plaintext = '{"data":"important"}';

      final encrypted = await LyrisCrypto.encrypt(plaintext, key);

      // Tamper with the ciphertext (flip a character in the middle)
      final chars = encrypted.split('');
      final mid = chars.length ~/ 2;
      chars[mid] = chars[mid] == 'A' ? 'B' : 'A';
      final tampered = chars.join();

      expect(
        () => LyrisCrypto.decrypt(tampered, key),
        throwsA(isA<Exception>()),
      );
    });

    test('decrypt too-short payload throws FormatException', () async {
      final key = await LyrisCrypto.deriveKey('my-token');
      expect(
        () => LyrisCrypto.decrypt('c2hvcnQ=', key), // "short" in base64
        throwsA(isA<FormatException>()),
      );
    });

    test('encrypt handles unicode content', () async {
      final key = await LyrisCrypto.deriveKey('unicode-token');
      const plaintext = '{"phase":"Periode 🩸","label":"Tag 3 – starke Blutung"}';

      final encrypted = await LyrisCrypto.encrypt(plaintext, key);
      final decrypted = await LyrisCrypto.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('encrypt handles large payload', () async {
      final key = await LyrisCrypto.deriveKey('large-token');
      final plaintext = '{"data":"${'x' * 10000}"}';

      final encrypted = await LyrisCrypto.encrypt(plaintext, key);
      final decrypted = await LyrisCrypto.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });
  });
}
