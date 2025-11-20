// path: lib/src/data/local/daos/category_dao.dart
import 'package:drift/drift.dart';
import 'package:test3_cursor/src/models/category.dart' as model;
import '../tables/categories_table.dart';
import '../app_database.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<model.Category>> getAllCategories() async {
    final rows = await select(categories).get();
    return rows.map(_rowToCategory).toList();
  }

  Future<model.Category?> getCategoryById(String id) async {
    final row = await (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _rowToCategory(row) : null;
  }

  Future<void> insertCategory(model.Category category) async {
    await into(categories).insert(_categoryToRow(category),
        mode: InsertMode.replace);
  }

  Future<void> updateCategory(model.Category category) async {
    await (update(categories)..where((c) => c.id.equals(category.id)))
        .write(_categoryToRow(category));
  }

  Future<void> deleteCategory(String id) async {
    await (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Future<bool> hasTransactions(String categoryId) async {
    final count = await (db.selectOnly(db.transactions)
          ..addColumns([db.transactions.id.count()])
          ..where(db.transactions.categoryId.equals(categoryId)))
        .getSingle();
    return (count.read(db.transactions.id.count()) ?? 0) > 0;
  }

  model.Category _rowToCategory(Category row) {
    return model.Category(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  CategoriesCompanion _categoryToRow(model.Category category) {
    return CategoriesCompanion(
      id: Value(category.id),
      name: Value(category.name),
      icon: Value(category.icon),
      color: Value(category.color),
      createdAt: Value(category.createdAt),
      updatedAt: Value(category.updatedAt),
    );
  }
}

