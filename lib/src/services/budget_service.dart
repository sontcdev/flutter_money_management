// path: lib/src/services/budget_service.dart

import '../data/local/app_database.dart';
import '../models/transaction.dart' as model;

class BudgetExceededException implements Exception {
  final String message;
  final int remainingCents;
  final int limitCents;

  BudgetExceededException({
    required this.message,
    required this.remainingCents,
    required this.limitCents,
  });

  @override
  String toString() => message;
}

class BudgetOverlapException implements Exception {
  final String message;

  BudgetOverlapException(this.message);

  @override
  String toString() => message;
}

class CategoryInUseException implements Exception {
  final String message;

  CategoryInUseException(this.message);

  @override
  String toString() => message;
}

class BudgetService {
  final AppDatabase _db;

  BudgetService(this._db);

  /// Apply a transaction to the relevant budget.
  /// Must be called within a drift transaction context.
  /// Throws BudgetExceededException if budget would be exceeded and allowOverdraft is false.
  Future<void> applyTransactionToBudget(
    model.Transaction transaction, {
    bool allowOverdraft = false,
  }) async {
    // Only apply to expense transactions
    if (transaction.type != model.TransactionType.expense) {
      return;
    }

    // Find active budget for this category and date
    final budgetEntity = await _db.budgetDao
        .getActiveBudgetForCategoryAndDate(
            transaction.categoryId, transaction.dateTime);

    if (budgetEntity == null) {
      // No budget to apply
      return;
    }

    final newConsumed = budgetEntity.consumedCents + transaction.amountCents;

    // Check if budget would be exceeded
    if (newConsumed > budgetEntity.limitCents &&
        !allowOverdraft &&
        !budgetEntity.allowOverdraft) {
      final remaining = budgetEntity.limitCents - budgetEntity.consumedCents;
      throw BudgetExceededException(
        message:
            'Budget exceeded! Remaining: $remaining cents, Limit: ${budgetEntity.limitCents} cents',
        remainingCents: remaining,
        limitCents: budgetEntity.limitCents,
      );
    }

    // Update budget consumed
    final newOverdraft = newConsumed > budgetEntity.limitCents
        ? newConsumed - budgetEntity.limitCents
        : 0;

    await _db.budgetDao.updateConsumed(
      budgetEntity.id,
      newConsumed,
      newOverdraft,
    );
  }

  /// Validate that a budget doesn't overlap with existing budgets for the same category
  Future<void> validateBudgetPeriod(
    int categoryId,
    DateTime start,
    DateTime end, {
    int? excludeId,
  }) async {
    final hasOverlap = await _db.budgetDao.hasOverlappingBudget(
      categoryId,
      start,
      end,
      excludeId: excludeId,
    );

    if (hasOverlap) {
      throw BudgetOverlapException(
          'Budget period overlaps with existing budget for this category');
    }
  }
}

