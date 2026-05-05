// path: lib/src/services/email_persistence_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist user email across sessions
class EmailPersistenceService {
  static const String _emailKey = 'saved_user_email';
  final SharedPreferences _prefs;

  EmailPersistenceService(this._prefs);

  /// Save email to local storage
  Future<void> saveEmail(String email) async {
    await _prefs.setString(_emailKey, email);
  }

  /// Get saved email, returns null if not found
  String? getSavedEmail() {
    return _prefs.getString(_emailKey);
  }

  /// Clear saved email
  Future<void> clearEmail() async {
    await _prefs.remove(_emailKey);
  }

  /// Check if email is saved
  bool hasEmail() {
    return _prefs.containsKey(_emailKey);
  }
}
