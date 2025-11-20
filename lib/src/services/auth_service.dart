// path: lib/src/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _pinKey = 'user_pin';

  final SharedPreferences _prefs;

  AuthService(this._prefs);

  bool get isLoggedIn => _prefs.getBool(_isLoggedInKey) ?? false;

  Future<void> login(String pin) async {
    await _prefs.setString(_pinKey, pin);
    await _prefs.setBool(_isLoggedInKey, true);
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = _prefs.getString(_pinKey);
    return savedPin == pin;
  }

  Future<void> logout() async {
    await _prefs.setBool(_isLoggedInKey, false);
  }

  bool hasPin() {
    return _prefs.getString(_pinKey) != null;
  }
}

