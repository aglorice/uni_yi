import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/school_credential.dart';

abstract class CredentialVault {
  Future<void> save(SchoolCredential credential);
  Future<SchoolCredential?> read();
  Future<void> clear();
}

class SecureCredentialVault implements CredentialVault {
  SecureCredentialVault(this._storage);

  static const _usernameKey = 'auth.username';
  static const _passwordKey = 'auth.password';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }

  @override
  Future<SchoolCredential?> read() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);

    if (username == null || password == null) {
      return null;
    }

    return SchoolCredential(username: username, password: password);
  }

  @override
  Future<void> save(SchoolCredential credential) async {
    await _storage.write(key: _usernameKey, value: credential.username);
    await _storage.write(key: _passwordKey, value: credential.password);
  }
}

class InMemoryCredentialVault implements CredentialVault {
  SchoolCredential? _credential;

  @override
  Future<void> clear() async {
    _credential = null;
  }

  @override
  Future<SchoolCredential?> read() async => _credential;

  @override
  Future<void> save(SchoolCredential credential) async {
    _credential = credential;
  }
}
