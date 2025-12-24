// path: lib/src/ui/screens/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../widgets/budget_progress.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/category_icon_widget.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../utils/cycle_utils.dart';
import 'settings_screen.dart';

class BudgetsScreen extends ConsumerWidget {
  final bool showBackButton;
  
  const BudgetsScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetsWithConsumedProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgets),
        automaticallyImplyLeading: showBackButton,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/budget-edit');
              if (result == true) {
                ref.invalidate(budgetsProvider);
                ref.invalidate(budgetsWithConsumedProvider);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetsProvider);
          ref.invalidate(budgetsWithConsumedProvider);
          ref.invalidate(categoriesProvider);
          // Wait a bit for the providers to refresh
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: budgetsAsync.when(
        data: (budgets) {
          return categoriesAsync.when(
            data: (categories) {
              // Create a map for quick category lookup
              final categoryMap = {for (var c in categories) c.id: c};
              
              // Filter budgets to show only expense budgets
              final filteredBudgets = budgets.where((b) {
                final cat = categoryMap[b.categoryId];
                return cat?.type == CategoryType.expense;
              }).toList();

              if (filteredBudgets.isEmpty) {
                return EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.noBudgets,
                  message: 'Create your first budget to track your spending',
                  actionLabel: 'Add Budget',
                  onAction: () async {
                    final result = await Navigator.pushNamed(context, '/budget-edit');
                    if (result == true) {
                      ref.invalidate(budgetsProvider);
                      ref.invalidate(budgetsWithConsumedProvider);
                    }
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredBudgets.length,
                itemBuilder: (context, index) {
                  final budget = filteredBudgets[index];
                  return _SwipeableBudgetCard(
                    budget: budget,
                    onDeleted: () {
                      ref.invalidate(budgetsProvider);
                      ref.invalidate(budgetsWithConsumedProvider);
                    },
                  );
                },
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const ShimmerCard(),
            ),
            error: (error, stack) => Center(child: Text('Lỗi: $error')),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (context, index) => const ShimmerCard(),
        ),
        error: (error, stack) => Center(
          child: Text('Lỗi: $error'),
        ),
        ),
      ),
    );
  }
}


class _SwipeableBudgetCard extends ConsumerWidget {
  final Budget budget;
  final VoidCallback onDeleted;

  const _SwipeableBudgetCard({
    required this.budget,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoryAsync = ref.watch(categoryProvider(budget.categoryId));
    
    return Slidable(
      key: Key('budget_${budget.id}'),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25, // Only takes 25% of the width
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirmed = await _showDeleteConfirmDialog(context, l10n, categoryAsync);
              if (confirmed) {
                await _deleteBudget(ref, l10n, context);
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: l10n.delete,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: _BudgetCard(budget: budget),
    );
  }

  Future<bool> _showDeleteConfirmDialog(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<Category?> categoryAsync,
  ) async {
    final categoryName = categoryAsync.maybeWhen(
      data: (category) => category?.name ?? 'Unknown',
      orElse: () => 'Unknown',
    );

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.notification),
          content: Text(
            l10n.confirmDeleteBudget(categoryName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _deleteBudget(WidgetRef ref, AppLocalizations l10n, BuildContext context) async {
    try {
      final repository = ref.read(budgetRepositoryProvider);
      await repository.deleteBudget(budget.id);
      onDeleted();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.budgetDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }
}

class _BudgetCard extends ConsumerWidget {
  final Budget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryProvider(budget.categoryId));
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBudgetTransactions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: categoryAsync.when(
                      data: (category) => Row(
                        children: [
                          if (category != null)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(category.colorValue).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CategoryIconWidget(
                                  iconName: category.iconName,
                                  size: 16,
                                  color: Color(category.colorValue),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category?.name ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('Unknown'),
                    ),
                  ),
                  Text(
                    budget.periodType == PeriodType.monthly 
                        ? l10n.monthly
                        : budget.periodType == PeriodType.yearly
                            ? l10n.yearly
                            : l10n.custom,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/budget-edit',
                        arguments: budget,
                      );
                      if (result == true) {
                        ref.invalidate(budgetsProvider);
                        ref.invalidate(budgetsWithConsumedProvider);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              categoryAsync.when(
                data: (category) => BudgetProgress(
                  budget: budget,
                  categoryName: category?.name ?? 'Unknown',
                  currency: 'VND',
                ),
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => BudgetProgress(
                  budget: budget,
                  categoryName: 'Unknown',
                  currency: 'VND',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${CurrencyFormatter.formatVNDFromCents(budget.consumedCents)} / ${CurrencyFormatter.formatVNDFromCents(budget.limitCents)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${l10n.remaining}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - budget.consumedCents)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: budget.consumedCents > budget.limitCents
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetTransactions(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.read(categoryProvider(budget.categoryId));
    final categoryName = categoryAsync.maybeWhen(
      data: (category) => category?.name ?? 'Unknown',
      orElse: () => 'Unknown',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetTransactionsDetailScreen(
          budget: budget,
          categoryName: categoryName,
        ),
      ),
    );
  }
}

// Budget Transactions Detail Screen
class BudgetTransactionsDetailScreen extends ConsumerWidget {
  final Budget budget;
  final String categoryName;

  const BudgetTransactionsDetailScreen({
    super.key,
    required this.budget,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final l10n = AppLocalizations.of(context)!;
    final monthStartDay = ref.watch(monthStartDayProvider);
    
    // Calculate period based on monthStartDay for monthly budgets
    late final DateTime periodStart;
    late final DateTime periodEnd;
    
    if (budget.periodType == PeriodType.monthly) {
      // Use cycle range from monthStartDay setting
      final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
      periodStart = cycleRange.start;
      periodEnd = cycleRange.end;
    } else {
      // Use budget's stored period for yearly/custom
      periodStart = budget.periodStart;
      periodEnd = budget.periodEnd;
    }
    
    final percentage = budget.limitCents > 0
        ? (budget.consumedCents / budget.limitCents * 100)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/budget-edit',
                arguments: budget,
              );
              if (result == true) {
                ref.invalidate(budgetsProvider);
                ref.invalidate(budgetsWithConsumedProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Budget summary card
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.spent,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          CurrencyFormatter.formatVNDFromCents(budget.consumedCents),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: percentage > 100
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: percentage > 100 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      percentage > 100 ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.limit}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${l10n.remaining}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - budget.consumedCents)}',
                      style: TextStyle(
                        color: budget.consumedCents > budget.limitCents
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // Filter transactions by category and budget period
                final budgetTransactions = transactions.where((t) {
                  return t.categoryId == budget.categoryId &&
                      t.type == TransactionType.expense &&
                      t.dateTime.isAfter(periodStart.subtract(const Duration(days: 1))) &&
                      t.dateTime.isBefore(periodEnd.add(const Duration(days: 1)));
                }).toList();

                if (budgetTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(l10n.noTransactions),
                      ],
                    ),
                  );
                }

                // Group by date
                final Map<DateTime, List<Transaction>> groupedByDate = {};
                for (final t in budgetTransactions) {
                  final date = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
                  if (!groupedByDate.containsKey(date)) {
                    groupedByDate[date] = [];
                  }
                  groupedByDate[date]!.add(t);
                }

                final sortedDates = groupedByDate.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final dayTransactions = groupedByDate[date]!;
                    final dayTotal = dayTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header with distinct color
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(date),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${CurrencyFormatter.formatVNDFromCents(dayTotal)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Transactions - amounts in black
                          ...dayTransactions.map((t) => ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.expense.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shopping_cart,
                                color: AppColors.expense,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              t.note ?? l10n.noNote,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              '${t.dateTime.hour.toString().padLeft(2, '0')}:${t.dateTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Text(
                              '-${CurrencyFormatter.formatVNDFromCents(t.amountCents)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/transaction-detail',
                                arguments: t.id,
                              );
                            },
                          )),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('${l10n.error}: $err')),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdayNames = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    final weekday = weekdayNames[date.weekday % 7];
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - $weekday';
  }
}

