import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/data/local/app_database.dart';
import 'package:flutter_money_management/src/data/repositories/budget_repository.dart';
import 'package:flutter_money_management/src/data/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/services/budget_service.dart';
import 'package:flutter_money_management/src/models/budget.dart';
import 'package:flutter_money_management/src/models/transaction.dart' as model;
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late BudgetService budgetService;
  late BudgetRepository budgetRepo;
  late TransactionRepository transactionRepo;

  setUp(() async {
    db = AppDatabase.withQueryExecutor(NativeDatabase.memory());
    budgetService = BudgetService(db);
    budgetRepo = BudgetRepository(db, budgetService);
    transactionRepo = TransactionRepository(db, budgetService);

    // Create a test category
    final now = DateTime.now();
    await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: 'Food',
        iconName: '🍔',
        colorValue: 0xFF000000,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Budget consumed updates when transaction is created', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Create budget with 1000 VND limit
    final budget = Budget(
      id: 0,
      categoryId: 1,
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 100000, // 1000 VND
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    final createdBudget = await budgetRepo.createBudget(budget);
    expect(createdBudget.consumedCents, equals(0));

    // Create expense transaction of 500 VND
    final transaction = model.Transaction(
      id: 0,
      amountCents: 50000, // 500 VND
      currency: 'VND',
      dateTime: now,
      categoryId: 1,
      type: model.TransactionType.expense,
      note: 'Test expense',
      receiptPath: null,
      createdAt: now,
      updatedAt: now,
    );

    await transactionRepo.createTransaction(transaction);

    // Get budget again and verify consumed was updated
    final updatedBudget = await budgetRepo.getBudgetById(createdBudget.id);
    expect(updatedBudget.consumedCents, equals(50000));
    expect(updatedBudget.remainingCents, equals(50000)); // 1000 - 500 = 500
  });

  test('Budget consumed updates when transaction is deleted', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Create budget
    final budget = Budget(
      id: 0,
      categoryId: 1,
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 100000,
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    final createdBudget = await budgetRepo.createBudget(budget);

    // Create transaction
    final transaction = model.Transaction(
      id: 0,
      amountCents: 50000,
      currency: 'VND',
      dateTime: now,
      categoryId: 1,
      type: model.TransactionType.expense,
      note: 'Test expense',
      receiptPath: null,
      createdAt: now,
      updatedAt: now,
    );

    final createdTransaction = await transactionRepo.createTransaction(transaction);

    // Verify budget was updated
    var updatedBudget = await budgetRepo.getBudgetById(createdBudget.id);
    expect(updatedBudget.consumedCents, equals(50000));

    // Delete transaction
    await transactionRepo.deleteTransaction(createdTransaction.id);

    // Verify budget consumed was recalculated to 0
    updatedBudget = await budgetRepo.getBudgetById(createdBudget.id);
    expect(updatedBudget.consumedCents, equals(0));
  });

  test('Income transactions do not affect budget consumed', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Create budget
    final budget = Budget(
      id: 0,
      categoryId: 1,
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 100000,
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    final createdBudget = await budgetRepo.createBudget(budget);

    // Create income transaction (should NOT affect budget)
    final transaction = model.Transaction(
      id: 0,
      amountCents: 50000,
      currency: 'VND',
      dateTime: now,
      categoryId: 1,
      type: model.TransactionType.income,
      note: 'Test income',
      receiptPath: null,
      createdAt: now,
      updatedAt: now,
    );

    await transactionRepo.createTransaction(transaction);

    // Verify budget consumed is still 0
    final updatedBudget = await budgetRepo.getBudgetById(createdBudget.id);
    expect(updatedBudget.consumedCents, equals(0));
  });

  test('Multiple transactions accumulate consumed amount', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Create budget
    final budget = Budget(
      id: 0,
      categoryId: 1,
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 200000, // 2000 VND
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    final createdBudget = await budgetRepo.createBudget(budget);

    // Create 3 expense transactions
    for (int i = 1; i <= 3; i++) {
      final transaction = model.Transaction(
        id: 0,
        amountCents: 30000, // 300 VND each
        currency: 'VND',
        dateTime: now,
        categoryId: 1,
        type: model.TransactionType.expense,
        note: 'Test expense $i',
        receiptPath: null,
        createdAt: now,
        updatedAt: now,
      );
      await transactionRepo.createTransaction(transaction);
    }

    // Verify total consumed is 900 VND (300 * 3)
    final updatedBudget = await budgetRepo.getBudgetById(createdBudget.id);
    expect(updatedBudget.consumedCents, equals(90000));
    expect(updatedBudget.remainingCents, equals(110000)); // 2000 - 900 = 1100
  });
}

