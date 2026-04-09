import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/school_credential.dart';

const _usernameKey = 'auth.username';
const _passwordKey = 'auth.password';

abstract class CredentialVault {
  Future<void> save(SchoolCredential credential);
  Future<SchoolCredential?> read();
  Future<void> clear();
}

class SecureCredentialVault implements CredentialVault {
  SecureCredentialVault(this._storage);

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

class SharedPreferencesCredentialVault implements CredentialVault {
  SharedPreferencesCredentialVault(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<void> clear() async {
    await _preferences.remove(_usernameKey);
    await _preferences.remove(_passwordKey);
  }

  @override
  Future<SchoolCredential?> read() async {
    final username = _preferences.getString(_usernameKey);
    final password = _preferences.getString(_passwordKey);

    if (username == null || password == null) {
      return null;
    }

    return SchoolCredential(username: username, password: password);
  }

  @override
  Future<void> save(SchoolCredential credential) async {
    await _preferences.setString(_usernameKey, credential.username);
    await _preferences.setString(_passwordKey, credential.password);
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
