// path: lib/src/app.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';
import 'i18n/locale_provider.dart';
import 'i18n/theme_provider.dart';
import 'providers/providers.dart';

class MoneyManagementApp extends ConsumerWidget {
  const MoneyManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authService = ref.watch(authServiceProvider);

    return MaterialApp(
      title: 'Money Manager',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: authService.isLoggedIn ? '/home' : '/login',
    );
  }
}

