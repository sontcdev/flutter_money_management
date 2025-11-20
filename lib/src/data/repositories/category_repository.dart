// path: lib/src/data/repositories/category_repository.dart

import 'package:drift/drift.dart';
import '../local/app_database.dart';
import '../../models/category.dart' as model;
import '../../services/budget_service.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Future<List<model.Category>> getAllCategories() async {
    final entities = await _db.categoryDao.getAllCategories();
    return entities.map(_entityToModel).toList();
  }

  Future<model.Category> getCategoryById(int id) async {
    final entity = await _db.categoryDao.getCategoryById(id);
    return _entityToModel(entity);
  }

  Future<model.Category> createCategory(model.Category category) async {
    final companion = _modelToCompanion(category);
    final id = await _db.categoryDao.insertCategory(companion);
    return getCategoryById(id);
  }

  Future<void> updateCategory(model.Category category) async {
    final companion = _modelToCompanion(category);
    await _db.categoryDao.updateCategory(companion);
  }

  Future<void> deleteCategory(int id) async {
    // Check if category is in use
    final inUse = await _db.categoryDao.isCategoryInUse(id);
    if (inUse) {
      throw CategoryInUseException(
          'Category is in use and cannot be deleted');
    }
    await _db.categoryDao.deleteCategory(id);
  }

  model.Category _entityToModel(CategoryEntity entity) {
    return model.Category(
      id: entity.id,
      name: entity.name,
      iconName: entity.iconName,
      colorValue: entity.colorValue,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CategoriesCompanion _modelToCompanion(model.Category category) {
    return CategoriesCompanion(
      id: category.id > 0 ? Value(category.id) : const Value.absent(),
      name: Value(category.name),
      iconName: Value(category.iconName),
      colorValue: Value(category.colorValue),
      createdAt: Value(category.createdAt),
      updatedAt: Value(category.updatedAt),
    );
  }
}

