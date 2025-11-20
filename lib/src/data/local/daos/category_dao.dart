// path: lib/src/data/local/daos/category_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';
import '../tables/transactions_table.dart';
import '../tables/budgets_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable, TransactionsTable, BudgetsTable])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);

  Future<List<CategoryEntity>> getAllCategories() {
    return select(categoriesTable).get();
  }

  Future<CategoryEntity?> getCategoryById(String id) {
    return (select(categoriesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CategoryEntity>> searchByName(String query) {
    return (select(categoriesTable)
          ..where((t) => t.name.like('%$query%')))
        .get();
  }

  Future<int> insertCategory(CategoryEntity category) {
    return into(categoriesTable).insert(category);
  }

  Future<bool> updateCategory(CategoryEntity category) {
    return update(categoriesTable).replace(category);
  }

  Future<int> deleteCategory(String id) {
    return (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> isCategoryInUse(String categoryId) async {
    // Only check if any budget references this category
    // Transactions are allowed - they will be set to null when category is deleted
    final budgetCount = await (selectOnly(budgetsTable)
          ..addColumns([budgetsTable.id])
          ..where(budgetsTable.categoryId.equals(categoryId))
          ..limit(1))
        .get()
        .then((rows) => rows.length);

    return budgetCount > 0;
  }

  Future<int> getTransactionCountForCategory(String categoryId) async {
    final countQuery = selectOnly(transactionsTable)
      ..addColumns([transactionsTable.id.count()])
      ..where(transactionsTable.categoryId.equals(categoryId));
    final result = await countQuery.getSingle();
    return result.read(transactionsTable.id.count()) ?? 0;
  }

  Future<int> getBudgetCountForCategory(String categoryId) async {
    final countQuery = selectOnly(budgetsTable)
      ..addColumns([budgetsTable.id.count()])
      ..where(budgetsTable.categoryId.equals(categoryId));
    final result = await countQuery.getSingle();
    return result.read(budgetsTable.id.count()) ?? 0;
  }

  /// Set categoryId to null for all transactions with this categoryId
  Future<int> removeCategoryFromTransactions(String categoryId) async {
    return await (update(transactionsTable)
          ..where((t) => t.categoryId.equals(categoryId)))
        .write(TransactionsTableCompanion(categoryId: const Value.absent()));
  }
}

// Generated code will be in category_dao.g.dart

