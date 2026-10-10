import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/report_calendar_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/reports_screen.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_date_cell.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';

void main() {
  for (final locale in ['en', 'vi', 'ja']) {
    for (final size in [const Size(844, 390), const Size(1366, 1024)]) {
      testWidgets('Populated calendar fits $locale $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final month = DateTime(2026, 10);
        final date = DateTime(2026, 10, 15);
        final transaction = model.Transaction(
          id: 'expense',
          amountCents: 3000000,
          currency: 'VND',
          dateTime: date,
          type: model.TransactionType.expense,
          categoryId: 'food',
          walletId: 'cash',
          note: 'Lunch with friends',
          createdAt: date,
          updatedAt: date,
        );
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            selectedMonthProvider.overrideWith((ref) => month),
            calendarDataProvider(month).overrideWith((ref) async => {
                  date: [
                    AmountBadge(amountCents: 3000000, isIncome: false),
                    AmountBadge(amountCents: 10000000, isIncome: true),
                  ],
                }),
            monthlySummaryProvider(month).overrideWith((ref) async => {
                  'income': 10000000,
                  'expense': 3000000,
                  'net': 7000000,
                }),
            transactionGroupsProvider(month).overrideWith((ref) async => [
                  TransactionGroup(
                    date: date,
                    totalIncome: 0,
                    totalExpense: 3000000,
                    transactions: [
                      TransactionWithCategory(
                        transaction: transaction,
                        categoryName: 'Food and dining',
                        categoryIconName: 'restaurant',
                        categoryColorValue: 0xff2196f3,
                      ),
                    ],
                  ),
                ]),
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
        final day = find.byWidgetPredicate(
            (widget) => widget is CalendarDateCell && widget.date == date);
        await tester.ensureVisible(day);
        await tester.tap(day);
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
            tester.element(find.byType(ReportCalendarScreen)));
        expect(container.read(selectedDateProvider), date);
        await tester.ensureVisible(find.byType(TransactionListItem));
        await tester.pumpAndSettle();
        expect(find.byType(TransactionListItem).hitTestable(), findsOneWidget);
        expect(find.text('Lunch with friends'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  for (final locale in ['en', 'vi', 'ja']) {
    for (final size in [const Size(844, 390), const Size(1366, 1024)]) {
      for (final screen in const [
        BudgetsScreen(),
        ReportsScreen(),
        ReportCalendarScreen(),
      ]) {
        testWidgets('${screen.runtimeType} empty state fits $locale $size',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final month = DateTime(2026, 10);
          await tester.pumpWidget(ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              canManageWorkspaceContentProvider.overrideWith((ref) => true),
              budgetsProvider.overrideWith((ref) async => []),
              budgetsWithConsumedProvider.overrideWith((ref) async => []),
              categoriesProvider.overrideWith((ref) async => []),
              transactionsProvider.overrideWith((ref) async => []),
              selectedMonthProvider.overrideWith((ref) => month),
              calendarDataProvider(month).overrideWith((ref) async => {}),
              monthlySummaryProvider(month).overrideWith(
                  (ref) async => {'income': 0, 'expense': 0, 'net': 0}),
              transactionGroupsProvider(month).overrideWith((ref) async => []),
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
              home: screen,
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.drag(
              find.byType(Scrollable).first, const Offset(0, -700));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (screen is BudgetsScreen || screen is ReportCalendarScreen) {
            final action = find.byType(ElevatedButton);
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            expect(action.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
