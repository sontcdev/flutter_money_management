// path: lib/src/providers/category_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../data/repositories/category_repository.dart';
import '../data/local/daos/category_dao.dart';
import 'providers.dart';

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryDao(db);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dao = ref.watch(categoryDaoProvider);
  return CategoryRepository(dao);
});

final categoryListProvider = AsyncNotifierProvider<CategoryListNotifier, List<Category>>(
  CategoryListNotifier.new,
);

class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return _loadCategories();
  }

  Future<List<Category>> _loadCategories() async {
    final repository = ref.read(categoryRepositoryProvider);
    return await repository.getAllCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _loadCategories();
    });
  }

  Future<void> addCategory({
    required String name,
    required CategoryType type,
    String? colorHex,
    String? iconName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.createCategory(
        name: name,
        type: type,
        colorHex: colorHex,
        iconName: iconName,
      );
      return await _loadCategories();
    });
  }

  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.updateCategory(category);
      return await _loadCategories();
    });
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.deleteCategory(id);
      return await _loadCategories();
    });
  }
}

final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return await repository.getCategoryById(id);
});

