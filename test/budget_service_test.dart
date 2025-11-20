// path: test/budget_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/data/local/app_database.dart';
import 'package:flutter_money_management/src/services/budget_service.dart';
import 'package:flutter_money_management/src/models/budget.dart';
import 'package:flutter_money_management/src/models/transaction.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase database;
  late BudgetService budgetService;

  setUp(() {
    database = AppDatabase.withQueryExecutor(NativeDatabase.memory());
    budgetService = BudgetService(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('BudgetService', () {
    test('applyTransactionToBudgets updates budget consumed amount', () async {
      // Create a test category
      final categoryId = await database.categoryDao.createCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          icon: '🍔',
          color: '#FF0000',
          type: 'expense',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a test account
      final accountId = await database.accountDao.createAccount(
        AccountsCompanion.insert(
          name: 'Cash',
          balanceCents: 100000,
          currency: 'USD',
          type: 'cash',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a budget
      final now = DateTime.now();
      final budgetId = await database.budgetDao.createBudget(
        BudgetsCompanion.insert(
          categoryId: categoryId,
          periodType: 'monthly',
          periodStart: DateTime(now.year, now.month, 1),
          periodEnd: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          limitCents: 50000,
          consumedCents: 0,
          allowOverdraft: false,
          overdraftCents: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create a transaction
      final transaction = Transaction(
        id: 1,
        amountCents: 10000,
        currency: 'USD',
        dateTime: now,
        categoryId: categoryId,
        accountId: accountId,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      );

      // Apply transaction to budget
      await database.transaction(() async {
        await budgetService.applyTransactionToBudgets(transaction);
      });

      // Verify budget was updated
      final updatedBudget = await database.budgetDao.getBudgetById(budgetId);
      expect(updatedBudget, isNotNull);
      expect(updatedBudget!.consumedCents, equals(10000));
      expect(updatedBudget.overdraftCents, equals(0));
    });

    test('applyTransactionToBudgets throws BudgetExceededException when budget is exceeded', () async {
      // Create a test category
      final categoryId = await database.categoryDao.createCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          icon: '🍔',
          color: '#FF0000',
          type: 'expense',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a test account
      final accountId = await database.accountDao.createAccount(
        AccountsCompanion.insert(
          name: 'Cash',
          balanceCents: 100000,
          currency: 'USD',
          type: 'cash',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a budget with low limit
      final now = DateTime.now();
      await database.budgetDao.createBudget(
        BudgetsCompanion.insert(
          categoryId: categoryId,
          periodType: 'monthly',
          periodStart: DateTime(now.year, now.month, 1),
          periodEnd: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          limitCents: 5000,
          consumedCents: 0,
          allowOverdraft: false,
          overdraftCents: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create a transaction that exceeds budget
      final transaction = Transaction(
        id: 1,
        amountCents: 10000,
        currency: 'USD',
        dateTime: now,
        categoryId: categoryId,
        accountId: accountId,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      );

      // Expect exception
      await expectLater(
        database.transaction(() async {
          await budgetService.applyTransactionToBudgets(transaction);
        }),
        throwsA(isA<BudgetExceededException>()),
      );
    });

    test('applyTransactionToBudgets allows overdraft when enabled', () async {
      // Create a test category
      final categoryId = await database.categoryDao.createCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          icon: '🍔',
          color: '#FF0000',
          type: 'expense',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a test account
      final accountId = await database.accountDao.createAccount(
        AccountsCompanion.insert(
          name: 'Cash',
          balanceCents: 100000,
          currency: 'USD',
          type: 'cash',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a budget with overdraft allowed
      final now = DateTime.now();
      final budgetId = await database.budgetDao.createBudget(
        BudgetsCompanion.insert(
          categoryId: categoryId,
          periodType: 'monthly',
          periodStart: DateTime(now.year, now.month, 1),
          periodEnd: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          limitCents: 5000,
          consumedCents: 0,
          allowOverdraft: true,
          overdraftCents: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create a transaction that exceeds budget
      final transaction = Transaction(
        id: 1,
        amountCents: 10000,
        currency: 'USD',
        dateTime: now,
        categoryId: categoryId,
        accountId: accountId,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      );

      // Apply transaction with overdraft
      await database.transaction(() async {
        await budgetService.applyTransactionToBudgets(transaction, allowOverdraft: true);
      });

      // Verify budget was updated with overdraft
      final updatedBudget = await database.budgetDao.getBudgetById(budgetId);
      expect(updatedBudget, isNotNull);
      expect(updatedBudget!.consumedCents, equals(10000));
      expect(updatedBudget.overdraftCents, equals(5000));
    });

    test('validateNoBudgetOverlap throws BudgetOverlapException when budgets overlap', () async {
      // Create a test category
      final categoryId = await database.categoryDao.createCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          icon: '🍔',
          color: '#FF0000',
          type: 'expense',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create an existing budget
      final now = DateTime.now();
      await database.budgetDao.createBudget(
        BudgetsCompanion.insert(
          categoryId: categoryId,
          periodType: 'monthly',
          periodStart: DateTime(now.year, now.month, 1),
          periodEnd: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          limitCents: 50000,
          consumedCents: 0,
          allowOverdraft: false,
          overdraftCents: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Try to create overlapping budget
      await expectLater(
        budgetService.validateNoBudgetOverlap(
          categoryId,
          DateTime(now.year, now.month, 15),
          DateTime(now.year, now.month + 1, 15),
        ),
        throwsA(isA<BudgetOverlapException>()),
      );
    });
  });
}
code