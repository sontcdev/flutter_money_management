// path: lib/src/services/budget_service.dart
import 'package:test3_cursor/src/models/transaction.dart' as model_transaction;
import 'package:test3_cursor/src/models/budget.dart' as model;
import 'package:test3_cursor/src/data/local/app_database.dart';

class BudgetExceededException implements Exception {
  final String message;
  final int remainingCents;
  BudgetExceededException(this.message, this.remainingCents);
}

class BudgetOverlapException implements Exception {
  final String message;
  BudgetOverlapException(this.message);
}

class BudgetService {
  final AppDatabase _db;

  BudgetService(this._db);

  Future<void> applyTransactionToBudgets(model_transaction.Transaction transaction,
      {bool allowOverdraft = false}) async {
    final budgets = await _db.budgetDao
        .getActiveBudgetsForCategory(transaction.categoryId, transaction.dateTime);

    if (budgets.isEmpty) {
      return; // No budget for this category/period
    }

    // Only one active budget should exist per category/period
    if (budgets.length > 1) {
      throw BudgetOverlapException(
          'Multiple active budgets found for category ${transaction.categoryId}');
    }

    final budget = budgets.first;

    // Only apply to expense transactions
    if (transaction.type != model_transaction.TransactionType.expense) {
      return;
    }

    final newConsumed = budget.consumedCents + transaction.amountCents;
    final remaining = budget.limitCents - budget.consumedCents;

    if (newConsumed > budget.limitCents && !allowOverdraft) {
      throw BudgetExceededException(
          'Budget exceeded. Remaining: $remaining cents', remaining);
    }

    int overdraftCents = 0;
    if (newConsumed > budget.limitCents) {
      overdraftCents = (newConsumed - budget.limitCents).toInt();
    }

    await _db.budgetDao.updateConsumed(
        budget.id, newConsumed.toInt(), overdraftCents);
  }

  Future<void> recalculateConsumed(model.Budget budget) async {
    final consumed = await _db.budgetDao.computeConsumed(budget);
    final overdraft = consumed > budget.limitCents
        ? (consumed - budget.limitCents).toInt()
        : 0;
    await _db.budgetDao.updateConsumed(budget.id, consumed, overdraft);
  }

  Future<void> checkBudgetOverlap(String categoryId, DateTime periodStart,
      DateTime periodEnd, String? excludeBudgetId) async {
    final overlapping = await _db.budgetDao
        .getOverlappingBudgets(categoryId, periodStart, periodEnd);
    
    final filtered = excludeBudgetId != null
        ? overlapping.where((b) => b.id != excludeBudgetId).toList()
        : overlapping;

    if (filtered.isNotEmpty) {
      throw BudgetOverlapException(
          'Budget overlaps with existing budget for category $categoryId');
    }
  }
}

