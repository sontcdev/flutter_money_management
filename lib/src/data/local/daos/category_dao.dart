// path: lib/src/data/local/daos/category_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);

  Future<List<CategoryEntity>> getAllCategories() {
    return select(categories).get();
  }

  Future<CategoryEntity> getCategoryById(int id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(category);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Future<bool> isCategoryInUse(int categoryId) async {
    // Check if any transactions reference this category
    final txnQuery = selectOnly(db.transactions)
      ..addColumns([db.transactions.id])
      ..where(db.transactions.categoryId.equals(categoryId))
      ..limit(1);

    final txnResult = await txnQuery.getSingleOrNull();
    if (txnResult != null) return true;

    // Check if any budgets reference this category
    final budgetQuery = selectOnly(db.budgets)
      ..addColumns([db.budgets.id])
      ..where(db.budgets.categoryId.equals(categoryId))
      ..limit(1);

    final budgetResult = await budgetQuery.getSingleOrNull();
    return budgetResult != null;
  }
}

