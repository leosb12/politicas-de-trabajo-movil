import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage(this._preferences);

  static const String _sessionKey = 'auth.session';

  final SharedPreferences _preferences;

  Future<void> saveSession(Map<String, dynamic> json) async {
    await _preferences.setString(_sessionKey, jsonEncode(json));
  }

  Map<String, dynamic>? readSession() {
    final String? rawSession = _preferences.getString(_sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(rawSession);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _preferences.remove(_sessionKey);
  }
}
