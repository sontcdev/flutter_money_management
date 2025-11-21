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

      return created;
    });
  }

  Future<void> updateTransaction(
    model.Transaction transaction,
  ) async {
    await _db.transaction(() async {
      // Get old transaction
      final oldTransaction =
          await _db.transactionDao.getTransactionById(transaction.id);

      // Update transaction
      final companion = _modelToCompanion(transaction);
      await _db.transactionDao.updateTransaction(companion);

      // Recalculate budgets for affected category
      final budgets = await _db.budgetDao
          .getBudgetsByCategory(transaction.categoryId);
      for (final budget in budgets) {
        await _db.budgetDao.recalculateConsumed(budget.id);
      }
    });
  }

  Future<void> deleteTransaction(int id) async {
    await _db.transaction(() async {
      // Get transaction
      final transaction = await _db.transactionDao.getTransactionById(id);

      // Delete transaction
      await _db.transactionDao.deleteTransaction(id);

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
      dateTime: entity.transactionDate,
      categoryId: entity.categoryId,
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
      transactionDate: Value(transaction.dateTime),
      categoryId: Value(transaction.categoryId),
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

