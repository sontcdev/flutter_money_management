import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/home/providers/home_tab_provider.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_invite_notification_section.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_switcher.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_avatar.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
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
    final upcomingRecurringAsync =
        ref.watch(upcomingRecurringOccurrencesProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final currentUser = ref.watch(currentUserProvider);
    final displayName =
        (currentUser?.userMetadata?['display_name'] as String?) ??
            currentUser?.email ??
            '?';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildGreeting(context, ref, l10n),
        actions: [
          const WorkspaceSwitcher(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenPadding),
            child: AppAvatar(
              name: displayName,
              size: 36,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await syncCurrentWorkspaceData(ref);
        },
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkspaceInviteNotificationSection(),
                    _buildFirstRunEmptyState(context, l10n),
                  ],
                ),
              );
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

                  const WorkspaceInviteNotificationSection(),

                  const SizedBox(height: AppSpacing.sectionGap),

                  _buildRecurringSection(context, l10n, upcomingRecurringAsync),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Attention Section
                  _buildAttentionSection(context, ref, l10n, transactions,
                      budgetsAsync, monthStartDay),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Monthly Budget Progress
                  _buildBudgetProgressSection(context, ref, l10n, budgetsAsync),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Recent Activity
                  _buildRecentActivity(context, ref, l10n, transactions),

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

  Widget _buildGreeting(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 18
            ? l10n.goodAfternoon
            : l10n.goodEvening;
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.userMetadata?['display_name'] as String?;

    return Text(
      displayName != null && displayName.isNotEmpty
          ? '$greeting, $displayName'
          : greeting,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBudgetProgressSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue budgetsAsync,
  ) {
    if (budgetsAsync is! AsyncData) {
      return const SizedBox.shrink();
    }

    final budgets = (budgetsAsync.value as List<Budget>)
        .where((b) => b.deletedAt == null)
        .toList();

    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final Map<String, Category> categoryById = {
          for (final c in categories) c.id: c,
        };

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: l10n.budgetProgress,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
              ...budgets.take(3).map((budget) {
                final category = categoryById[budget.categoryId];
                final progress = budget.progressPercentage.clamp(0.0, 1.0);
                final tone = budget.isExceeded
                    ? MetricCardTone.danger
                    : progress >= 0.8
                        ? MetricCardTone.warning
                        : MetricCardTone.neutral;
                final barColor = tone == MetricCardTone.danger
                    ? AppColors.expense
                    : tone == MetricCardTone.warning
                        ? AppColors.warning
                        : Theme.of(context).colorScheme.primary;
                final tint = category != null
                    ? getCategoryColor(category.colorValue)
                    : barColor;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: tint.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              alignment: Alignment.center,
                              child: category != null
                                  ? CategoryIconWidget(
                                      iconName: category.iconName,
                                      size: 18,
                                      color: tint,
                                    )
                                  : Icon(Icons.category_outlined,
                                      size: 18, color: tint),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                category?.name ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: barColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${CurrencyFormatter.formatVNDFromCents(budget.consumedCents, locale: l10n.localeName)} / '
                          '${CurrencyFormatter.formatVNDFromCents(budget.limitCents, locale: l10n.localeName)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.3),
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecurringSection(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue upcomingRecurringAsync,
  ) {
    return upcomingRecurringAsync.when(
      data: (occurrences) {
        if (occurrences.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: l10n.recurringUpcoming,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
              AppMetricCard.status(
                label: l10n.recurringTransactions,
                value:
                    '${occurrences.length} ${l10n.notification.toLowerCase()}',
                icon: Icons.schedule,
                tone: MetricCardTone.warning,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
      final budgets = budgetsAsync.value as List<Budget>;
      final exceededCount =
          budgets.where((b) => b.consumedCents > b.limitCents).length;
      final nearLimitCount = budgets.where((b) {
        final percentage =
            b.limitCents > 0 ? (b.consumedCents / b.limitCents) : 0.0;
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

    // Gradient tone follows the same status logic as before, but now the
    // whole card is a single brand-gradient surface (matches mockup `.hero`).
    final List<Color> gradientColors = switch (tone) {
      MetricCardTone.danger => [AppColors.error, AppColors.expenseContainerDark],
      MetricCardTone.warning => [AppColors.warning, AppColors.primaryStrong],
      _ => [AppColors.primaryStrong, AppColors.primary],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CycleUtils.getCycleLabel(cycleRange.start, cycleRange.end),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              CurrencyFormatter.formatVNDFromCents(balance,
                  locale: l10n.localeName),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildHeroMiniStat(
                    context,
                    icon: Icons.arrow_downward,
                    label: l10n.income,
                    value: CurrencyFormatter.formatVNDFromCents(totalIncome,
                        locale: l10n.localeName),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildHeroMiniStat(
                    context,
                    icon: Icons.arrow_upward,
                    label: l10n.expense,
                    value: CurrencyFormatter.formatVNDFromCents(totalExpense,
                        locale: l10n.localeName),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMiniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.iconSizeSm, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(
    BuildContext context,
    WidgetRef ref,
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
      final budgets = budgetsAsync.value as List<Budget>;
      final exceededBudgets =
          budgets.where((b) => b.consumedCents > b.limitCents).toList();
      final nearLimitBudgets = budgets.where((b) {
        final percentage =
            b.limitCents > 0 ? (b.consumedCents / b.limitCents) : 0.0;
        return percentage >= 0.8 && percentage < 1.0;
      }).toList();

      if (exceededBudgets.isNotEmpty) {
        attentionCards.add(
          AppMetricCard.status(
            label: l10n.budgets,
            value: '${exceededBudgets.length} ${l10n.exceeded.toLowerCase()}',
            icon: Icons.warning_amber_rounded,
            tone: MetricCardTone.danger,
            onTap: () =>
                ref.read(currentTabProvider.notifier).state = AppTab.plan,
          ),
        );
      } else if (nearLimitBudgets.isNotEmpty) {
        attentionCards.add(
          AppMetricCard.status(
            label: l10n.budgets,
            value: '${nearLimitBudgets.length} ${l10n.nearLimit.toLowerCase()}',
            icon: Icons.warning_outlined,
            tone: MetricCardTone.warning,
            onTap: () =>
                ref.read(currentTabProvider.notifier).state = AppTab.plan,
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
    WidgetRef ref,
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
              onPressed: () =>
                  ref.read(currentTabProvider.notifier).state = AppTab.activity,
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
