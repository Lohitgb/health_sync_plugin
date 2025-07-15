import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptService {
  static const _storage = FlutterSecureStorage();
  static const _keyStorageKey = 'aes_key';

  static Future<Encrypter> _getEncrypter() async {
    String? keyStr = await _storage.read(key: _keyStorageKey);

    if (keyStr == null) {
      final key = List<int>.generate(32, (i) => Random.secure().nextInt(256));
      keyStr = base64UrlEncode(key);
      await _storage.write(key: _keyStorageKey, value: keyStr);
    }

    final key = Key(base64Url.decode(keyStr));
    return Encrypter(AES(key, mode: AESMode.cbc));
  }

  static Future<Map<String, String>> encryptText(String plainText) async {
    final encrypter = await _getEncrypter();
    final iv = IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return {
      'iv': base64Encode(iv.bytes),
      'data': encrypted.base64,
    };
  }

  static Future<String> decryptText(String encryptedData, String ivBase64) async {
    final encrypter = await _getEncrypter();
    final iv = IV(base64Decode(ivBase64));
    final encrypted = Encrypted.fromBase64(encryptedData);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
