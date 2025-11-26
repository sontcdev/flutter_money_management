// path: lib/src/data/repositories/budget_repository.dart

import 'package:drift/drift.dart';
import '../local/app_database.dart';
import '../../models/budget.dart' as model;
import '../../services/budget_service.dart';

class BudgetRepository {
  final AppDatabase _db;
  final BudgetService _budgetService;

  BudgetRepository(this._db, this._budgetService);

  Future<List<model.Budget>> getAllBudgets() async {
    final entities = await _db.budgetDao.getAllBudgets();
    
    // Recalculate consumed for all budgets to ensure up-to-date data
    for (final entity in entities) {
      await _db.budgetDao.recalculateConsumed(entity.id);
    }
    
    // Re-fetch to get updated consumed values
    final updatedEntities = await _db.budgetDao.getAllBudgets();
    return updatedEntities.map(_entityToModel).toList();
  }

  Future<model.Budget> getBudgetById(int id) async {
    final entity = await _db.budgetDao.getBudgetById(id);
    return _entityToModel(entity);
  }

  Future<List<model.Budget>> getBudgetsByCategory(int categoryId) async {
    final entities = await _db.budgetDao.getBudgetsByCategory(categoryId);
    return entities.map(_entityToModel).toList();
  }

  Future<model.Budget?> getActiveBudgetForCategoryAndDate(
      int categoryId, DateTime date) async {
    final entity = await _db.budgetDao
        .getActiveBudgetForCategoryAndDate(categoryId, date);
    return entity != null ? _entityToModel(entity) : null;
  }

  Future<model.Budget> createBudget(model.Budget budget) async {
    // Validate no overlap
    await _budgetService.validateBudgetPeriod(
      budget.categoryId,
      budget.periodStart,
      budget.periodEnd,
    );

    final companion = _modelToCompanion(budget);
    final id = await _db.budgetDao.insertBudget(companion);

    // Recalculate consumed from existing transactions
    await _db.budgetDao.recalculateConsumed(id);

    return getBudgetById(id);
  }

  Future<void> updateBudget(model.Budget budget) async {
    // Validate no overlap (excluding this budget)
    await _budgetService.validateBudgetPeriod(
      budget.categoryId,
      budget.periodStart,
      budget.periodEnd,
      excludeId: budget.id,
    );

    final companion = _modelToCompanion(budget);
    await _db.budgetDao.updateBudget(companion);

    // Recalculate consumed
    await _db.budgetDao.recalculateConsumed(budget.id);
  }

  Future<void> deleteBudget(int id) async {
    await _db.budgetDao.deleteBudget(id);
  }

  Future<void> recalculateConsumed(int budgetId) async {
    await _db.budgetDao.recalculateConsumed(budgetId);
  }

  model.Budget _entityToModel(BudgetEntity entity) {
    return model.Budget(
      id: entity.id,
      categoryId: entity.categoryId,
      periodType: _stringToPeriodType(entity.periodType),
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      limitCents: entity.limitCents,
      consumedCents: entity.consumedCents,
      allowOverdraft: entity.allowOverdraft,
      overdraftCents: entity.overdraftCents,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BudgetsCompanion _modelToCompanion(model.Budget budget) {
    return BudgetsCompanion(
      id: budget.id > 0 ? Value(budget.id) : const Value.absent(),
      categoryId: Value(budget.categoryId),
      periodType: Value(_periodTypeToString(budget.periodType)),
      periodStart: Value(budget.periodStart),
      periodEnd: Value(budget.periodEnd),
      limitCents: Value(budget.limitCents),
      consumedCents: Value(budget.consumedCents),
      allowOverdraft: Value(budget.allowOverdraft),
      overdraftCents: Value(budget.overdraftCents),
      createdAt: Value(budget.createdAt),
      updatedAt: Value(budget.updatedAt),
    );
  }

  model.PeriodType _stringToPeriodType(String type) {
    switch (type) {
      case 'monthly':
        return model.PeriodType.monthly;
      case 'yearly':
        return model.PeriodType.yearly;
      case 'custom':
        return model.PeriodType.custom;
      default:
        return model.PeriodType.monthly;
    }
  }

  String _periodTypeToString(model.PeriodType type) {
    switch (type) {
      case model.PeriodType.monthly:
        return 'monthly';
      case model.PeriodType.yearly:
        return 'yearly';
      case model.PeriodType.custom:
        return 'custom';
    }
  }
}

