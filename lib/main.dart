// path: lib/main.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app.dart';
import 'src/providers/providers.dart';
import 'src/i18n/locale_provider.dart';
import 'src/i18n/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        localeProvider.overrideWith((ref) => LocaleNotifier(sharedPreferences)),
        themeModeProvider.overrideWith((ref) => ThemeNotifier(sharedPreferences)),
      ],
      child: const MoneyManagementApp(),
    ),
  );
}

