// path: lib/src/ui/screens/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../widgets/budget_progress.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetsWithConsumedProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgets),
        automaticallyImplyLeading: false,
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
      body: budgetsAsync.when(
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noBudgets,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredBudgets.length,
                itemBuilder: (context, index) {
                  final budget = filteredBudgets[index];
                  return _BudgetCard(budget: budget);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Lỗi: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final Budget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryProvider(budget.categoryId));

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
                                child: Text(
                                  category.iconName,
                                  style: const TextStyle(fontSize: 16),
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
                        ? 'Hàng tháng' 
                        : budget.periodType == PeriodType.yearly
                            ? 'Hàng năm'
                            : 'Tùy chỉnh',
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
                      'Còn: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - budget.consumedCents)}',
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
                        const Text(
                          'Đã chi',
                          style: TextStyle(color: Colors.grey),
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
                      'Hạn mức: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Còn: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - budget.consumedCents)}',
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
                      t.dateTime.isAfter(budget.periodStart.subtract(const Duration(days: 1))) &&
                      t.dateTime.isBefore(budget.periodEnd.add(const Duration(days: 1)));
                }).toList();

                if (budgetTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Chưa có giao dịch nào'),
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
                              t.note ?? 'Không có ghi chú',
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
              error: (err, _) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdayMap = {
      1: 'Thứ 2',
      2: 'Thứ 3',
      3: 'Thứ 4',
      4: 'Thứ 5',
      5: 'Thứ 6',
      6: 'Thứ 7',
      7: 'Chủ nhật',
    };
    final weekday = weekdayMap[date.weekday] ?? '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - $weekday';
  }
}

