// path: test/budget_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test3_cursor/src/data/local/app_database.dart';
import 'package:test3_cursor/src/services/budget_service.dart';
import 'package:test3_cursor/src/models/transaction.dart' as model_transaction;
import 'package:test3_cursor/src/models/budget.dart' as model;

class MockDatabase extends Mock implements AppDatabase {}

void main() {
  late AppDatabase database;
  late BudgetService budgetService;

  setUp(() {
    database = AppDatabase();
    budgetService = BudgetService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('applyTransactionToBudgets - should update consumed when within limit',
      () async {
    // Create test budget
    final budget = model.Budget(
      id: '1',
      categoryId: 'cat1',
      periodType: model.PeriodType.monthly,
      periodStart: DateTime(2024, 1, 1),
      periodEnd: DateTime(2024, 1, 31),
      limitCents: 100000,
      consumedCents: 50000,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await database.budgetDao.insertBudget(budget);

    // Create test transaction
    final transaction = model_transaction.Transaction(
      id: 't1',
      amountCents: 20000,
      currency: 'VND',
      dateTime: DateTime(2024, 1, 15),
      categoryId: 'cat1',
      accountId: 'acc1',
      type: model_transaction.TransactionType.expense,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await budgetService.applyTransactionToBudgets(transaction);

    final updated = await database.budgetDao.getBudgetById('1');
    expect(updated?.consumedCents, 70000);
    expect(updated?.overdraftCents, 0);
  });

  test('applyTransactionToBudgets - should throw BudgetExceededException when limit exceeded',
      () async {
    final budget = model.Budget(
      id: '2',
      categoryId: 'cat2',
      periodType: model.PeriodType.monthly,
      periodStart: DateTime(2024, 1, 1),
      periodEnd: DateTime(2024, 1, 31),
      limitCents: 100000,
      consumedCents: 90000,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await database.budgetDao.insertBudget(budget);

    final transaction = model_transaction.Transaction(
      id: 't2',
      amountCents: 20000,
      currency: 'VND',
      dateTime: DateTime(2024, 1, 15),
      categoryId: 'cat2',
      accountId: 'acc1',
      type: model_transaction.TransactionType.expense,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(
      () => budgetService.applyTransactionToBudgets(transaction),
      throwsA(isA<BudgetExceededException>()),
    );
  });

  test('applyTransactionToBudgets - should allow overdraft when allowOverdraft is true',
      () async {
    final budget = model.Budget(
      id: '3',
      categoryId: 'cat3',
      periodType: model.PeriodType.monthly,
      periodStart: DateTime(2024, 1, 1),
      periodEnd: DateTime(2024, 1, 31),
      limitCents: 100000,
      consumedCents: 90000,
      allowOverdraft: true,
      overdraftCents: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await database.budgetDao.insertBudget(budget);

    final transaction = model_transaction.Transaction(
      id: 't3',
      amountCents: 20000,
      currency: 'VND',
      dateTime: DateTime(2024, 1, 15),
      categoryId: 'cat3',
      accountId: 'acc1',
      type: model_transaction.TransactionType.expense,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await budgetService.applyTransactionToBudgets(transaction, allowOverdraft: true);

    final updated = await database.budgetDao.getBudgetById('3');
    expect(updated?.consumedCents, 110000);
    expect(updated?.overdraftCents, 10000);
  });
}

