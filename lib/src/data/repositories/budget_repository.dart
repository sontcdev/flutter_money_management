// path: lib/src/data/repositories/budget_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/budget.dart' as model;
import '../../services/budget_service.dart';

class BudgetRepository {
  final SupabaseClient _supabase;
  final String? Function() _getActiveWorkspaceId;
  final String? Function() _getCurrentUserId;
  final _uuid = const Uuid();

  BudgetRepository(
    this._supabase,
    this._getActiveWorkspaceId,
    this._getCurrentUserId,
  );

  Future<List<model.Budget>> getAllBudgets() async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('budgets')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('period_start');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(_mapBudget)
        .toList();
  }

  Future<model.Budget> getBudgetById(String id) async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('budgets')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      throw Exception('Budget not found: $id');
    }

    return _mapBudget(response);
  }

  Future<List<model.Budget>> getBudgetsByCategory(String categoryId) async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('budgets')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('category_id', categoryId)
        .isFilter('deleted_at', null)
        .order('period_start');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(_mapBudget)
        .toList();
  }

  Future<model.Budget?> getActiveBudgetForCategoryAndDate(
    String categoryId,
    DateTime date,
  ) async {
    final budgets = await getBudgetsByCategory(categoryId);
    for (final budget in budgets) {
      final isWithinPeriod = !date.isBefore(budget.periodStart) &&
          !date.isAfter(budget.periodEnd);
      if (isWithinPeriod) {
        return budget;
      }
    }
    return null;
  }

  Future<model.Budget> createBudget(model.Budget budget) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();
    await _validateBudgetPeriod(
      categoryId: budget.categoryId,
      start: budget.periodStart,
      end: budget.periodEnd,
    );

    final id = budget.id.isEmpty ? _uuid.v4() : budget.id;
    await _supabase.from('budgets').insert({
      'id': id,
      'workspace_id': workspaceId,
      'category_id': budget.categoryId,
      'period_type': budget.periodType.name,
      'period_start': budget.periodStart.toIso8601String(),
      'period_end': budget.periodEnd.toIso8601String(),
      'limit_minor': budget.limitCents,
      'currency_code': 'VND',
      'allow_overdraft': budget.allowOverdraft,
      'created_by_user_id': userId,
      'updated_by_user_id': userId,
      'created_at': budget.createdAt.toIso8601String(),
      'updated_at': budget.updatedAt.toIso8601String(),
    });

    return getBudgetById(id);
  }

  Future<void> updateBudget(model.Budget budget) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();
    await _validateBudgetPeriod(
      categoryId: budget.categoryId,
      start: budget.periodStart,
      end: budget.periodEnd,
      excludeId: budget.id,
    );

    await _supabase.from('budgets').update({
      'category_id': budget.categoryId,
      'period_type': budget.periodType.name,
      'period_start': budget.periodStart.toIso8601String(),
      'period_end': budget.periodEnd.toIso8601String(),
      'limit_minor': budget.limitCents,
      'allow_overdraft': budget.allowOverdraft,
      'updated_by_user_id': userId,
      'updated_at': budget.updatedAt.toIso8601String(),
    }).eq('workspace_id', workspaceId).eq('id', budget.id);
  }

  Future<void> deleteBudget(String id) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();
    await _supabase.from('budgets').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'deleted_by_user_id': userId,
      'updated_by_user_id': userId,
    }).eq('workspace_id', workspaceId).eq('id', id);
  }

  Future<void> recalculateConsumed(String budgetId) async {
    await getBudgetById(budgetId);
  }

  Future<void> _validateBudgetPeriod({
    required String categoryId,
    required DateTime start,
    required DateTime end,
    String? excludeId,
  }) async {
    final budgets = await getBudgetsByCategory(categoryId);
    final hasOverlap = budgets.any((budget) {
      if (excludeId != null && budget.id == excludeId) {
        return false;
      }
      return !end.isBefore(budget.periodStart) && !start.isAfter(budget.periodEnd);
    });

    if (hasOverlap) {
      throw BudgetOverlapException(
        'Budget period overlaps with existing budget for this category',
      );
    }
  }

  model.Budget _mapBudget(Map<String, dynamic> item) {
    return model.Budget(
      id: item['id'] as String,
      categoryId: item['category_id'] as String,
      periodType: _parsePeriodType(item['period_type'] as String),
      periodStart: DateTime.parse(item['period_start'] as String),
      periodEnd: DateTime.parse(item['period_end'] as String),
      limitCents: item['limit_minor'] as int,
      consumedCents: 0,
      allowOverdraft: item['allow_overdraft'] as bool? ?? false,
      overdraftCents: 0,
      createdAt: DateTime.parse(item['created_at'] as String),
      updatedAt: DateTime.parse(item['updated_at'] as String),
      syncStatus: model.SyncStatus.synced,
      deletedAt: item['deleted_at'] != null
          ? DateTime.parse(item['deleted_at'] as String)
          : null,
    );
  }

  model.PeriodType _parsePeriodType(String value) {
    switch (value) {
      case 'yearly':
        return model.PeriodType.yearly;
      case 'custom':
        return model.PeriodType.custom;
      case 'monthly':
      default:
        return model.PeriodType.monthly;
    }
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
