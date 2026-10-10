import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/transactions/services/transaction_receipt_service.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

class _FakeTransactionRepository extends Fake
    implements TransactionRepository {
  final deletedIds = <String>[];

  @override
  Future<void> deleteTransaction(
    String id, {
    String? workspaceIdOverride,
  }) async {
    deletedIds.add(id);
  }
}

class _FakeReceiptService extends Fake implements TransactionReceiptService {}

void main() {
  testWidgets('swipe delete hides the row and Undo restores it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final category = Category(
      id: 'cat-1',
      name: 'Food',
      iconName: 'restaurant',
      colorValue: 0xFF4CAF50,
      createdAt: now,
      updatedAt: now,
    );
    final transaction = Transaction(
      id: 'tx-1',
      amountCents: 50000,
      currency: 'VND',
      dateTime: now,
      categoryId: category.id,
      type: TransactionType.expense,
      note: 'Lunch note',
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeTransactionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transactionRepositoryProvider.overrideWithValue(repository),
          transactionReceiptServiceProvider
              .overrideWithValue(_FakeReceiptService()),
          transactionsProvider.overrideWith((ref) async => [transaction]),
          categoriesProvider.overrideWith((ref) async => [category]),
          walletsProvider.overrideWith((ref) async => []),
          transactionCanManageProvider.overrideWith((ref, id) async => true),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('vi'), Locale('ja')],
          home: TransactionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('tx-1'));
    expect(row, findsOneWidget);

    await tester.drag(row, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(row, findsNothing);
    expect(find.text('Transaction deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(row, findsOneWidget);
    expect(repository.deletedIds, isEmpty);
  });
}
