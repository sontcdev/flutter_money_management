// path: test/report_calendar_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/ui/screens/report_calendar_screen.dart';
import 'package:flutter_money_management/src/providers/report_providers.dart';
import 'package:flutter_money_management/src/models/transaction.dart';
import 'package:flutter_money_management/src/ui/widgets/calendar_grid.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('ReportCalendarScreen Widget Tests', () {
    late DateTime testMonth;
    late Map<DateTime, List<AmountBadge>> testCalendarData;
    late Map<String, int> testSummary;
    late List<TransactionGroup> testGroups;

    setUp(() {
      testMonth = DateTime(2025, 11, 1);

      // Sample calendar data
      testCalendarData = {
        DateTime(2025, 11, 5): [
          AmountBadge(amountCents: 50000 * 100, isIncome: false),
          AmountBadge(amountCents: 200000 * 100, isIncome: true),
        ],
      };

      // Sample summary
      testSummary = {
        'income': 15000000 * 100,
        'expense': 8500000 * 100,
        'net': 6500000 * 100,
      };

      // Sample transaction groups
      testGroups = [
        TransactionGroup(
          date: DateTime(2025, 11, 5),
          netAmount: -200000 * 100,
          transactions: [
            TransactionWithCategory(
              transaction: Transaction(
                id: 1,
                amountCents: 50000 * 100,
                currency: 'VND',
                dateTime: DateTime(2025, 11, 5),
                categoryId: 1,
                type: TransactionType.expense,
                note: 'Ăn trưa',
                createdAt: DateTime(2025, 11, 5),
                updatedAt: DateTime(2025, 11, 5),
              ),
              categoryName: 'Ăn uống',
            ),
          ],
        ),
      ];
    });

    Widget createTestWidget(List<Override> overrides) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('vi'),
          ],
          locale: const Locale('vi'),
          home: const ReportCalendarScreen(),
        ),
      );
    }

    testWidgets('displays month label and navigation chevrons', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget([
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => testCalendarData),
          monthlySummaryProvider(testMonth).overrideWith((ref) => testSummary),
          transactionGroupsProvider(testMonth).overrideWith((ref) => testGroups),
        ]),
      );

      await tester.pumpAndSettle();

      // Check for navigation chevrons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Check for month label (contains month/year)
      expect(find.textContaining('11/2025'), findsOneWidget);
    });

    testWidgets('displays summary bar with income, expense, and net', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget([
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => testCalendarData),
          monthlySummaryProvider(testMonth).overrideWith((ref) => testSummary),
          transactionGroupsProvider(testMonth).overrideWith((ref) => testGroups),
        ]),
      );

      await tester.pumpAndSettle();

      // Check for summary labels
      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('Tổng'), findsOneWidget);

      // Check for amounts (formatted)
      expect(find.textContaining('15.000.000'), findsOneWidget);
      expect(find.textContaining('8.500.000'), findsOneWidget);
      expect(find.textContaining('6.500.000'), findsOneWidget);
    });

    testWidgets('displays calendar grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget([
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => testCalendarData),
          monthlySummaryProvider(testMonth).overrideWith((ref) => testSummary),
          transactionGroupsProvider(testMonth).overrideWith((ref) => testGroups),
        ]),
      );

      await tester.pumpAndSettle();

      // Check for calendar grid widget
      expect(find.byType(CalendarGrid), findsOneWidget);

      // Check for weekday headers
      expect(find.text('T2'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
    });

    testWidgets('displays transaction list with group header', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget([
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => testCalendarData),
          monthlySummaryProvider(testMonth).overrideWith((ref) => testSummary),
          transactionGroupsProvider(testMonth).overrideWith((ref) => testGroups),
        ]),
      );

      await tester.pumpAndSettle();

      // Check for transaction group date
      expect(find.textContaining('05/11/2025'), findsOneWidget);

      // Check for transaction item
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Ăn trưa'), findsOneWidget);
    });

    testWidgets('displays search icon in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget([
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => testCalendarData),
          monthlySummaryProvider(testMonth).overrideWith((ref) => testSummary),
          transactionGroupsProvider(testMonth).overrideWith((ref) => testGroups),
        ]),
      );

      await tester.pumpAndSettle();

      // Check for search icon
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('handles pull to refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget([
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => testCalendarData),
          monthlySummaryProvider(testMonth).overrideWith((ref) => testSummary),
          transactionGroupsProvider(testMonth).overrideWith((ref) => testGroups),
        ]),
      );

      await tester.pumpAndSettle();

      // Find RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('displays transaction chevron for navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget([
          selectedMonthProvider.overrideWith((ref) => testMonth),
          calendarDataProvider(testMonth).overrideWith((ref) => testCalendarData),
          monthlySummaryProvider(testMonth).overrideWith((ref) => testSummary),
          transactionGroupsProvider(testMonth).overrideWith((ref) => testGroups),
        ]),
      );

      await tester.pumpAndSettle();

      // Check for chevron_right icons in transaction items
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });
  });
}

