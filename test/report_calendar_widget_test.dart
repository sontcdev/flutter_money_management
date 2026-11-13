import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/report_calendar_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_date_cell.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_grid.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';

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

  Future<void> pumpCalendar(
    WidgetTester tester,
    Future<List<TransactionGroup>> Function(Ref ref) groups,
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
          transactionGroupsProvider(testMonth).overrideWith(groups),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: ReportCalendarScreen(),
        ),
      ),
    );
  }

  testWidgets('loading shows spinner, no false empty state, refreshable', (
    tester,
  ) async {
    final completer = Completer<List<TransactionGroup>>();
    await pumpCalendar(tester, (ref) => completer.future);
    await tester.pump();

    final l10n =
        AppLocalizations.of(tester.element(find.byType(ReportCalendarScreen)))!;
    expect(find.text(l10n.noTransactionsThisMonth), findsNothing);
    expect(find.byType(EmptyState), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(
      tester
          .widget<ListView>(find.descendant(
              of: find.byType(RefreshIndicator),
              matching: find.byType(ListView)))
          .physics,
      isA<AlwaysScrollableScrollPhysics>(),
    );

    completer.complete([]);
    await tester.pumpAndSettle();
    expect(find.text(l10n.noTransactionsThisMonth), findsOneWidget);
  });

  testWidgets('error shows inline Retry that refetches and succeeds', (
    tester,
  ) async {
    var calls = 0;
    await pumpCalendar(tester, (ref) async {
      calls++;
      if (calls == 1) throw Exception('boom');
      return [];
    });
    await tester.pumpAndSettle();

    final l10n =
        AppLocalizations.of(tester.element(find.byType(ReportCalendarScreen)))!;
    expect(find.text(l10n.noTransactionsThisMonth), findsNothing);
    expect(find.text(l10n.retry), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text(l10n.retry), findsNothing);
    expect(find.text(l10n.noTransactionsThisMonth), findsOneWidget);
  });

  testWidgets(
      'refresh failure after success shows Retry despite retained previous '
      'data, then Retry succeeds', (tester) async {
    var calls = 0;
    await pumpCalendar(tester, (ref) async {
      calls++;
      if (calls == 2) throw Exception('refresh failed');
      return [];
    });
    await tester.pumpAndSettle();

    final l10n =
        AppLocalizations.of(tester.element(find.byType(ReportCalendarScreen)))!;
    expect(find.text(l10n.noTransactionsThisMonth), findsOneWidget);
    expect(find.text(l10n.retry), findsNothing);

    final container = ProviderScope.containerOf(
        tester.element(find.byType(ReportCalendarScreen)));
    final month = DateTime(2025, 11, 1);
    container.invalidate(transactionGroupsProvider(month));
    await tester.pumpAndSettle();

    final state = container.read(transactionGroupsProvider(month));
    expect(state.hasError, isTrue);
    expect(state.hasValue, isTrue,
        reason: 'Riverpod retains previous data inside AsyncError');
    expect(calls, 2);
    expect(find.text(l10n.retry), findsOneWidget);
    expect(find.text(l10n.noTransactionsThisMonth), findsNothing);

    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();

    expect(calls, 3);
    expect(find.text(l10n.retry), findsNothing);
    expect(find.text(l10n.noTransactionsThisMonth), findsOneWidget);
  });

  testWidgets('actual empty data shows empty state; no search action', (
    tester,
  ) async {
    await pumpCalendar(tester, (ref) async => []);
    await tester.pumpAndSettle();

    final l10n =
        AppLocalizations.of(tester.element(find.byType(ReportCalendarScreen)))!;
    expect(find.text(l10n.noTransactionsThisMonth), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNothing);
  });

  testWidgets('CalendarDateCell distinguishes days outside the displayed month',
      (
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

    final cellFill = Theme.of(
      tester.element(find.byType(CalendarDateCell)),
    ).scaffoldBackgroundColor;

    expect(inMonthColor, isNotNull);
    expect(outOfMonthColor, isNotNull);
    expect(outOfMonthColor, isNot(inMonthColor));
    expect(
      AppSurfaceTokens.contrast(outOfMonthColor!, cellFill),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      AppSurfaceTokens.contrast(inMonthColor!, cellFill),
      greaterThanOrEqualTo(4.5),
    );
  });
}
