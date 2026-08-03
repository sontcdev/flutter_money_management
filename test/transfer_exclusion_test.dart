import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/providers/budget_providers.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

/// Serves a fixed transaction list, so the aggregation providers can be tested
/// without Supabase.
class _FakeTransactionRepository extends Fake
    implements TransactionRepository {
  _FakeTransactionRepository(this.transactions);

  final List<Transaction> transactions;

  @override
  Future<List<Transaction>> getAllTransactions({
    String? workspaceIdOverride,
  }) async =>
      transactions;
}

/// Middle of the month, so the default cycle (start day 1) always contains it.
final _date = DateTime(2026, 3, 15, 12);

Transaction _txn({
  required String id,
  required TransactionType type,
  required int amountCents,
  String? categoryId,
}) =>
    Transaction(
      id: id,
      amountCents: amountCents,
      currency: 'VND',
      dateTime: _date,
      categoryId: categoryId,
      type: type,
      walletId: 'wallet-a',
      toWalletId: type == TransactionType.transfer ? 'wallet-b' : null,
      createdAt: _date,
      updatedAt: _date,
    );

Future<ProviderContainer> _createContainer(
  List<Transaction> transactions, {
  List<Budget> budgets = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      monthStartDayProvider.overrideWith((ref) => MonthStartDayNotifier(prefs)),
      transactionRepositoryProvider
          .overrideWithValue(_FakeTransactionRepository(transactions)),
      transactionsProvider.overrideWith((ref) async => transactions),
      budgetsProvider.overrideWith((ref) async => budgets),
    ],
  );
}

/// Keeps a listener alive while awaiting, otherwise the container never
/// resolves the provider's future.
Future<T> _resolve<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) async {
  final sub = container.listen(provider, (_, __) {});
  try {
    while (true) {
      final value = sub.read();
      if (value is AsyncData<T>) {
        return value.value;
      }
      if (value is AsyncError<T>) {
        throw value.error;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  } finally {
    sub.close();
  }
}

void main() {
  // SharedPreferences' mock channel needs an initialized binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('monthly summary counts neither income nor expense for a transfer',
      () async {
    final container = await _createContainer([
      _txn(
          id: 't1',
          type: TransactionType.income,
          amountCents: 1000,
          categoryId: 'cat-1'),
      _txn(
          id: 't2',
          type: TransactionType.expense,
          amountCents: 400,
          categoryId: 'cat-1'),
      _txn(id: 't3', type: TransactionType.transfer, amountCents: 9999),
    ]);
    addTearDown(container.dispose);

    final summary = await _resolve(container, monthlySummaryProvider(_date));

    expect(summary['income'], 1000);
    expect(summary['expense'], 400);
    expect(summary['net'], 600);
  });

  test('calendar badges ignore transfers', () async {
    final container = await _createContainer([
      _txn(id: 't1', type: TransactionType.transfer, amountCents: 9999),
    ]);
    addTearDown(container.dispose);

    final cells = await _resolve(container, calendarDataProvider(_date));

    expect(cells, isEmpty);
  });

  test('a transfer does not consume the budget of its wallet', () async {
    final budget = Budget(
      id: 'b1',
      categoryId: 'cat-1',
      periodType: PeriodType.custom,
      periodStart: DateTime(2026, 3, 1),
      periodEnd: DateTime(2026, 3, 31, 23, 59, 59),
      limitCents: 5000,
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: _date,
      updatedAt: _date,
    );

    final container = await _createContainer(
      [
        _txn(
            id: 't1',
            type: TransactionType.expense,
            amountCents: 400,
            categoryId: 'cat-1'),
        // Transfers carry no category, so they can never hit a budget.
        _txn(id: 't2', type: TransactionType.transfer, amountCents: 9999),
      ],
      budgets: [budget],
    );
    addTearDown(container.dispose);

    final budgets = await _resolve(container, budgetsWithConsumedProvider);

    expect(budgets.single.consumedCents, 400);
  });
}
