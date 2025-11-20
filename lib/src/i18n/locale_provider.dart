// path: lib/src/i18n/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'app_locale';
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final localeCode = _prefs.getString(_localeKey);
    if (localeCode != null) {
      state = Locale(localeCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  throw UnimplementedError('LocaleNotifier must be overridden');
});

