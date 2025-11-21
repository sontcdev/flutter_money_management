// path: lib/src/services/budget_service.dart
import '../models/transaction.dart';
import '../data/local/app_database.dart';
import '../data/local/daos/budget_dao.dart';
import '../data/repositories/category_repository.dart';
import 'package:drift/drift.dart' as drift;

class BudgetExceededException implements Exception {
  final int remainingCents;
  final String message;

  BudgetExceededException({
    required this.remainingCents,
    required this.message,
  });

  @override
  String toString() => message;
}

class BudgetDuplicateException implements Exception {
  final String categoryName;
  final String budgetName;
  final String message;

  BudgetDuplicateException({
    required this.categoryName,
    required this.budgetName,
    String? message,
  }) : message = message ?? 
      'Danh mục "$categoryName" đang được gắn với hũ chi tiêu "$budgetName". Vui lòng chọn hũ khác hoặc thay đổi chu kỳ.';

  @override
  String toString() => message;
}

class BudgetService {
  final BudgetDao _budgetDao;
  CategoryRepository? _categoryRepository;

  BudgetService(this._budgetDao);

  void setCategoryRepository(CategoryRepository repository) {
    _categoryRepository = repository;
  }

  /// Apply transaction to budgets. Can be called within an existing transaction block
  /// or standalone (will create its own transaction).
  ///
  /// When called from TransactionRepository, pass the AppDatabase instance
  /// and this method will NOT create a new transaction (assumes caller manages transaction).
  ///
  /// When called standalone, will create its own transaction.
  Future<void> applyTransactionToBudgets(
    Transaction transaction, {
    required bool allowOverdraft,
    AppDatabase? db,
  }) async {
    if (transaction.categoryId == null) {
      // No category means no budget tracking
      return;
    }

    // If db is provided, we're inside a transaction already - don't create nested transaction
    if (db != null) {
      await _applyTransactionToBudgetsInternal(transaction, allowOverdraft);
    } else {
      // Create our own transaction
      await _budgetDao.db.transaction(() async {
        await _applyTransactionToBudgetsInternal(transaction, allowOverdraft);
      });
    }
  }

  Future<void> _applyTransactionToBudgetsInternal(
    Transaction transaction,
    bool allowOverdraft,
  ) async {
    // Find active budget for this category at transaction date
    final budget = await _budgetDao.getActiveBudgetForCategoryAt(
      transaction.categoryId!,
      transaction.dateTime,
    );

    if (budget == null) {
      // No budget for this category/period - nothing to update
      return;
    }

    // Calculate new consumed amount
    final newConsumed = budget.consumedCents + transaction.amountCents;
    final newOverdraft = newConsumed > budget.limitCents ? newConsumed - budget.limitCents : 0;

    // Check if we're exceeding budget without allowOverdraft
    if (newConsumed > budget.limitCents && !budget.allowOverdraft && !allowOverdraft) {
      final remaining = budget.limitCents - budget.consumedCents;
      throw BudgetExceededException(
        remainingCents: remaining,
        message: 'Budget exceeded. Remaining: $remaining cents, attempted: ${transaction.amountCents} cents',
      );
    }

    // Update budget consumed and overdraft
    await _budgetDao.updateBudget(
      budget.copyWith(
        consumedCents: newConsumed,
        overdraftCents: newOverdraft,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Recalculate consumed amount for a budget by summing all transactions
  Future<void> recalculateBudgetConsumed(String budgetId) async {
    await _budgetDao.recalculateConsumed(budgetId);
  }

  /// Recalculate consumed for a Budget model (overload for compatibility)
  Future<void> recalculateConsumed(dynamic budget) async {
    if (budget is String) {
      await recalculateBudgetConsumed(budget);
    } else {
      await recalculateBudgetConsumed(budget.id);
    }
  }

  /// Check for budget overlap (prevent multiple budgets for same category/period)
  /// Throws BudgetDuplicateException if a budget already exists
  Future<void> checkBudgetOverlap(
    String categoryId,
    DateTime periodStart,
    DateTime periodEnd,
    String? excludeBudgetId,
  ) async {
    // Check if there's already a budget with the same categoryId and periodStart
    final existingBudget = await _budgetDao.getBudgetByCategoryAndPeriodStart(
      categoryId,
      periodStart,
      excludeBudgetId,
    );
    
    if (existingBudget != null) {
      // Get category name
      String categoryName = 'Danh mục';
      if (_categoryRepository != null) {
        final category = await _categoryRepository!.getCategoryById(categoryId);
        categoryName = category?.name ?? 'Danh mục';
      }
      
      // Get budget name
      final budgetName = existingBudget.name ?? 'Hũ chi tiêu';
      
      throw BudgetDuplicateException(
        categoryName: categoryName,
        budgetName: budgetName,
      );
    }
  }
}

