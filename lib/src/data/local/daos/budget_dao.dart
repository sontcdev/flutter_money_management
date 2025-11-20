// path: lib/src/data/local/daos/budget_dao.dart
import 'package:drift/drift.dart';
import 'package:test3_cursor/src/models/budget.dart' as model;
import '../tables/budgets_table.dart';
import '../app_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Future<List<model.Budget>> getAllBudgets() async {
    final rows = await select(budgets).get();
    return rows.map(_rowToBudget).toList();
  }

  Future<model.Budget?> getBudgetById(String id) async {
    final row = await (select(budgets)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _rowToBudget(row) : null;
  }

  Future<List<model.Budget>> getActiveBudgetsForCategory(
      String categoryId, DateTime date) async {
    final rows = await (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.periodStart.isSmallerOrEqualValue(date) &
              b.periodEnd.isBiggerOrEqualValue(date)))
        .get();
    return rows.map(_rowToBudget).toList();
  }

  Future<List<model.Budget>> getOverlappingBudgets(
      String categoryId, DateTime periodStart, DateTime periodEnd) async {
    final rows = await (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              ((b.periodStart.isSmallerOrEqualValue(periodStart) &
                      b.periodEnd.isBiggerOrEqualValue(periodStart)) |
                  (b.periodStart.isSmallerOrEqualValue(periodEnd) &
                      b.periodEnd.isBiggerOrEqualValue(periodEnd)) |
                  (b.periodStart.isBiggerOrEqualValue(periodStart) &
                      b.periodEnd.isSmallerOrEqualValue(periodEnd)))))
        .get();
    return rows.map(_rowToBudget).toList();
  }

  Future<void> insertBudget(model.Budget budget) async {
    await into(budgets).insert(_budgetToRow(budget), mode: InsertMode.replace);
  }

  Future<void> updateBudget(model.Budget budget) async {
    await (update(budgets)..where((b) => b.id.equals(budget.id)))
        .write(_budgetToRow(budget));
  }

  Future<void> deleteBudget(String id) async {
    await (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  Future<void> updateConsumed(String id, int consumedCents, int overdraftCents) async {
    await (update(budgets)..where((b) => b.id.equals(id))).write(
        BudgetsCompanion(
            consumedCents: Value(consumedCents),
            overdraftCents: Value(overdraftCents),
            updatedAt: Value(DateTime.now())));
  }

  Future<int> computeConsumed(model.Budget budget) async {
    final total = await db.transactionDao.getTotalByCategory(
        budget.categoryId, budget.periodStart, budget.periodEnd);
    return total;
  }

  int remainingCents(model.Budget budget) {
    return budget.limitCents - budget.consumedCents;
  }

  model.Budget _rowToBudget(Budget row) {
    return model.Budget(
      id: row.id,
      categoryId: row.categoryId,
      periodType: model.PeriodType.values.firstWhere(
        (e) => e.name == row.periodType,
        orElse: () => model.PeriodType.monthly,
      ),
      periodStart: row.periodStart,
      periodEnd: row.periodEnd,
      limitCents: row.limitCents,
      consumedCents: row.consumedCents,
      allowOverdraft: row.allowOverdraft,
      overdraftCents: row.overdraftCents,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  BudgetsCompanion _budgetToRow(model.Budget budget) {
    return BudgetsCompanion(
      id: Value(budget.id),
      categoryId: Value(budget.categoryId),
      periodType: Value(budget.periodType.name),
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
}

