import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_session.dart';

abstract class SessionStore {
  Future<void> save(AppSession session);
  Future<AppSession?> read();
  Future<void> clear();
}

class SharedPreferencesSessionStore implements SessionStore {
  SharedPreferencesSessionStore(this._preferences);

  static const _sessionKey = 'auth.session';

  final SharedPreferences _preferences;

  @override
  Future<void> clear() async {
    await _preferences.remove(_sessionKey);
  }

  @override
  Future<AppSession?> read() async {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return AppSession.fromJson(decoded);
  }

  @override
  Future<void> save(AppSession session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }
}
