// path: lib/src/data/repositories/transaction_repository.dart

import 'package:drift/drift.dart';
import '../local/app_database.dart';
import '../../models/transaction.dart' as model;
import '../../services/budget_service.dart';

class TransactionRepository {
  final AppDatabase _db;
  final BudgetService _budgetService;

  TransactionRepository(this._db, this._budgetService);

  Future<List<model.Transaction>> getAllTransactions() async {
    final entities = await _db.transactionDao.getAllTransactions();
    return entities.map(_entityToModel).toList();
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) async {
    final entities =
        await _db.transactionDao.getTransactionsByDateRange(start, end);
    return entities.map(_entityToModel).toList();
  }

  Future<model.Transaction> getTransactionById(int id) async {
    final entity = await _db.transactionDao.getTransactionById(id);
    return _entityToModel(entity);
  }

  Future<model.Transaction> createTransaction(
    model.Transaction transaction, {
    bool affectAccountBalance = true,
    bool allowOverdraft = false,
  }) async {
    return await _db.transaction(() async {
      // Insert transaction
      final companion = _modelToCompanion(transaction);
      final id = await _db.transactionDao.insertTransaction(companion);

      // Apply to budget (throws if exceeded)
      final created = transaction.copyWith(id: id);
      await _budgetService.applyTransactionToBudget(
        created,
        allowOverdraft: allowOverdraft,
      );

      // Update account balance
      if (affectAccountBalance) {
        final amountDelta = transaction.type == model.TransactionType.expense
            ? -transaction.amountCents
            : transaction.amountCents;
        await _db.accountDao.updateBalance(transaction.accountId, amountDelta);
      }

      return created;
    });
  }

  Future<void> updateTransaction(
    model.Transaction transaction, {
    bool affectAccountBalance = true,
  }) async {
    await _db.transaction(() async {
      // Get old transaction to reverse account balance
      final oldTransaction =
          await _db.transactionDao.getTransactionById(transaction.id);

      // Update transaction
      final companion = _modelToCompanion(transaction);
      await _db.transactionDao.updateTransaction(companion);

      // Update account balance
      if (affectAccountBalance) {
        // Reverse old transaction
        final oldDelta = oldTransaction.type == 'expense'
            ? oldTransaction.amountCents
            : -oldTransaction.amountCents;
        await _db.accountDao.updateBalance(oldTransaction.accountId, oldDelta);

        // Apply new transaction
        final newDelta = transaction.type == model.TransactionType.expense
            ? -transaction.amountCents
            : transaction.amountCents;
        await _db.accountDao.updateBalance(transaction.accountId, newDelta);
      }

      // Recalculate budgets for affected category
      final budgets = await _db.budgetDao
          .getBudgetsByCategory(transaction.categoryId);
      for (final budget in budgets) {
        await _db.budgetDao.recalculateConsumed(budget.id);
      }
    });
  }

  Future<void> deleteTransaction(
    int id, {
    bool affectAccountBalance = true,
  }) async {
    await _db.transaction(() async {
      // Get transaction to reverse account balance
      final transaction = await _db.transactionDao.getTransactionById(id);

      // Delete transaction
      await _db.transactionDao.deleteTransaction(id);

      // Update account balance
      if (affectAccountBalance) {
        final amountDelta = transaction.type == 'expense'
            ? transaction.amountCents
            : -transaction.amountCents;
        await _db.accountDao.updateBalance(transaction.accountId, amountDelta);
      }

      // Recalculate budgets for affected category
      final budgets =
          await _db.budgetDao.getBudgetsByCategory(transaction.categoryId);
      for (final budget in budgets) {
        await _db.budgetDao.recalculateConsumed(budget.id);
      }
    });
  }

  model.Transaction _entityToModel(TransactionEntity entity) {
    return model.Transaction(
      id: entity.id,
      amountCents: entity.amountCents,
      currency: entity.currency,
      dateTime: entity.dateTime,
      categoryId: entity.categoryId,
      accountId: entity.accountId,
      type: entity.type == 'expense'
          ? model.TransactionType.expense
          : model.TransactionType.income,
      note: entity.note,
      receiptPath: entity.receiptPath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TransactionsCompanion _modelToCompanion(model.Transaction transaction) {
    return TransactionsCompanion(
      id: transaction.id > 0 ? Value(transaction.id) : const Value.absent(),
      amountCents: Value(transaction.amountCents),
      currency: Value(transaction.currency),
      dateTime: Value(transaction.dateTime),
      categoryId: Value(transaction.categoryId),
      accountId: Value(transaction.accountId),
      type: Value(transaction.type == model.TransactionType.expense
          ? 'expense'
          : 'income'),
      note: Value(transaction.note),
      receiptPath: Value(transaction.receiptPath),
      createdAt: Value(transaction.createdAt),
      updatedAt: Value(transaction.updatedAt),
    );
  }
}

