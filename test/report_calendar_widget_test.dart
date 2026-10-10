import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/report_calendar_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_date_cell.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_grid.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';

Future<void> _pumpCalendar(
  WidgetTester tester, {
  Future<Map<DateTime, List<AmountBadge>>> Function()? calendarData,
  Future<Map<String, int>> Function()? summary,
}) async {
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
        calendarDataProvider(testMonth).overrideWith(
          (ref) => calendarData?.call() ?? Future.value({}),
        ),
        monthlySummaryProvider(testMonth).overrideWith(
          (ref) =>
              summary?.call() ??
              Future.value({'income': 0, 'expense': 0, 'net': 0}),
        ),
        transactionGroupsProvider(testMonth).overrideWith((ref) => []),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('vi')],
        home: ReportCalendarScreen(),
      ),
    ),
  );
}

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
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('vi')],
          home: ReportCalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ReportCalendarScreen), findsOneWidget);
    expect(find.byType(CalendarGrid), findsOneWidget);
  });

  testWidgets('calendar shows a skeleton while loading', (tester) async {
    final completer = Completer<Map<DateTime, List<AmountBadge>>>();
    await _pumpCalendar(tester, calendarData: () => completer.future);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SectionSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete({});
    await tester.pumpAndSettle();
    expect(find.byType(CalendarGrid), findsOneWidget);
  });

  testWidgets('summary error offers a retry', (tester) async {
    await _pumpCalendar(
      tester,
      summary: () => Future.error(Exception('offline')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InlineLoadErrorState), findsOneWidget);
  });

  testWidgets('month navigation buttons have tooltips', (tester) async {
    await _pumpCalendar(tester);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Previous month'), findsOneWidget);
    expect(find.byTooltip('Next month'), findsOneWidget);
  });

  testWidgets('CalendarDateCell dims days outside the displayed month', (
    WidgetTester tester,
  ) async {
    final displayedMonth = DateTime(2020, 1, 1);

    Future<Color?> dayColor(DateTime date) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDateCell(
              date: date,
              displayedMonth: displayedMonth,
              badges: const [],
              onTap: () {},
            ),
          ),
        ),
      );
      return tester.widget<Text>(find.text(date.day.toString())).style?.color;
    }

    final inMonthColor = await dayColor(DateTime(2020, 1, 15));
    final outOfMonthColor = await dayColor(DateTime(2020, 2, 2));

    expect(inMonthColor?.a, 1.0);
    expect(outOfMonthColor?.a, closeTo(0.4, 0.01));
  });
}
