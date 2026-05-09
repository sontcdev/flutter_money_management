import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/budgets/repositories/budget_repository.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BudgetRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getAllBudgets();
});

final budgetsWithConsumedProvider = FutureProvider<List<Budget>>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  final monthStartDay = ref.watch(monthStartDayProvider);

  return budgets.map((budget) {
    late final DateTime periodStart;
    late final DateTime periodEnd;

    if (budget.periodType == PeriodType.monthly) {
      final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
      periodStart = cycleRange.start;
      periodEnd = cycleRange.end;
    } else {
      periodStart = budget.periodStart;
      periodEnd = budget.periodEnd;
    }

    final consumedCents = transactions
        .where((transaction) =>
            transaction.categoryId == budget.categoryId &&
            transaction.type == TransactionType.expense &&
            transaction.dateTime
                .isAfter(periodStart.subtract(const Duration(seconds: 1))) &&
            transaction.dateTime
                .isBefore(periodEnd.add(const Duration(seconds: 1))))
        .fold<int>(0, (sum, transaction) => sum + transaction.amountCents);

    return budget.copyWith(consumedCents: consumedCents);
  }).toList();
});
