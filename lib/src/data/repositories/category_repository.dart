// path: lib/src/data/repositories/category_repository.dart
import '../../models/category.dart';
import '../local/app_database.dart';
import '../local/daos/category_dao.dart';
import 'package:uuid/uuid.dart';

class CategoryInUseException implements Exception {
  final String message;
  final int transactionsCount;
  final int budgetsCount;

  CategoryInUseException({
    required this.message,
    required this.transactionsCount,
    required this.budgetsCount,
  });

  @override
  String toString() => message;
}

class CategoryRepository {
  final CategoryDao _dao;
  final _uuid = const Uuid();

  CategoryRepository(this._dao);

  Future<List<Category>> getAllCategories() async {
    final entities = await _dao.getAllCategories();
    return entities.map(_entityToModel).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final entity = await _dao.getCategoryById(id);
    return entity != null ? _entityToModel(entity) : null;
  }

  Future<List<Category>> searchByName(String query) async {
    final entities = await _dao.searchByName(query);
    return entities.map(_entityToModel).toList();
  }

  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    String? colorHex,
    String? iconName,
  }) async {
    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      name: name,
      type: type,
      colorHex: colorHex,
      iconName: iconName,
      createdAt: now,
      updatedAt: now,
    );

    await _dao.insertCategory(_modelToEntity(category));
    return category;
  }

  Future<void> updateCategory(Category category) async {
    final updated = category.copyWith(updatedAt: DateTime.now());
    await _dao.updateCategory(_modelToEntity(updated));
  }

  Future<void> deleteCategory(String id) async {
    // Check if category is in use by budgets (only check budgets, not transactions)
    final budgetsCount = await _dao.getBudgetCountForCategory(id);
    if (budgetsCount > 0) {
      throw CategoryInUseException(
        message: 'Không thể xóa danh mục này vì đang được gắn với $budgetsCount hũ chi tiêu. Vui lòng xóa các hũ chi tiêu trước.',
        transactionsCount: 0,
        budgetsCount: budgetsCount,
      );
    }
    
    // If no budgets, proceed with deletion
    // First, set categoryId to null for all transactions with this category
    await _dao.removeCategoryFromTransactions(id);
    
    // Then delete the category
    await _dao.deleteCategory(id);
  }

  Category _entityToModel(CategoryEntity entity) {
    return Category(
      id: entity.id,
      name: entity.name,
      type: entity.type == 'expense' ? CategoryType.expense : CategoryType.income,
      colorHex: entity.colorHex,
      iconName: entity.iconName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CategoryEntity _modelToEntity(Category category) {
    return CategoryEntity(
      id: category.id,
      name: category.name,
      type: category.type == CategoryType.expense ? 'expense' : 'income',
      colorHex: category.colorHex,
      iconName: category.iconName,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }
}

