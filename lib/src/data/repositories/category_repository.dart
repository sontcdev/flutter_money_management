// path: lib/src/data/repositories/category_repository.dart
import 'package:test3_cursor/src/models/category.dart' as model;
import 'package:test3_cursor/src/data/local/app_database.dart';

class CategoryInUseException implements Exception {
  final String message;
  CategoryInUseException(this.message);
}

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Future<List<model.Category>> getAllCategories() async {
    return await _db.categoryDao.getAllCategories();
  }

  Future<model.Category?> getCategoryById(String id) async {
    return await _db.categoryDao.getCategoryById(id);
  }

  Future<model.Category> createCategory(model.Category category) async {
    await _db.categoryDao.insertCategory(category);
    return category;
  }

  Future<model.Category> updateCategory(model.Category category) async {
    await _db.categoryDao.updateCategory(category);
    return category;
  }

  Future<void> deleteCategory(String id) async {
    final hasTransactions = await _db.categoryDao.hasTransactions(id);
    if (hasTransactions) {
      throw CategoryInUseException('Category is in use by transactions');
    }
    await _db.categoryDao.deleteCategory(id);
  }
}

