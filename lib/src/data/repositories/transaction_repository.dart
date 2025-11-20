// path: lib/src/data/repositories/transaction_repository.dart
import 'package:test3_cursor/src/models/transaction.dart' as model;
import 'package:test3_cursor/src/data/local/app_database.dart';
import 'package:test3_cursor/src/services/budget_service.dart';
import 'package:test3_cursor/src/data/repositories/category_repository.dart';
import 'package:test3_cursor/src/data/repositories/account_repository.dart';

class TransactionRepository {
  final AppDatabase _db;
  final BudgetService _budgetService;
  final CategoryRepository _categoryRepository;
  final AccountRepository _accountRepository;

  TransactionRepository(
      this._db, this._budgetService, this._categoryRepository, this._accountRepository);

  Future<List<model.Transaction>> getTransactions({
    int? limit,
    int? offset,
    String? categoryId,
    String? accountId,
    model.TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _db.transactionDao.getAllTransactions(
      limit: limit,
      offset: offset,
      categoryId: categoryId,
      accountId: accountId,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<model.Transaction?> getTransactionById(String id) async {
    return await _db.transactionDao.getTransactionById(id);
  }

  Future<model.Transaction> createTransaction(model.Transaction transaction,
      {bool affectAccountBalance = true, bool allowOverdraft = false}) async {
    // Verify category exists
    final category = await _categoryRepository.getCategoryById(transaction.categoryId);
    if (category == null) {
      throw Exception('Category not found');
    }

    // Verify account exists
    final account = await _accountRepository.getAccountById(transaction.accountId);
    if (account == null) {
      throw Exception('Account not found');
    }

    // Atomic transaction: insert transaction + update budget + update account balance
    await _db.transaction(() async {
      await _db.transactionDao.insertTransaction(transaction);

      // Apply to budget
      try {
        await _budgetService.applyTransactionToBudgets(transaction,
            allowOverdraft: allowOverdraft);
      } catch (e) {
        if (e is BudgetExceededException) {
          rethrow;
        }
      }

      // Update account balance
      if (affectAccountBalance) {
        int newBalance = account.balanceCents;
        if (transaction.type == model.TransactionType.income) {
          newBalance = (newBalance + transaction.amountCents).toInt();
        } else {
          newBalance = (newBalance - transaction.amountCents).toInt();
        }
        await _db.accountDao.updateBalance(transaction.accountId, newBalance);
      }
    });

    return transaction;
  }

  Future<model.Transaction> updateTransaction(model.Transaction transaction) async {
    final oldTransaction = await getTransactionById(transaction.id);
    if (oldTransaction == null) {
      throw Exception('Transaction not found');
    }

    await _db.transaction(() async {
      await _db.transactionDao.updateTransaction(transaction);

      // Recalculate budgets for old and new category/date
      if (oldTransaction.categoryId != transaction.categoryId ||
          oldTransaction.dateTime != transaction.dateTime ||
          oldTransaction.amountCents != transaction.amountCents) {
        // Revert old budget
        if (oldTransaction.type == model.TransactionType.expense) {
          final oldBudgets = await _db.budgetDao.getActiveBudgetsForCategory(
              oldTransaction.categoryId, oldTransaction.dateTime);
          for (final budget in oldBudgets) {
            await _budgetService.recalculateConsumed(budget);
          }
        }

        // Apply new budget
        if (transaction.type == model.TransactionType.expense) {
          await _budgetService.applyTransactionToBudgets(transaction,
              allowOverdraft: true);
        }
      }
    });

    return transaction;
  }

  Future<void> deleteTransaction(String id) async {
    final transaction = await getTransactionById(id);
    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    await _db.transaction(() async {
      await _db.transactionDao.deleteTransaction(id);

      // Recalculate budget
      if (transaction.type == model.TransactionType.expense) {
        final budgets = await _db.budgetDao.getActiveBudgetsForCategory(
            transaction.categoryId, transaction.dateTime);
        for (final budget in budgets) {
          await _budgetService.recalculateConsumed(budget);
        }
      }

      // Revert account balance
      final account = await _accountRepository.getAccountById(transaction.accountId);
      if (account != null) {
        int newBalance = account.balanceCents;
        if (transaction.type == model.TransactionType.income) {
          newBalance = (newBalance - transaction.amountCents).toInt();
        } else {
          newBalance = (newBalance + transaction.amountCents).toInt();
        }
        await _db.accountDao.updateBalance(transaction.accountId, newBalance);
      }
    });
  }

  Future<int> getTotalByMonth(int year, int month) async {
    return await _db.transactionDao.getTotalByMonth(year, month);
  }

  Future<int> getTotalByYear(int year) async {
    return await _db.transactionDao.getTotalByYear(year);
  }

  Future<int> getTotalByCategory(String categoryId, DateTime start, DateTime end) async {
    return await _db.transactionDao.getTotalByCategory(categoryId, start, end);
  }
}

