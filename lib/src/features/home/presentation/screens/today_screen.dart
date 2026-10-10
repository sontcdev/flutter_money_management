import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/uncategorized_category.dart';
import 'package:flutter_money_management/src/features/home/providers/home_tab_provider.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_invite_notification_section.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_switcher.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_avatar.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_metric_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_section_header.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';
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

                  const _WalletBalanceStrip(),

                  const SizedBox(height: AppSpacing.sectionGap),

                  const WorkspaceInviteNotificationSection(),

                  const SizedBox(height: AppSpacing.sectionGap),

                  _buildRecurringSection(
                      context, ref, l10n, upcomingRecurringAsync),

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
          error: (_, __) => LoadErrorState(
            title: l10n.dataLoadFailed,
            message: l10n.dataLoadFailedHint,
            retryLabel: l10n.retry,
            onRetry: () => syncCurrentWorkspaceData(ref),
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
      return budgetsAsync.hasError
          ? InlineLoadErrorState(
              onRetry: () => ref.invalidate(budgetsWithConsumedProvider),
            )
          : const SectionSkeleton();
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
                final progress =
                    (budget.progressPercentage / 100).clamp(0.0, 1.0);
                final tone = budget.isExceeded
                    ? MetricCardTone.danger
                    : progress >= 0.8
                        ? MetricCardTone.warning
                        : MetricCardTone.neutral;
                final barColor = tone == MetricCardTone.danger
                    ? context.semanticColors.expense
                    : tone == MetricCardTone.warning
                        ? context.semanticColors.warning
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
                                    BorderRadius.circular(AppSpacing.radiusCard),
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
                              '${budget.progressPercentage.toStringAsFixed(0)}%',
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
      loading: () => const SectionSkeleton(),
      error: (_, __) => InlineLoadErrorState(
        onRetry: () => ref.invalidate(categoriesProvider),
      ),
    );
  }

  Widget _buildRecurringSection(
    BuildContext context,
    WidgetRef ref,
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
                value: l10n.upcomingCount(occurrences.length),
                icon: Icons.schedule,
                tone: MetricCardTone.warning,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/recurring-transactions');
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SectionSkeleton(),
      error: (_, __) => InlineLoadErrorState(
        onRetry: () => ref.invalidate(upcomingRecurringOccurrencesProvider),
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
    final heroPalette = _heroPalette(context, tone);
    final gradientColors = heroPalette.gradient;
    final foreground = heroPalette.foreground;

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
          borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CycleUtils.getCycleLabel(cycleRange.start, cycleRange.end),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              CurrencyFormatter.formatVNDFromCents(balance,
                  locale: l10n.localeName),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildHeroMiniStat(
                    context,
                    foreground: foreground,
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
                    foreground: foreground,
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
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.iconSizeSm, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  ({List<Color> gradient, Color foreground}) _heroPalette(
    BuildContext context,
    MetricCardTone tone,
  ) {
    final theme = Theme.of(context);
    final base = switch (tone) {
      MetricCardTone.danger => theme.colorScheme.error,
      MetricCardTone.warning => context.semanticColors.warning,
      _ => theme.colorScheme.primary,
    };
    final isDark = theme.brightness == Brightness.dark;
    var foreground = isDark ? AppColors.textDark : AppColors.textLight;
    var away = isDark ? AppColors.textLight : AppColors.textDark;
    var shift = _heroContrastShift(base, foreground, away);
    if (shift > 0.35) {
      (foreground, away) = (away, foreground);
      shift = _heroContrastShift(base, foreground, away);
    }
    return (
      gradient: [
        Color.lerp(base, away, (shift + 0.2).clamp(0.0, 1.0))!,
        Color.lerp(base, away, shift)!,
      ],
      foreground: foreground,
    );
  }

  double _heroContrastShift(Color base, Color foreground, Color away) {
    for (var step = 0; step <= 20; step++) {
      final shift = step / 20;
      final background = Color.lerp(base, away, shift)!;
      final panel =
          Color.alphaBlend(foreground.withValues(alpha: 0.14), background);
      if (_contrastRatio(foreground, panel) >= 4.5) {
        return shift;
      }
    }
    return 1.0;
  }

  double _contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
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
            value: l10n.exceededCount(exceededBudgets.length),
            icon: Icons.warning_amber_outlined,
            tone: MetricCardTone.danger,
            onTap: () =>
                ref.read(currentTabProvider.notifier).state = AppTab.plan,
          ),
        );
      } else if (nearLimitBudgets.isNotEmpty) {
        attentionCards.add(
          AppMetricCard.status(
            label: l10n.budgets,
            value: l10n.nearLimitCount(nearLimitBudgets.length),
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
            title: l10n.needsAttention,
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
                final wallets =
                    ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];

                return categoriesAsync.when(
                  data: (categories) {
                    // Transfers carry no category: label them "from -> to".
                    if (transaction.type == model.TransactionType.transfer) {
                      final from = wallets
                          .where((w) => w.id == transaction.walletId)
                          .firstOrNull;
                      final to = wallets
                          .where((w) => w.id == transaction.toWalletId)
                          .firstOrNull;

                      return TransactionItem.compact(
                        transaction: transaction,
                        categoryName:
                            '${from?.name ?? l10n.unknown} → ${to?.name ?? l10n.unknown}',
                        categoryIcon: Icons.swap_horiz,
                        categoryColor: Theme.of(context).colorScheme.primary,
                        showChevron: true,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/transaction-detail',
                            arguments: transaction.id,
                          );
                        },
                      );
                    }

                    final category = categories.firstWhere(
                      (c) => c.id == transaction.categoryId,
                      orElse: () => uncategorizedCategory(
                        transaction.categoryId ?? '',
                        l10n.uncategorized,
                      ),
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
                  loading: () => const ShimmerListItem(),
                  error: (_, __) => InlineLoadErrorState(
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

/// Horizontally scrolling per-wallet balance cards shown under the hero
/// summary. Renders nothing while loading, on error, or when the workspace has
/// no wallets yet, so the home screen layout never jumps.
class _WalletBalanceStrip extends ConsumerWidget {
  const _WalletBalanceStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final wallets = ref.watch(walletsProvider).valueOrNull;
    if (wallets == null || wallets.isEmpty) {
      return const SizedBox.shrink();
    }

    final balances =
        ref.watch(walletBalancesProvider).valueOrNull ?? const <String, int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.wallets,
          trailing: Text(
            l10n.manageWallets,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          onTrailingTap: () => Navigator.pushNamed(context, '/wallets'),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            itemCount: wallets.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return _WalletBalanceCard(
                wallet: wallet,
                balance: balances[wallet.id] ?? wallet.openingBalanceMinor,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.wallet, required this.balance});

  final Wallet wallet;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(wallet.colorValue);

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/wallets'),
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(CategoryIcons.getIcon(wallet.iconName),
                    size: AppSpacing.iconSizeSm, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            Text(
              CurrencyFormatter.formatVNDFromCents(
                balance,
                locale: Localizations.localeOf(context).toString(),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: balance < 0 ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
