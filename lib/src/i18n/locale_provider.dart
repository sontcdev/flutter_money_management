// path: lib/src/i18n/locale_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<String> {
  static const String _key = 'locale';

  LocaleNotifier() : super('en') {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? 'en';
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale);
    state = locale;
  }
}

