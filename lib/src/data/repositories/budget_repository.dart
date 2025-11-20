// path: lib/src/data/repositories/budget_repository.dart
import 'package:test3_cursor/src/models/budget.dart' as model;
import 'package:test3_cursor/src/data/local/app_database.dart';
import 'package:test3_cursor/src/services/budget_service.dart';

class BudgetRepository {
  final AppDatabase _db;
  final BudgetService _budgetService;

  BudgetRepository(this._db, this._budgetService);

  Future<List<model.Budget>> getAllBudgets() async {
    return await _db.budgetDao.getAllBudgets();
  }

  Future<model.Budget?> getBudgetById(String id) async {
    return await _db.budgetDao.getBudgetById(id);
  }

  Future<model.Budget> createBudget(model.Budget budget) async {
    await _budgetService.checkBudgetOverlap(
        budget.categoryId, budget.periodStart, budget.periodEnd, null);
    await _db.budgetDao.insertBudget(budget);
    return budget;
  }

  Future<model.Budget> updateBudget(model.Budget budget) async {
    await _budgetService.checkBudgetOverlap(budget.categoryId,
        budget.periodStart, budget.periodEnd, budget.id);
    await _db.budgetDao.updateBudget(budget);
    return budget;
  }

  Future<void> deleteBudget(String id) async {
    await _db.budgetDao.deleteBudget(id);
  }

  Future<List<model.Budget>> getActiveBudgetsForCategory(
      String categoryId, DateTime date) async {
    return await _db.budgetDao.getActiveBudgetsForCategory(categoryId, date);
  }

  Future<void> recalculateBudget(String budgetId) async {
    final budget = await getBudgetById(budgetId);
    if (budget != null) {
      await _budgetService.recalculateConsumed(budget);
    }
  }
}

