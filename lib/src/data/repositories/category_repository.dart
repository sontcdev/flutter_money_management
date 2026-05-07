// path: lib/src/data/repositories/category_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/category.dart' as model;
import '../../services/budget_service.dart';
import '../../utils/category_color_codec.dart';

class CategoryRepository {
  final SupabaseClient _supabase;
  final String? Function() _getActiveWorkspaceId;
  final String? Function() _getCurrentUserId;
  final _uuid = const Uuid();

  CategoryRepository(
    this._supabase,
    this._getActiveWorkspaceId,
    this._getCurrentUserId,
  );

  Future<List<model.Category>> getAllCategories() async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('categories')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('sort_order')
        .order('name');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(_mapCategory)
        .toList();
  }

  Future<List<model.Category>> getCategoriesByType(model.CategoryType type) async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('categories')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('type', type.name)
        .isFilter('deleted_at', null)
        .order('sort_order')
        .order('name');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(_mapCategory)
        .toList();
  }

  Future<model.Category?> getCategoryById(String id) async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('categories')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _mapCategory(response);
  }

  Future<model.Category> createCategory(model.Category category) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();
    final id = category.id.isEmpty ? _uuid.v4() : category.id;

    await _supabase.from('categories').insert({
      'id': id,
      'workspace_id': workspaceId,
      'name': category.name.trim(),
      'type': category.type.name,
      'icon_name': category.iconName,
      'color_value': encodeCategoryColor(category.colorValue),
      'created_by_user_id': userId,
      'updated_by_user_id': userId,
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': category.updatedAt.toIso8601String(),
    });

    final created = await getCategoryById(id);
    if (created == null) {
      throw Exception('Failed to load created category: $id');
    }
    return created;
  }

  Future<void> updateCategory(model.Category category) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();

    await _supabase.from('categories').update({
      'name': category.name.trim(),
      'type': category.type.name,
      'icon_name': category.iconName,
      'color_value': encodeCategoryColor(category.colorValue),
      'updated_by_user_id': userId,
      'updated_at': category.updatedAt.toIso8601String(),
    }).eq('workspace_id', workspaceId).eq('id', category.id);
  }

  Future<void> deleteCategory(String id) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();

    final transactionInUse = await _supabase
        .from('transactions')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('category_id', id)
        .isFilter('deleted_at', null)
        .limit(1)
        .maybeSingle();
    if (transactionInUse != null) {
      throw CategoryInUseException('Category is in use and cannot be deleted');
    }

    final budgetInUse = await _supabase
        .from('budgets')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('category_id', id)
        .isFilter('deleted_at', null)
        .limit(1)
        .maybeSingle();
    if (budgetInUse != null) {
      throw CategoryInUseException('Category is in use and cannot be deleted');
    }

    await _supabase.from('categories').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'deleted_by_user_id': userId,
      'updated_by_user_id': userId,
    }).eq('workspace_id', workspaceId).eq('id', id);
  }

  model.Category _mapCategory(Map<String, dynamic> item) {
    return model.Category(
      id: item['id'] as String,
      name: item['name'] as String,
      iconName: item['icon_name'] as String,
      colorValue: decodeCategoryColor(item['color_value']),
      type: (item['type'] as String) == 'income'
          ? model.CategoryType.income
          : model.CategoryType.expense,
      createdAt: DateTime.parse(item['created_at'] as String),
      updatedAt: DateTime.parse(item['updated_at'] as String),
      syncStatus: model.SyncStatus.synced,
      deletedAt: item['deleted_at'] != null
          ? DateTime.parse(item['deleted_at'] as String)
          : null,
    );
  }

  String _requireWorkspaceId() {
    final workspaceId = _getActiveWorkspaceId();
    if (workspaceId == null || workspaceId.isEmpty) {
      throw Exception('No active workspace selected');
    }
    return workspaceId;
  }

  String _requireUserId() {
    final userId = _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user');
    }
    return userId;
  }
}
