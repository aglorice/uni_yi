import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;

class CredentialTransformer {
  CredentialTransformer({Random? random}) : _random = random ?? Random();

  static const _aesChars = 'ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678';

  final Random _random;

  String encryptPassword(String password, String salt) {
    if (salt.isEmpty) {
      return password;
    }

    final plain = '${_randomString(64)}$password';
    final key = encrypt.Key.fromUtf8(salt);
    final iv = encrypt.IV.fromUtf8(_randomString(16));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    return encrypter.encrypt(plain, iv: iv).base64;
  }

  String _randomString(int length) {
    return List.generate(
      length,
      (_) => _aesChars[_random.nextInt(_aesChars.length)],
    ).join();
  }
}
