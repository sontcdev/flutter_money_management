// path: lib/src/data/local/daos/budget_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budgets_table.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Future<List<BudgetEntity>> getAllBudgets() {
    return select(budgets).get();
  }

  Future<BudgetEntity> getBudgetById(int id) {
    return (select(budgets)..where((b) => b.id.equals(id))).getSingle();
  }

  Future<List<BudgetEntity>> getBudgetsByCategory(int categoryId) {
    return (select(budgets)..where((b) => b.categoryId.equals(categoryId)))
        .get();
  }

  Future<BudgetEntity?> getActiveBudgetForCategoryAndDate(
      int categoryId, DateTime date) async {
    final result = await (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.periodStart.isSmallerOrEqualValue(date) &
              b.periodEnd.isBiggerOrEqualValue(date)))
        .getSingleOrNull();
    return result;
  }

  Future<bool> hasOverlappingBudget(
      int categoryId, DateTime start, DateTime end, {int? excludeId}) async {
    var query = select(budgets)
      ..where((b) =>
          b.categoryId.equals(categoryId) &
          (b.periodStart.isSmallerThanValue(end) &
              b.periodEnd.isBiggerThanValue(start)));

    if (excludeId != null) {
      query = query..where((b) => b.id.equals(excludeId).not());
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  Future<int> insertBudget(BudgetsCompanion budget) {
    return into(budgets).insert(budget);
  }

  Future<bool> updateBudget(BudgetsCompanion budget) {
    return update(budgets).replace(budget);
  }

  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  Future<void> updateConsumed(int budgetId, int consumedCents,
      int overdraftCents) async {
    await (update(budgets)..where((b) => b.id.equals(budgetId))).write(
      BudgetsCompanion(
        consumedCents: Value(consumedCents),
        overdraftCents: Value(overdraftCents),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> computeConsumed(BudgetEntity budget) async {
    final query = selectOnly(db.transactions)
      ..addColumns([db.transactions.amountCents.sum()])
      ..where(db.transactions.categoryId.equals(budget.categoryId) &
          db.transactions.transactionDate.isBiggerOrEqualValue(budget.periodStart) &
          db.transactions.transactionDate.isSmallerOrEqualValue(budget.periodEnd) &
          db.transactions.type.equals('expense'));

    final result = await query.getSingle();
    return result.read(db.transactions.amountCents.sum()) ?? 0;
  }

  Future<void> recalculateConsumed(int budgetId) async {
    final budget = await getBudgetById(budgetId);
    final consumed = await computeConsumed(budget);
    final overdraft = consumed > budget.limitCents
        ? consumed - budget.limitCents
        : 0;
    await updateConsumed(budgetId, consumed, overdraft);
  }
}

