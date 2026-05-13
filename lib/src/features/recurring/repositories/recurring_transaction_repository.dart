import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_transaction_service.dart';

class RecurringTransactionRepository implements RecurringTransactionsGateway {
  RecurringTransactionRepository(
    this._supabase,
    this._getActiveWorkspaceId,
    this._getCurrentUserId,
  );

  final SupabaseClient _supabase;
  final String? Function() _getActiveWorkspaceId;
  final String? Function() _getCurrentUserId;

  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('recurring_transactions')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('next_occurrence_at');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(RecurringTransaction.fromJson)
        .toList();
  }

  Future<RecurringTransaction?> getRecurringTransactionById(String id) async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('recurring_transactions')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return RecurringTransaction.fromJson(response);
  }

  @override
  Future<RecurringTransaction> createRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    _requireWorkspaceId();
    _requireUserId();
    try {
      final response = await _supabase.rpc(
        'create_recurring_transaction_rpc',
        params: _rpcParams(transaction),
      );
      return RecurringTransaction.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  @override
  Future<void> updateRecurringTransaction(
      RecurringTransaction transaction) async {
    _requireWorkspaceId();
    _requireUserId();
    try {
      await _supabase.rpc(
        'update_recurring_transaction_rpc',
        params: _rpcParams(transaction),
      );
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final workspaceId = _requireWorkspaceId();
    _requireUserId();
    try {
      await _supabase.rpc(
        'soft_delete_recurring_transaction_rpc',
        params: {
          'p_recurring_transaction_id': id,
          'p_workspace_id': workspaceId,
        },
      );
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<List<RecurringOccurrence>> getUpcomingOccurrences({
    DateTime? from,
    DateTime? to,
  }) async {
    final workspaceId = _requireWorkspaceId();
    final start = from ?? DateTime.now();
    final end = to ?? start.add(const Duration(days: 30));

    final response = await _supabase
        .from('recurring_transaction_occurrences')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', RecurringOccurrenceStatus.pending.name)
        .gte('scheduled_for', start.toIso8601String())
        .lte('scheduled_for', end.toIso8601String())
        .order('scheduled_for');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(RecurringOccurrence.fromJson)
        .toList();
  }

  @override
  Future<void> generateOccurrences({required DateTime throughDate}) async {
    final workspaceId = _requireWorkspaceId();
    _requireUserId();
    try {
      await _supabase.rpc(
        'generate_recurring_occurrences_rpc',
        params: {
          'p_workspace_id': workspaceId,
          'p_through_date': throughDate.toIso8601String(),
        },
      );
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  @override
  Future<void> skipOccurrence(String occurrenceId) async {
    final workspaceId = _requireWorkspaceId();
    _requireUserId();
    try {
      await _supabase.rpc(
        'skip_recurring_occurrence_rpc',
        params: {
          'p_occurrence_id': occurrenceId,
          'p_workspace_id': workspaceId,
        },
      );
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  @override
  Future<void> completeOccurrence({
    required String occurrenceId,
    required String generatedTransactionId,
  }) async {
    final workspaceId = _requireWorkspaceId();
    _requireUserId();
    try {
      await _supabase.rpc(
        'complete_recurring_occurrence_rpc',
        params: {
          'p_occurrence_id': occurrenceId,
          'p_workspace_id': workspaceId,
          'p_generated_transaction_id': generatedTransactionId,
        },
      );
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
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

  Map<String, dynamic> _rpcParams(RecurringTransaction transaction) {
    return {
      'id': transaction.id.isEmpty ? null : transaction.id,
      'workspace_id': transaction.workspaceId,
      'title': transaction.title,
      'category_id': transaction.categoryId,
      'amount_minor': transaction.amountCents,
      'currency_code': transaction.currency,
      'transaction_type': transaction.type.name,
      'frequency': transaction.frequency.name,
      'mode': transaction.mode.name,
      'interval_count': transaction.intervalCount,
      'start_date': transaction.startDate.toIso8601String(),
      'next_occurrence_at': transaction.nextOccurrenceAt.toIso8601String(),
      'reminder_days_before': transaction.reminderDaysBefore,
      'is_active': transaction.isActive,
      'created_by_user_id': transaction.createdByUserId,
      'updated_by_user_id': transaction.updatedByUserId,
      'created_at': transaction.createdAt.toIso8601String(),
      'updated_at': transaction.updatedAt.toIso8601String(),
      'note': transaction.note,
      'day_of_month': transaction.dayOfMonth,
      'day_of_week': transaction.dayOfWeek,
      'month_of_year': transaction.monthOfYear,
      'end_date': transaction.endDate?.toIso8601String(),
    };
  }
}
