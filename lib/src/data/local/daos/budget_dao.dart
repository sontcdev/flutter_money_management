// path: lib/src/data/local/daos/budget_dao.dart
import 'package:drift/drift.dart';
import 'package:test3_cursor/src/models/budget.dart' as model;
import '../app_database.dart';
import '../tables/budgets_table.dart';
import '../tables/transactions_table.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [BudgetsTable, TransactionsTable])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(AppDatabase db) : super(db);

  Future<List<model.Budget>> getAllBudgets() async {
    final rows = await select(budgetsTable).get();
    return rows.map(_rowToBudget).toList();
  }

  Future<model.Budget?> getBudgetById(String id) async {
    final row = await (select(budgetsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _rowToBudget(row) : null;
  }

  Future<model.Budget?> getActiveBudgetForCategoryAt(String categoryId, DateTime date) async {
    final row = await (select(budgetsTable)
          ..where((t) =>
              t.categoryId.equals(categoryId) &
              t.periodStart.isSmallerOrEqualValue(date) &
              t.periodEnd.isBiggerOrEqualValue(date)))
        .getSingleOrNull();
    return row != null ? _rowToBudget(row) : null;
  }

  Future<int> computeConsumed(model.Budget budget) async {
    // Sum all transaction amounts for this category within the budget period
    final result = await (selectOnly(transactionsTable)
          ..addColumns([transactionsTable.amountCents.sum()])
          ..where(transactionsTable.categoryId.equals(budget.categoryId) &
              transactionsTable.transactionDate.isBiggerOrEqualValue(budget.periodStart) &
              transactionsTable.transactionDate.isSmallerOrEqualValue(budget.periodEnd)))
        .getSingle();

    return result.read(transactionsTable.amountCents.sum()) ?? 0;
  }

  int remainingCents(model.Budget budget) {
    return budget.limitCents - budget.consumedCents;
  }

  Future<void> recalculateConsumed(String budgetId) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) return;

    final consumed = await computeConsumed(budget);
    final overdraft = (consumed > budget.limitCents ? consumed - budget.limitCents : 0).toInt();

    await (update(budgetsTable)..where((t) => t.id.equals(budgetId))).write(
      BudgetsTableCompanion(
        consumedCents: Value(consumed),
        overdraftCents: Value(overdraft),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> insertBudget(model.Budget budget) async {
    await into(budgetsTable).insert(_budgetToRow(budget));
  }

  Future<void> updateBudget(model.Budget budget) async {
    await (update(budgetsTable)..where((t) => t.id.equals(budget.id)))
        .write(_budgetToRow(budget));
  }

  Future<int> deleteBudget(String id) {
    return (delete(budgetsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<model.Budget>> getBudgetsForCategory(String categoryId) async {
    final rows = await (select(budgetsTable)..where((t) => t.categoryId.equals(categoryId))).get();
    return rows.map(_rowToBudget).toList();
  }

  Future<List<model.Budget>> getActiveBudgetsForCategory(String? categoryId, DateTime date) async {
    if (categoryId == null) return [];
    final rows = await (select(budgetsTable)
          ..where((t) =>
              t.categoryId.equals(categoryId) &
              t.periodStart.isSmallerOrEqualValue(date) &
              t.periodEnd.isBiggerOrEqualValue(date)))
        .get();
    return rows.map(_rowToBudget).toList();
  }

  /// Get budget by categoryId and periodStart (for duplicate checking)
  Future<model.Budget?> getBudgetByCategoryAndPeriodStart(
    String categoryId,
    DateTime periodStart,
    String? excludeBudgetId,
  ) async {
    var condition = budgetsTable.categoryId.equals(categoryId) &
        budgetsTable.periodStart.equals(periodStart);
    
    if (excludeBudgetId != null) {
      condition = condition & budgetsTable.id.isNotValue(excludeBudgetId);
    }
    
    final row = await (select(budgetsTable)..where((t) => condition)).getSingleOrNull();
    return row != null ? _rowToBudget(row) : null;
  }

  model.Budget _rowToBudget(BudgetEntity row) {
    return model.Budget(
      id: row.id,
      name: row.name,
      categoryId: row.categoryId,
      periodType: model.PeriodType.custom,
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

  BudgetsTableCompanion _budgetToRow(model.Budget budget) {
    return BudgetsTableCompanion(
      id: Value(budget.id),
      name: Value(budget.name),
      categoryId: Value(budget.categoryId),
      limitCents: Value(budget.limitCents),
      consumedCents: Value(budget.consumedCents),
      allowOverdraft: Value(budget.allowOverdraft),
      overdraftCents: Value(budget.overdraftCents),
      periodStart: Value(budget.periodStart),
      periodEnd: Value(budget.periodEnd),
      createdAt: Value(budget.createdAt),
      updatedAt: Value(budget.updatedAt),
    );
  }
}

// Generated code will be in budget_dao.g.dart

