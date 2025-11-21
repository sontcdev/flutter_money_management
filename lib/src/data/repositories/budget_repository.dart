// path: lib/src/data/repositories/budget_repository.dart
import '../../models/budget.dart' as model;
import '../local/app_database.dart';
import '../../services/budget_service.dart';
import 'category_repository.dart';

class BudgetRepository {
  final AppDatabase _db;
  final BudgetService _budgetService;
  final CategoryRepository _categoryRepository;

  BudgetRepository(this._db, this._budgetService, this._categoryRepository) {
    // Set category repository for budget service to get category names
    _budgetService.setCategoryRepository(_categoryRepository);
  }

  Future<List<model.Budget>> getAllBudgets() async {
    final budgets = await _db.budgetDao.getAllBudgets();
    // Recalculate consumedCents for all budgets to ensure accuracy
    for (final budget in budgets) {
      await _budgetService.recalculateConsumed(budget);
    }
    // Return updated budgets
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

