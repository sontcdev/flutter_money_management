import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_switcher.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_metric_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_section_header.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsWithConsumedProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        automaticallyImplyLeading: false,
        actions: const [
          WorkspaceSwitcher(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await syncCurrentWorkspaceData(ref);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Summary Section
              _buildHeroSummary(
                  context, l10n, transactionsAsync, monthStartDay),

              const SizedBox(height: AppSpacing.sectionGap),

              // Quick Actions
              _buildQuickActions(context, l10n),

              const SizedBox(height: AppSpacing.sectionGap),

              // Budget Snapshot
              _buildBudgetSnapshot(context, l10n, budgetsAsync),

              const SizedBox(height: AppSpacing.sectionGap),

              // Recent Transactions
              _buildRecentTransactions(context, l10n, transactionsAsync),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSummary(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<model.Transaction>> transactionsAsync,
    int monthStartDay,
  ) {
    return transactionsAsync.when(
      data: (transactions) {
        final now = DateTime.now();
        final cycleRange = CycleUtils.getCycleRangeForMonth(now, monthStartDay);

        // Filter transactions for current cycle
        final cycleTransactions = transactions.where((t) {
          return t.dateTime.isAfter(
                  cycleRange.start.subtract(const Duration(seconds: 1))) &&
              t.dateTime
                  .isBefore(cycleRange.end.add(const Duration(seconds: 1)));
        }).toList();

        final totalIncome = cycleTransactions
            .where((t) => t.type == model.TransactionType.income)
            .fold<int>(0, (sum, t) => sum + t.amountCents);

        final totalExpense = cycleTransactions
            .where((t) => t.type == model.TransactionType.expense)
            .fold<int>(0, (sum, t) => sum + t.amountCents);

        final balance = totalIncome - totalExpense;

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              // Balance Card
              AppMetricCard(
                label: l10n.balance,
                value: CurrencyFormatter.formatVNDFromCents(balance,
                    locale: l10n.localeName),
                icon: balance >= 0 ? Icons.trending_up : Icons.trending_down,
                color: balance >= 0 ? AppColors.income : AppColors.expense,
                subtitle:
                    CycleUtils.getCycleLabel(cycleRange.start, cycleRange.end),
              ),
              const SizedBox(height: AppSpacing.md),
              // Income & Expense Row
              Row(
                children: [
                  Expanded(
                    child: AppMetricCard(
                      label: l10n.income,
                      value: CurrencyFormatter.formatVNDFromCents(totalIncome,
                          locale: l10n.localeName),
                      icon: Icons.arrow_downward,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppMetricCard(
                      label: l10n.expense,
                      value: CurrencyFormatter.formatVNDFromCents(totalExpense,
                          locale: l10n.localeName),
                      icon: Icons.arrow_upward,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(l10n.errorWithMessage('$error')),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        AppSectionHeader(
          title: l10n.quickActions,
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_circle,
                  label: l10n.addExpense,
                  color: AppColors.expense,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/add-transaction',
                      arguments: {'type': model.TransactionType.expense},
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_circle,
                  label: l10n.addIncome,
                  color: AppColors.income,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/add-transaction',
                      arguments: {'type': model.TransactionType.income},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.calendar_month,
                  label: l10n.calendar,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    // Will be handled by bottom nav
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.bar_chart,
                  label: l10n.reports,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    // Will be handled by bottom nav
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSnapshot(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<dynamic>> budgetsAsync,
  ) {
    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.noBudgets,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.createFirstBudget,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/budget-edit');
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addBudget),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show top 3 budgets - budgets already have category info from budgetsWithConsumedProvider
        final topBudgets = budgets.take(3).toList();

        return Column(
          children: [
            AppSectionHeader(
              title: l10n.budgets,
              trailing: TextButton(
                onPressed: () {
                  // Will navigate to budgets tab
                },
                child: Text(l10n.viewAll),
              ),
            ),
            // Budgets are simplified for dashboard - just show basic info
            ...topBudgets.map((budget) {
              final consumed = budget.consumedCents;
              final limit = budget.limitCents;
              final percentage =
                  limit > 0 ? (consumed / limit * 100).clamp(0, 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.xs,
                ),
                child: Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/budget-detail',
                        arguments: budget.id,
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.budget,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: percentage > 90
                                      ? AppColors.expense
                                      : AppColors.income,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            color: percentage > 90
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                CurrencyFormatter.formatVNDFromCents(
                                  consumed,
                                  locale: l10n.localeName,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                CurrencyFormatter.formatVNDFromCents(
                                  limit,
                                  locale: l10n.localeName,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<model.Transaction>> transactionsAsync,
  ) {
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.noTransactions,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.startTracking,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final recentTransactions = transactions.take(5).toList();

        return Column(
          children: [
            AppSectionHeader(
              title: l10n.recentTransactions,
              trailing: TextButton(
                onPressed: () {
                  // Will navigate to transactions tab
                },
                child: Text(l10n.viewAll),
              ),
            ),
            ...recentTransactions.map((transaction) {
              return _RecentTransactionItem(
                transaction: transaction,
                key: ValueKey(transaction.id),
              );
            }),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(l10n.errorWithMessage('$error')),
      ),
    );
  }
}

/// Recent transaction item with category lookup
class _RecentTransactionItem extends ConsumerWidget {
  final model.Transaction transaction;

  const _RecentTransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoryAsync = ref.watch(categoryProvider(transaction.categoryId));

    return categoryAsync.when(
      data: (category) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: TransactionItem(
            transaction: transaction,
            categoryName: category?.name ?? l10n.unknown,
            categoryIconName: category?.iconName,
            categoryColor:
                category != null ? getCategoryColor(category.colorValue) : null,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/transaction-detail',
                arguments: transaction.id,
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppSpacing.iconSizeLg,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
