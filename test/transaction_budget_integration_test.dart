// path: test/transaction_budget_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:test3_cursor/src/data/local/app_database.dart';
import 'package:test3_cursor/src/data/repositories/transaction_repository.dart';
import 'package:test3_cursor/src/services/budget_service.dart';
import 'package:test3_cursor/src/data/repositories/category_repository.dart';
import 'package:test3_cursor/src/data/repositories/account_repository.dart';
import 'package:test3_cursor/src/models/transaction.dart' as model_transaction;
import 'package:test3_cursor/src/models/budget.dart' as model;
import 'package:test3_cursor/src/models/category.dart' as model;
import 'package:test3_cursor/src/models/account.dart' as model;

void main() {
  late AppDatabase database;
  late TransactionRepository transactionRepository;
  late BudgetService budgetService;
  late CategoryRepository categoryRepository;
  late AccountRepository accountRepository;

  setUp(() {
    database = AppDatabase();
    budgetService = BudgetService(database);
    categoryRepository = CategoryRepository(database);
    accountRepository = AccountRepository(database);
    transactionRepository = TransactionRepository(
      database,
      budgetService,
      categoryRepository,
      accountRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('createTransaction - should rollback both transaction and budget on budget exceeded',
      () async {
    // Create category
    final category = model.Category(
      id: 'cat1',
      name: 'Food',
      icon: '🍔',
      color: '#FF0000',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepository.createCategory(category);

    // Create account
    final account = model.Account(
      id: 'acc1',
      name: 'Cash',
      balanceCents: 1000000,
      currency: 'VND',
      type: model.AccountType.cash,
      createdAt: DateTime.now(),
    );
    await accountRepository.createAccount(account);

    // Create budget
    final budget = model.Budget(
      id: 'budget1',
      categoryId: 'cat1',
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

    // Create transaction that would exceed budget
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

    // Should throw exception and rollback
    expect(
      () => transactionRepository.createTransaction(transaction, allowOverdraft: false),
      throwsA(isA<BudgetExceededException>()),
    );

    // Verify transaction was not created
    final created = await transactionRepository.getTransactionById('t1');
    expect(created, isNull);

    // Verify budget was not updated
    final updatedBudget = await database.budgetDao.getBudgetById('budget1');
    expect(updatedBudget?.consumedCents, 90000);
  });
}

