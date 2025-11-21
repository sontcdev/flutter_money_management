// path: test/transaction_budget_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/data/local/app_database.dart';
import 'package:flutter_money_management/src/services/budget_service.dart';
import 'package:flutter_money_management/src/data/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/models/transaction.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase database;
  late BudgetService budgetService;
  late TransactionRepository transactionRepository;

  setUp(() {
    database = AppDatabase.withQueryExecutor(NativeDatabase.memory());
    budgetService = BudgetService(database);
    transactionRepository = TransactionRepository(database, budgetService);
  });

  tearDown(() async {
    await database.close();
  });

  group('Transaction-Budget Integration', () {
    test('creating transaction that exceeds budget rolls back both transaction and budget', () async {
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
      final budgetId = await database.budgetDao.insertBudget(
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
        id: 0,
        amountCents: 10000,
        currency: 'USD',
        dateTime: now,
        categoryId: categoryId,
        accountId: accountId,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      );

      // Try to create transaction - should fail
      try {
        await transactionRepository.createTransaction(transaction);
        fail('Expected BudgetExceededException');
      } catch (e) {
        expect(e, isA<BudgetExceededException>());
      }

      // Verify transaction was not created
      final transactions = await database.transactionDao.getAllTransactions();
      expect(transactions, isEmpty);

      // Verify budget was not updated
      final budget = await database.budgetDao.getBudgetById(budgetId);
      expect(budget, isNotNull);
      expect(budget.consumedCents, equals(0));

      // Verify account balance was not changed
      final account = await database.accountDao.getAccountById(accountId);
      expect(account, isNotNull);
      expect(account.balanceCents, equals(100000));
    });

    test('creating transaction within budget succeeds atomically', () async {
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

      // Create a transaction within budget
      final transaction = Transaction(
        id: 0,
        amountCents: 10000,
        currency: 'USD',
        dateTime: now,
        categoryId: categoryId,
        accountId: accountId,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      );

      // Create transaction - should succeed
      final created = await transactionRepository.createTransaction(transaction);
      expect(created, isNotNull);

      // Verify transaction was created
      final transactions = await database.transactionDao.getAllTransactions();
      expect(transactions, hasLength(1));
      expect(transactions.first.amountCents, equals(10000));

      // Verify budget was updated
      final budget = await database.budgetDao.getBudgetById(budgetId);
      expect(budget, isNotNull);
      expect(budget.consumedCents, equals(10000));

      // Verify account balance was updated
      final account = await database.accountDao.getAccountById(accountId);
      expect(account, isNotNull);
      expect(account.balanceCents, equals(90000));
    });

    test('creating income transaction does not affect budget', () async {
      // Create a test category
      final categoryId = await database.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Salary',
          iconName: '💰',
          colorValue: 0xFF00FF00,
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

      // Create a budget (even though income shouldn't use it)
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

      // Create an income transaction
      final transaction = Transaction(
        id: 0,
        amountCents: 50000,
        currency: 'USD',
        dateTime: now,
        categoryId: categoryId,
        accountId: accountId,
        type: TransactionType.income,
        createdAt: now,
        updatedAt: now,
      );

      // Create transaction
      await transactionRepository.createTransaction(transaction);

      // Verify budget was NOT updated (income doesn't consume budget)
      final budget = await database.budgetDao.getBudgetById(budgetId);
      expect(budget, isNotNull);
      expect(budget.consumedCents, equals(0));

      // Verify account balance was increased
      final account = await database.accountDao.getAccountById(accountId);
      expect(account, isNotNull);
      expect(account.balanceCents, equals(150000));
    });
  });
}

