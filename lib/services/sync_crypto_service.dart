import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class SyncCryptoService {
  static final SyncCryptoService instance = SyncCryptoService._init();
  SyncCryptoService._init();
  factory SyncCryptoService() => instance;

  /// Derives a 32-byte (256-bit) AES key from a pair secret string or 6-digit code.
  enc.Key deriveKey(String secret) {
    final bytes = utf8.encode(secret.trim());
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts a raw text string (e.g. JSON note manifest/payload) into a base64 ciphertext with IV.
  String? encryptPayload(String rawText, String secretKey) {
    try {
      final key = deriveKey(secretKey);
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(rawText, iv: iv);
      
      final payloadMap = {
        'iv': iv.base64,
        'data': encrypted.base64,
      };
      return base64.encode(utf8.encode(json.encode(payloadMap)));
    } catch (_) {
      return null;
    }
  }

  /// Decrypts a base64 ciphertext string back to raw text payload.
  String? decryptPayload(String encryptedBase64Payload, String secretKey) {
    try {
      final decodedJson = utf8.decode(base64.decode(encryptedBase64Payload));
      final map = json.decode(decodedJson) as Map<String, dynamic>;
      
      final iv = enc.IV.fromBase64(map['iv'] as String);
      final encryptedData = enc.Encrypted.fromBase64(map['data'] as String);
      
      final key = deriveKey(secretKey);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      if (decrypted.trim().isEmpty) return null;
      try {
        json.decode(decrypted);
      } catch (_) {
        // Return null if wrong key produced unparseable garbage text
        return null;
      }
      return decrypted;
    } catch (_) {
      return null;
    }
  }
}
