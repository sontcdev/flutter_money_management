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
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_metric_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_section_header.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';

/// Daily home screen for new users - action-first, not analytics-first
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsWithConsumedProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.today),
        automaticallyImplyLeading: false,
        actions: const [
          WorkspaceSwitcher(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await syncCurrentWorkspaceData(ref);
        },
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return _buildFirstRunEmptyState(context, l10n);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Summary
                  _buildHeroSummary(
                      context, l10n, transactions, budgetsAsync, monthStartDay),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Quick Actions
                  _buildQuickActions(context, l10n),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Attention Section
                  _buildAttentionSection(
                      context, l10n, transactions, budgetsAsync, monthStartDay),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Recent Activity
                  _buildRecentActivity(context, l10n, transactions),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Text(l10n.errorWithMessage('$error')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstRunEmptyState(BuildContext context, AppLocalizations l10n) {
    return EmptyState.firstRun(
      icon: Icons.account_balance_wallet_outlined,
      title: l10n.startTracking,
      message: l10n.onboardingSubtitle,
      actionLabel: l10n.addTransaction,
      onAction: () {
        Navigator.pushNamed(context, '/add-transaction');
      },
    );
  }

  Widget _buildHeroSummary(
    BuildContext context,
    AppLocalizations l10n,
    List<model.Transaction> transactions,
    AsyncValue budgetsAsync,
    int monthStartDay,
  ) {
    final now = DateTime.now();
    final cycleRange = CycleUtils.getCycleRangeForMonth(now, monthStartDay);

    // Filter transactions for current cycle
    final cycleTransactions = transactions.where((t) {
      return t.dateTime
              .isAfter(cycleRange.start.subtract(const Duration(seconds: 1))) &&
          t.dateTime.isBefore(cycleRange.end.add(const Duration(seconds: 1)));
    }).toList();

    final totalIncome = cycleTransactions
        .where((t) => t.type == model.TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    final totalExpense = cycleTransactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    final balance = totalIncome - totalExpense;

    // Determine tone based on budget status
    MetricCardTone tone = MetricCardTone.neutral;
    if (budgetsAsync is AsyncData) {
      final budgets = budgetsAsync.value as List;
      final exceededCount =
          budgets.where((b) => b.consumed > b.limitCents).length;
      final nearLimitCount = budgets.where((b) {
        final percentage = b.limitCents > 0 ? (b.consumed / b.limitCents) : 0.0;
        return percentage >= 0.8 && percentage < 1.0;
      }).length;

      if (exceededCount > 0) {
        tone = MetricCardTone.danger;
      } else if (nearLimitCount > 0) {
        tone = MetricCardTone.warning;
      } else if (balance >= 0) {
        tone = MetricCardTone.positive;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: [
          // Hero Balance Card
          AppMetricCard.hero(
            label: l10n.balance,
            value: CurrencyFormatter.formatVNDFromCents(balance,
                locale: l10n.localeName),
            icon: balance >= 0 ? Icons.trending_up : Icons.trending_down,
            subtitle:
                CycleUtils.getCycleLabel(cycleRange.start, cycleRange.end),
            tone: tone,
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
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: l10n.quickActions,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: l10n.addTransaction,
            icon: Icons.add_circle_outline,
            onPressed: () {
              Navigator.pushNamed(context, '/add-transaction');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(
    BuildContext context,
    AppLocalizations l10n,
    List<model.Transaction> transactions,
    AsyncValue budgetsAsync,
    int monthStartDay,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTransactions = transactions.where((t) {
      final txDate =
          DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
      return txDate.isAtSameMomentAs(today);
    }).toList();

    final List<Widget> attentionCards = [];

    // No transaction logged today
    if (todayTransactions.isEmpty) {
      attentionCards.add(
        AppMetricCard.status(
          label: l10n.today,
          value: l10n.noTransactions,
          icon: Icons.info_outline,
          tone: MetricCardTone.neutral,
        ),
      );
    }

    // Budget warnings
    if (budgetsAsync is AsyncData) {
      final budgets = budgetsAsync.value as List;
      final exceededBudgets =
          budgets.where((b) => b.consumed > b.limitCents).toList();
      final nearLimitBudgets = budgets.where((b) {
        final percentage = b.limitCents > 0 ? (b.consumed / b.limitCents) : 0.0;
        return percentage >= 0.8 && percentage < 1.0;
      }).toList();

      if (exceededBudgets.isNotEmpty) {
        attentionCards.add(
          AppMetricCard.status(
            label: l10n.budgets,
            value: '${exceededBudgets.length} ${l10n.exceeded.toLowerCase()}',
            icon: Icons.warning_amber_rounded,
            tone: MetricCardTone.danger,
            onTap: () {
              // Navigate to budgets tab
              // This will be handled by parent HomeScreen
            },
          ),
        );
      } else if (nearLimitBudgets.isNotEmpty) {
        attentionCards.add(
          AppMetricCard.status(
            label: l10n.budgets,
            value: '${nearLimitBudgets.length} ${l10n.nearLimit.toLowerCase()}',
            icon: Icons.warning_outlined,
            tone: MetricCardTone.warning,
            onTap: () {
              // Navigate to budgets tab
            },
          ),
        );
      }
    }

    if (attentionCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: l10n.notification,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          ...attentionCards.map((card) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: card,
              )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    AppLocalizations l10n,
    List<model.Transaction> transactions,
  ) {
    final recentTransactions = transactions.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: l10n.recentTransactions,
            padding: EdgeInsets.zero,
            trailing: TextButton(
              onPressed: () {
                // Navigate to Activity tab
                // This will be handled by parent HomeScreen
              },
              child: Text(l10n.viewAll),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...recentTransactions.map((transaction) {
            return Consumer(
              builder: (context, ref, _) {
                final categoriesAsync = ref.watch(categoriesProvider);

                return categoriesAsync.when(
                  data: (categories) {
                    final category = categories.firstWhere(
                      (c) => c.id == transaction.categoryId,
                      orElse: () => categories.first,
                    );

                    return TransactionItem.compact(
                      transaction: transaction,
                      categoryName: category.name,
                      categoryIconName: category.iconName,
                      categoryColor: getCategoryColor(category.colorValue),
                      showChevron: true,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/transaction-detail',
                          arguments: transaction.id,
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
