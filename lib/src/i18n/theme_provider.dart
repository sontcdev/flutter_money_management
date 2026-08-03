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

final themeModeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  throw UnimplementedError('ThemeNotifier must be overridden');
});

// Theme Color Provider
class ThemeColorNotifier extends StateNotifier<Color> {
  static const String _themeColorKey = 'theme_color';
  final SharedPreferences _prefs;

  // Available theme colors
  static const Map<String, Color> availableColors = {
    'blue': Color(0xFF2196F3),
    'green': Color(0xFF4CAF50),
    'purple': Color(0xFF9C27B0),
    'orange': Color(0xFFFF9800),
    'teal': Color(0xFF009688),
    'pink': Color(0xFFE91E63),
    'indigo': Color(0xFF3F51B5),
    'red': Color(0xFFF44336),
  };

  ThemeColorNotifier(this._prefs) : super(availableColors['blue']!) {
    _loadThemeColor();
  }

  void _loadThemeColor() {
    final colorValue = _prefs.getInt(_themeColorKey);
    if (colorValue != null) {
      state = Color(colorValue);
    }
  }

  Future<void> setThemeColor(Color color) async {
    await _prefs.setInt(_themeColorKey, color.toARGB32());
    state = color;
  }
}

final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, Color>((ref) {
  throw UnimplementedError('ThemeColorNotifier must be overridden');
});

// Font Scale Provider
enum FontScale {
  small(0.9),
  medium(1.0),
  large(1.15),
  extraLarge(1.3);

  const FontScale(this.multiplier);

  final double multiplier;
}

class FontScaleNotifier extends StateNotifier<FontScale> {
  static const String _fontScaleKey = 'font_scale';
  final SharedPreferences _prefs;

  FontScaleNotifier(this._prefs) : super(FontScale.medium) {
    _loadFontScale();
  }

  void _loadFontScale() {
    final index = _prefs.getInt(_fontScaleKey);
    if (index != null && index >= 0 && index < FontScale.values.length) {
      state = FontScale.values[index];
    }
  }

  Future<void> setFontScale(FontScale scale) async {
    await _prefs.setInt(_fontScaleKey, scale.index);
    state = scale;
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, FontScale>((ref) {
  throw UnimplementedError('FontScaleNotifier must be overridden');
});
