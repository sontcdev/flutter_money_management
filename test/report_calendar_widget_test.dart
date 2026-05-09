import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/report_calendar_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_grid.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

void main() {
  testWidgets('ReportCalendarScreen builds with overridden providers', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testMonth = DateTime(2025, 11, 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
          themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
          themeColorProvider.overrideWith((ref) => ThemeColorNotifier(prefs)),
          monthStartDayProvider
              .overrideWith((ref) => MonthStartDayNotifier(prefs)),
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => {}),
          monthlySummaryProvider(testMonth).overrideWith(
            (ref) => {'income': 0, 'expense': 0, 'net': 0},
          ),
          transactionGroupsProvider(testMonth).overrideWith((ref) => []),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: const ReportCalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ReportCalendarScreen), findsOneWidget);
    expect(find.byType(CalendarGrid), findsOneWidget);
  });
}
