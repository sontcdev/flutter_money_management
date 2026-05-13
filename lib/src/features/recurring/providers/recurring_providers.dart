import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/repositories/recurring_transaction_repository.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_reminder_service.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_transaction_service.dart';
import 'package:flutter_money_management/src/features/budgets/providers/budget_providers.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/shared/providers/app_service_providers.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RecurringTransactionRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final recurringTransactionsProvider =
    FutureProvider<List<RecurringTransaction>>((ref) async {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return repository.getAllRecurringTransactions();
});

final recurringTransactionProvider =
    FutureProvider.family<RecurringTransaction?, String>((ref, id) async {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return repository.getRecurringTransactionById(id);
});

final upcomingRecurringOccurrencesProvider =
    FutureProvider<List<RecurringOccurrence>>((ref) async {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  await repository.generateOccurrences(
    throughDate: DateTime.now().add(const Duration(days: 30)),
  );
  return repository.getUpcomingOccurrences();
});

final recurringTransactionServiceProvider =
    Provider<RecurringTransactionService>((ref) {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return RecurringTransactionService(
    repository,
    transactionRepository,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final recurringActionsProvider =
    StateNotifierProvider<RecurringActionsNotifier, AsyncValue<void>>((ref) {
  return RecurringActionsNotifier(ref);
});

final recurringReminderServiceProvider =
    Provider<RecurringReminderService>((ref) {
  final plugin = ref.watch(localNotificationsPluginProvider);
  return RecurringReminderService(FlutterLocalNotificationsGateway(plugin));
});

final recurringNotificationsPermissionProvider =
    FutureProvider<bool>((ref) async {
  final service = ref.watch(recurringReminderServiceProvider);
  return service.areNotificationsAllowed();
});

class RecurringActionsNotifier extends StateNotifier<AsyncValue<void>> {
  RecurringActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> refreshRecurringData() async {
    _ref.invalidate(recurringTransactionsProvider);
    _ref.invalidate(upcomingRecurringOccurrencesProvider);
    await syncRecurringReminders();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(recurringTransactionRepositoryProvider)
          .deleteRecurringTransaction(id);
      await refreshRecurringData();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> skipOccurrence(String occurrenceId) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(recurringTransactionServiceProvider)
          .skipOccurrence(occurrenceId);
      await refreshRecurringData();
      _invalidateDependents();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> confirmOccurrence({
    required RecurringOccurrence occurrence,
    required RecurringTransaction recurringTransaction,
    bool allowOverdraft = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(recurringTransactionServiceProvider).confirmOccurrence(
            occurrence: occurrence,
            recurringTransaction: recurringTransaction,
            allowOverdraft: allowOverdraft,
          );
      await refreshRecurringData();
      _invalidateDependents();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  void _invalidateDependents() {
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(budgetsProvider);
    _ref.invalidate(budgetsWithConsumedProvider);
    final selectedMonth = _ref.read(selectedMonthProvider);
    _ref.invalidate(calendarDataProvider(selectedMonth));
    _ref.invalidate(monthlySummaryProvider(selectedMonth));
    _ref.invalidate(transactionGroupsProvider(selectedMonth));
  }

  Future<void> syncRecurringReminders() async {
    final recurringTransactions =
        await _ref.read(recurringTransactionsProvider.future);
    final occurrences =
        await _ref.read(upcomingRecurringOccurrencesProvider.future);
    final recurringById = {
      for (final recurring in recurringTransactions) recurring.id: recurring,
    };
    await _ref
        .read(recurringReminderServiceProvider)
        .syncPendingRecurringReminders(
          occurrences: occurrences,
          recurringById: recurringById,
        );
  }

  Future<bool> requestNotificationPermission() async {
    state = const AsyncValue.loading();
    try {
      final granted =
          await _ref.read(recurringReminderServiceProvider).requestPermission();
      _ref.invalidate(recurringNotificationsPermissionProvider);
      state = const AsyncValue.data(null);
      return granted;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
