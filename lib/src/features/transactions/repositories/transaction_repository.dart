// path: lib/src/data/repositories/transaction_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_transaction_service.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart'
    as budget_model;
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;

class TransactionRepository implements TransactionCreationGateway {
  final SupabaseClient _supabase;
  final String? Function() _getActiveWorkspaceId;
  final String? Function() _getCurrentUserId;
  final _uuid = const Uuid();

  TransactionRepository(
    this._supabase,
    this._getActiveWorkspaceId,
    this._getCurrentUserId,
  );

  Future<List<model.Transaction>> getAllTransactions({
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('transaction_at', ascending: false);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(_mapTransaction)
        .toList();
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('workspace_id', workspaceId)
        .gte('transaction_at', start.toIso8601String())
        .lte('transaction_at', end.toIso8601String())
        .isFilter('deleted_at', null)
        .order('transaction_at', ascending: false);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(_mapTransaction)
        .toList();
  }

  Future<model.Transaction> getTransactionById(
    String id, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      throw Exception('Transaction not found: $id');
    }

    return _mapTransaction(response);
  }

  @override
  Future<model.Transaction> createTransaction(
    model.Transaction transaction, {
    bool allowOverdraft = false,
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();
    final id = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
    final transactionWithId = transaction.copyWith(id: id);

    await _validateBudgetImpact(
      transaction: transactionWithId,
      allowOverdraft: allowOverdraft,
      workspaceIdOverride: workspaceIdOverride,
    );

    try {
      final response = await _supabase.rpc('create_transaction_rpc', params: {
        'p_workspace_id': workspaceId,
        'p_category_id': transaction.categoryId,
        'p_amount_minor': transaction.amountCents,
        'p_currency_code': transaction.currency,
        'p_transaction_type': transaction.type.name,
        'p_transaction_at': transaction.dateTime.toIso8601String(),
        'p_wallet_id': transaction.walletId,
        'p_to_wallet_id': transaction.toWalletId,
        'p_note': transaction.note,
        'p_client_reference_id': id,
        'p_allow_overdraft_override': allowOverdraft,
        'p_id': id,
        'p_created_at': transaction.createdAt.toIso8601String(),
        'p_updated_at': transaction.updatedAt.toIso8601String(),
      });
      return _mapTransaction((response as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> updateTransaction(
    model.Transaction transaction, {
    bool allowOverdraft = false,
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();
    final existing = await getTransactionById(
      transaction.id,
      workspaceIdOverride: workspaceIdOverride,
    );

    await _validateBudgetImpact(
      transaction: transaction,
      previousTransaction: existing,
      allowOverdraft: allowOverdraft,
      workspaceIdOverride: workspaceIdOverride,
    );

    try {
      await _supabase.rpc('update_transaction_rpc', params: {
        'p_transaction_id': transaction.id,
        'p_workspace_id': workspaceId,
        'p_category_id': transaction.categoryId,
        'p_amount_minor': transaction.amountCents,
        'p_currency_code': transaction.currency,
        'p_transaction_type': transaction.type.name,
        'p_transaction_at': transaction.dateTime.toIso8601String(),
        'p_wallet_id': transaction.walletId,
        'p_to_wallet_id': transaction.toWalletId,
        'p_note': transaction.note,
        'p_allow_overdraft_override': allowOverdraft,
        'p_updated_at': transaction.updatedAt.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> deleteTransaction(String id,
      {String? workspaceIdOverride}) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);

    _requireUserId();

    try {
      await _supabase.rpc('soft_delete_transaction_rpc', params: {
        'p_transaction_id': id,
        'p_workspace_id': workspaceId,
      });
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<bool> canCurrentUserManageTransaction(
    String id, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    final userId = _requireUserId();
    final currentRole = await _getCurrentWorkspaceRole(workspaceId);
    if (currentRole == 'owner' || currentRole == 'admin') {
      return true;
    }
    final response = await _supabase
        .from('transactions')
        .select('created_by_user_id')
        .eq('workspace_id', workspaceId)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      return false;
    }

    return response['created_by_user_id'] == userId;
  }

  Future<void> _validateBudgetImpact({
    required model.Transaction transaction,
    model.Transaction? previousTransaction,
    required bool allowOverdraft,
    String? workspaceIdOverride,
  }) async {
    final categoryId = transaction.categoryId;
    if (transaction.type != model.TransactionType.expense ||
        categoryId == null) {
      return;
    }

    final budget = await _getActiveBudget(
      categoryId,
      transaction.dateTime,
      workspaceIdOverride: workspaceIdOverride,
    );
    if (budget == null) {
      return;
    }

    final transactions = await getTransactionsByDateRange(
      budget.periodStart,
      budget.periodEnd,
      workspaceIdOverride: workspaceIdOverride,
    );

    var consumed = transactions
        .where((item) =>
            item.id != previousTransaction?.id &&
            item.categoryId == budget.categoryId &&
            item.type == model.TransactionType.expense)
        .fold<int>(0, (sum, item) => sum + item.amountCents);
    consumed += transaction.amountCents;

    if (consumed > budget.limitCents &&
        !allowOverdraft &&
        !budget.allowOverdraft) {
      final remaining =
          budget.limitCents - (consumed - transaction.amountCents);
      throw BudgetExceededException(
        message:
            'Budget exceeded! Remaining: $remaining cents, Limit: ${budget.limitCents} cents',
        remainingCents: remaining,
        limitCents: budget.limitCents,
      );
    }
  }

  Future<budget_model.Budget?> _getActiveBudget(
    String categoryId,
    DateTime date, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    final response = await _supabase
        .from('budgets')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('category_id', categoryId)
        .isFilter('deleted_at', null)
        .lte('period_start', date.toIso8601String())
        .gte('period_end', date.toIso8601String())
        .order('period_start')
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return budget_model.Budget(
      id: response['id'] as String,
      categoryId: response['category_id'] as String,
      periodType: _parsePeriodType(response['period_type'] as String),
      periodStart: DateTime.parse(response['period_start'] as String),
      periodEnd: DateTime.parse(response['period_end'] as String),
      limitCents: response['limit_minor'] as int,
      consumedCents: 0,
      allowOverdraft: response['allow_overdraft'] as bool? ?? false,
      overdraftCents: 0,
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
      syncStatus: budget_model.SyncStatus.synced,
      deletedAt: response['deleted_at'] != null
          ? DateTime.parse(response['deleted_at'] as String)
          : null,
    );
  }

  budget_model.PeriodType _parsePeriodType(String value) {
    switch (value) {
      case 'yearly':
        return budget_model.PeriodType.yearly;
      case 'custom':
        return budget_model.PeriodType.custom;
      case 'monthly':
      default:
        return budget_model.PeriodType.monthly;
    }
  }

  model.TransactionType _parseTransactionType(String value) {
    switch (value) {
      case 'income':
        return model.TransactionType.income;
      case 'transfer':
        return model.TransactionType.transfer;
      case 'expense':
      default:
        return model.TransactionType.expense;
    }
  }

  model.Transaction _mapTransaction(Map<String, dynamic> item) {
    return model.Transaction(
      id: item['id'] as String,
      amountCents: item['amount_minor'] as int,
      currency: item['currency_code'] as String,
      dateTime: DateTime.parse(item['transaction_at'] as String),
      categoryId: item['category_id'] as String?,
      type: _parseTransactionType(item['transaction_type'] as String),
      walletId: item['wallet_id'] as String?,
      toWalletId: item['to_wallet_id'] as String?,
      note: item['note'] as String?,
      receiptPath: item['receipt_path'] as String?,
      createdAt: DateTime.parse(item['created_at'] as String),
      updatedAt: DateTime.parse(item['updated_at'] as String),
      syncStatus: model.SyncStatus.synced,
      deletedAt: item['deleted_at'] != null
          ? DateTime.parse(item['deleted_at'] as String)
          : null,
    );
  }

  Future<String?> _getCurrentWorkspaceRole(String workspaceId) async {
    final response = await _supabase
        .from('workspace_members')
        .select('role')
        .eq('workspace_id', workspaceId)
        .eq('user_id', _requireUserId())
        .eq('membership_status', 'active')
        .maybeSingle();
    return response?['role'] as String?;
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
