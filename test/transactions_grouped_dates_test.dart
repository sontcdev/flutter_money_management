import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';

final _stamp = DateTime(2026, 3, 1);

Transaction _txn(String id, DateTime date, String note) => Transaction(
      id: id,
      amountCents: 5000000,
      currency: 'VND',
      dateTime: date,
      categoryId: 'cat',
      type: TransactionType.expense,
      note: note,
      walletId: 'w',
      createdAt: _stamp,
      updatedAt: _stamp,
    );

Future<void> _pump(WidgetTester tester) async {
  final txns = [
    _txn('1', DateTime(2026, 3, 15, 9), 'alpha'),
    _txn('2', DateTime(2026, 3, 15, 8), 'beta'),
    _txn('3', DateTime(2026, 3, 14, 8), 'gamma'),
  ];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      transactionsProvider.overrideWith((ref) async => txns),
      categoriesProvider.overrideWith((ref) async => [
            Category(
              id: 'cat',
              name: 'Food',
              iconName: 'restaurant',
              colorValue: Colors.green.toARGB32(),
              createdAt: _stamp,
              updatedAt: _stamp,
            ),
          ]),
      walletsProvider.overrideWith((ref) async => <Wallet>[]),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TransactionsScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('grouped rows show the date only in the day header',
      (tester) async {
    await _pump(tester);

    final headers = find.byWidgetPredicate((w) =>
        w is RichText &&
        w.text.toPlainText().toUpperCase() == w.text.toPlainText() &&
        RegExp(r'MARCH|MAR').hasMatch(w.text.toPlainText()));
    expect(headers, findsNWidgets(2));
    expect(find.byType(TransactionItem), findsNWidgets(3));
    // Row-level dates (yMd) must be gone; notes remain.
    expect(find.text('3/15/2026'), findsNothing);
    expect(find.text('3/14/2026'), findsNothing);
    expect(find.text('alpha'), findsOneWidget);
    for (final item in tester.widgetList<TransactionItem>(
        find.byType(TransactionItem))) {
      expect(item.showDate, isFalse);
    }
    // Newest day first.
    final first = tester.getTopLeft(find.text('alpha')).dy;
    final last = tester.getTopLeft(find.text('gamma')).dy;
    expect(first, lessThan(last));
  });

  testWidgets('search still filters grouped rows', (tester) async {
    await _pump(tester);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'gamma');
    await tester.pumpAndSettle();
    expect(find.byType(TransactionItem), findsOneWidget);
    expect(
      find.descendant(
          of: find.byType(TransactionItem), matching: find.text('gamma')),
      findsOneWidget,
    );
  });

  testWidgets('ungrouped TransactionItem keeps its date by default',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TransactionItem(
          transaction: _txn('4', DateTime(2026, 3, 15, 9), 'delta'),
          categoryName: 'Food',
        ),
      ),
    ));
    expect(find.text('3/15/2026'), findsWidgets);
  });
}
