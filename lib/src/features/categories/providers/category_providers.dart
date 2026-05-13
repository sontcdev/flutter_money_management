import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/categories/repositories/category_repository.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CategoryRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories();
});

final categoriesForWorkspaceProvider =
    FutureProvider.family<List<Category>, String>((ref, workspaceId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories(workspaceIdOverride: workspaceId);
});

final categoriesByTypeProvider =
    FutureProvider.family<List<Category>, CategoryType>((ref, type) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoriesByType(type);
});

typedef WorkspaceCategoryTypeQuery = ({String workspaceId, CategoryType type});

final categoriesByTypeForWorkspaceProvider =
    FutureProvider.family<List<Category>, WorkspaceCategoryTypeQuery>(
        (ref, query) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoriesByType(
    query.type,
    workspaceIdOverride: query.workspaceId,
  );
});

final categoryProvider =
    FutureProvider.family<Category?, String>((ref, categoryId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
});
