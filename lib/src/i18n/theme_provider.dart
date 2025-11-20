// path: lib/src/i18n/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(ThemeMode.light) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final themeModeIndex = _prefs.getInt(_themeModeKey);
    if (themeModeIndex != null) {
      state = ThemeMode.values[themeModeIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_themeModeKey, mode.index);
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  throw UnimplementedError('ThemeNotifier must be overridden');
});

