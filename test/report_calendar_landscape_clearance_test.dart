import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/report_calendar_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_grid.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/summary_bar.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

void main() {
  for (final locale in ['en', 'vi', 'ja']) {
    testWidgets(
        'landscape 844x390 scale 1.3 reaches last week and totals '
        '($locale)', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Nov 2025 spans six week rows (starts on Saturday).
      final month = DateTime(2025, 11, 1);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
          themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
          themeColorProvider.overrideWith((ref) => ThemeColorNotifier(prefs)),
          monthStartDayProvider
              .overrideWith((ref) => MonthStartDayNotifier(prefs)),
          selectedMonthProvider.overrideWith((ref) => month),
          calendarDataProvider(month).overrideWith((ref) => {}),
          monthlySummaryProvider(month).overrideWith(
            (ref) => {'income': 12000000, 'expense': 3000000, 'net': 9000000},
          ),
          transactionGroupsProvider(month).overrideWith((ref) => []),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const ReportCalendarScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The calendar section is the scrollable that contains the grid.
      final calendarScrollable = find
          .descendant(
              of: find.byType(ReportCalendarScreen),
              matching: find.byType(Scrollable))
          .first;
      expect(
          find.descendant(
              of: calendarScrollable, matching: find.byType(CalendarGrid)),
          findsOneWidget);

      await tester.drag(calendarScrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      final viewport = tester.getRect(calendarScrollable);
      final totals = tester.getRect(find.byType(SummaryBar));
      expect(totals.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
      expect(totals.top, greaterThanOrEqualTo(viewport.top));
      // Last day of the displayed month (last week row) is reachable too.
      final lastDay = find.descendant(
          of: find.byType(CalendarGrid), matching: find.text('30'));
      expect(lastDay, findsWidgets);
      expect(tester.getRect(lastDay.first).bottom,
          lessThanOrEqualTo(viewport.bottom));
      expect(tester.takeException(), isNull);
    });
  }
}
