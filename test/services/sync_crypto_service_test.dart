import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/sync_crypto_service.dart';

void main() {
  group('SyncCryptoService Tests', () {
    final crypto = SyncCryptoService.instance;
    const testSecret = '482910';
    const testPayload = '{"id":"note_123","title":"Hello World","content":"Delta text"}';

    test('derives 256-bit key consistently from pair secret', () {
      final key1 = crypto.deriveKey(testSecret);
      final key2 = crypto.deriveKey(testSecret);
      expect(key1.bytes, equals(key2.bytes));
    });

    test('encrypts and decrypts payload correctly with same key', () {
      final encrypted = crypto.encryptPayload(testPayload, testSecret);
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(equals(testPayload)));

      final decrypted = crypto.decryptPayload(encrypted!, testSecret);
      expect(decrypted, equals(testPayload));
    });

    test('returns null when decrypting with wrong key', () {
      final encrypted = crypto.encryptPayload(testPayload, testSecret);
      expect(encrypted, isNotNull);

      final decrypted = crypto.decryptPayload(encrypted!, '999999');
      expect(decrypted, isNull);
    });
  });
}
