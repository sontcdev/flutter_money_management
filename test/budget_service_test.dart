// path: test/budget_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/data/local/app_database.dart';
import 'package:flutter_money_management/src/services/budget_service.dart';
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
    test('applyTransactionToBudget updates budget consumed amount', () async {
      // Create a test category
      final categoryId = await database.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          iconName: '🍔',
          colorValue: 0xFFFF0000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a test account
      final accountId = await database.accountDao.insertAccount(
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
      final budgetId = await database.budgetDao.insertBudget(
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
        await budgetService.applyTransactionToBudget(transaction);
      });

      // Verify budget was updated
      final updatedBudget = await database.budgetDao.getBudgetById(budgetId);
      expect(updatedBudget, isNotNull);
      expect(updatedBudget.consumedCents, equals(10000));
      expect(updatedBudget.overdraftCents, equals(0));
    });

    test('applyTransactionToBudget throws BudgetExceededException when budget is exceeded', () async {
      // Create a test category
      final categoryId = await database.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          iconName: '🍔',
          colorValue: 0xFFFF0000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a test account
      final accountId = await database.accountDao.insertAccount(
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
      await database.budgetDao.insertBudget(
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
          await budgetService.applyTransactionToBudget(transaction);
        }),
        throwsA(isA<BudgetExceededException>()),
      );
    });

    test('applyTransactionToBudget allows overdraft when enabled', () async {
      // Create a test category
      final categoryId = await database.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          iconName: '🍔',
          colorValue: 0xFFFF0000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create a test account
      final accountId = await database.accountDao.insertAccount(
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
      final budgetId = await database.budgetDao.insertBudget(
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
        await budgetService.applyTransactionToBudget(transaction, allowOverdraft: true);
      });

      // Verify budget was updated with overdraft
      final updatedBudget = await database.budgetDao.getBudgetById(budgetId);
      expect(updatedBudget, isNotNull);
      expect(updatedBudget.consumedCents, equals(10000));
      expect(updatedBudget.overdraftCents, equals(5000));
    });

    test('hasOverlappingBudget detects overlapping budgets', () async {
      // Create a test category
      final categoryId = await database.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Food',
          iconName: '🍔',
          colorValue: 0xFFFF0000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create an existing budget
      final now = DateTime.now();
      await database.budgetDao.insertBudget(
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

      // Check for overlapping budget
      final hasOverlap = await database.budgetDao.hasOverlappingBudget(
        categoryId,
        DateTime(now.year, now.month, 15),
        DateTime(now.year, now.month + 1, 15),
      );

      expect(hasOverlap, isTrue);
    });
  });
}
