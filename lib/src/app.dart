// path: lib/src/app.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';
import 'i18n/locale_provider.dart';
import 'i18n/theme_provider.dart';
import 'ui/widgets/auth_callback_feedback_listener.dart';
import 'utils/responsive.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

class MoneyManagementApp extends ConsumerWidget {
  const MoneyManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'MyMoney',
      theme: AppTheme.lightTheme(primaryColor: themeColor),
      darkTheme: AppTheme.darkTheme(primaryColor: themeColor),
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
        Locale('ja'),
        Locale('vi'),
      ],
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Initialize responsive dimensions
        Responsive.init(context);

        // Calculate text scale factor based on screen width
        final screenWidth = MediaQuery.of(context).size.width;
        double textScaleFactor = 1.0;

        if (screenWidth >= 900) {
          // Large tablets (iPad Pro)
          textScaleFactor = 1.5;
        } else if (screenWidth >= 600) {
          // Tablets (iPad)
          textScaleFactor = 1.35;
        }

        // Apply text scaling for tablets
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: AuthCallbackFeedbackListener(child: child!),
        );
      },
    );
  }
}
