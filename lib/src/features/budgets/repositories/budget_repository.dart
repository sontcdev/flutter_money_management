// path: lib/src/data/repositories/budget_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart'
    as model;

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

  Future<List<model.Budget>> getAllBudgets(
      {String? workspaceIdOverride}) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
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

  Future<model.Budget> getBudgetById(
    String id, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
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

  Future<List<model.Budget>> getBudgetsByCategory(
    String categoryId, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
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
      final isWithinPeriod =
          !date.isBefore(budget.periodStart) && !date.isAfter(budget.periodEnd);
      if (isWithinPeriod) {
        return budget;
      }
    }
    return null;
  }

  Future<model.Budget> createBudget(
    model.Budget budget, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();
    await _validateBudgetPeriod(
      categoryId: budget.categoryId,
      start: budget.periodStart,
      end: budget.periodEnd,
      workspaceIdOverride: workspaceIdOverride,
    );

    final id = budget.id.isEmpty ? _uuid.v4() : budget.id;
    try {
      final response = await _supabase.rpc('create_budget_rpc', params: {
        'p_workspace_id': workspaceId,
        'p_category_id': budget.categoryId,
        'p_period_type': budget.periodType.name,
        'p_period_start': budget.periodStart.toIso8601String(),
        'p_period_end': budget.periodEnd.toIso8601String(),
        'p_limit_minor': budget.limitCents,
        'p_currency_code': 'VND',
        'p_allow_overdraft': budget.allowOverdraft,
        'p_id': id,
        'p_created_at': budget.createdAt.toIso8601String(),
        'p_updated_at': budget.updatedAt.toIso8601String(),
      });
      return _mapBudget((response as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> updateBudget(
    model.Budget budget, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();
    await _validateBudgetPeriod(
      categoryId: budget.categoryId,
      start: budget.periodStart,
      end: budget.periodEnd,
      excludeId: budget.id,
      workspaceIdOverride: workspaceIdOverride,
    );

    try {
      await _supabase.rpc('update_budget_rpc', params: {
        'p_budget_id': budget.id,
        'p_workspace_id': workspaceId,
        'p_category_id': budget.categoryId,
        'p_period_type': budget.periodType.name,
        'p_period_start': budget.periodStart.toIso8601String(),
        'p_period_end': budget.periodEnd.toIso8601String(),
        'p_limit_minor': budget.limitCents,
        'p_currency_code': 'VND',
        'p_allow_overdraft': budget.allowOverdraft,
        'p_updated_at': budget.updatedAt.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> deleteBudget(
    String id, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();
    try {
      await _supabase.rpc('soft_delete_budget_rpc', params: {
        'p_budget_id': id,
        'p_workspace_id': workspaceId,
      });
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> recalculateConsumed(String budgetId) async {
    await getBudgetById(budgetId);
  }

  Future<void> _validateBudgetPeriod({
    required String categoryId,
    required DateTime start,
    required DateTime end,
    String? excludeId,
    String? workspaceIdOverride,
  }) async {
    final budgets = await getBudgetsByCategory(
      categoryId,
      workspaceIdOverride: workspaceIdOverride,
    );
    final hasOverlap = budgets.any((budget) {
      if (excludeId != null && budget.id == excludeId) {
        return false;
      }
      return !end.isBefore(budget.periodStart) &&
          !start.isAfter(budget.periodEnd);
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

  String _requireWorkspaceId([String? workspaceIdOverride]) {
    final workspaceId = workspaceIdOverride ?? _getActiveWorkspaceId();
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
