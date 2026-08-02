import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/widgets/budget_progress.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

enum BudgetFilter { all, onTrack, nearLimit, exceeded }

enum BudgetSort { name, amount, percentage }

class BudgetsScreen extends ConsumerWidget {
  final bool showBackButton;

  const BudgetsScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetsWithConsumedProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final canManageContent = ref.watch(canManageWorkspaceContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgets),
        automaticallyImplyLeading: showBackButton,
        actions: [
          if (canManageContent)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/budget-edit');
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
          await syncCurrentWorkspaceData(ref);
        },
        child: budgetsAsync.when(
          data: (budgets) {
            return categoriesAsync.when(
              data: (categories) {
                final categoryMap = {for (var c in categories) c.id: c};

                final filteredBudgets = budgets.where((b) {
                  final cat = categoryMap[b.categoryId];
                  return cat?.type == CategoryType.expense;
                }).toList();

                if (filteredBudgets.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: l10n.noBudgets,
                          message: l10n.createFirstBudget,
                          actionLabel:
                              canManageContent ? l10n.addBudgetAction : null,
                          onAction: canManageContent
                              ? () async {
                                  final result = await Navigator.pushNamed(
                                      context, '/budget-edit');
                                  if (result == true) {
                                    ref.invalidate(budgetsProvider);
                                    ref.invalidate(budgetsWithConsumedProvider);
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  );
                }

                return _BudgetsContent(
                  budgets: filteredBudgets,
                  categoryMap: categoryMap,
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) => const ShimmerCard(),
              ),
              error: (error, stack) =>
                  Center(child: Text(l10n.errorWithMessage('$error'))),
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => const ShimmerCard(),
          ),
          error: (error, stack) => Center(
            child: Text(l10n.errorWithMessage('$error')),
          ),
        ),
      ),
    );
  }
}

class _BudgetsContent extends ConsumerStatefulWidget {
  final List<Budget> budgets;
  final Map<String, Category> categoryMap;

  const _BudgetsContent({
    required this.budgets,
    required this.categoryMap,
  });

  @override
  ConsumerState<_BudgetsContent> createState() => _BudgetsContentState();
}

class _BudgetsContentState extends ConsumerState<_BudgetsContent> {
  BudgetFilter _filter = BudgetFilter.all;
  BudgetSort _sort = BudgetSort.percentage;

  List<Budget> get _filteredAndSortedBudgets {
    var result = widget.budgets.where((b) {
      final percentage =
          b.limitCents > 0 ? (b.consumedCents / b.limitCents * 100) : 0.0;

      switch (_filter) {
        case BudgetFilter.all:
          return true;
        case BudgetFilter.onTrack:
          return percentage < 80;
        case BudgetFilter.nearLimit:
          return percentage >= 80 && percentage <= 100;
        case BudgetFilter.exceeded:
          return percentage > 100;
      }
    }).toList();

    result.sort((a, b) {
      switch (_sort) {
        case BudgetSort.name:
          final catA = widget.categoryMap[a.categoryId]?.name ?? '';
          final catB = widget.categoryMap[b.categoryId]?.name ?? '';
          return catA.compareTo(catB);
        case BudgetSort.amount:
          return b.consumedCents.compareTo(a.consumedCents);
        case BudgetSort.percentage:
          final percA =
              a.limitCents > 0 ? (a.consumedCents / a.limitCents) : 0.0;
          final percB =
              b.limitCents > 0 ? (b.consumedCents / b.limitCents) : 0.0;
          return percB.compareTo(percA);
      }
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalLimit =
        widget.budgets.fold<int>(0, (sum, b) => sum + b.limitCents);
    final totalSpent =
        widget.budgets.fold<int>(0, (sum, b) => sum + b.consumedCents);
    final totalRemaining = totalLimit - totalSpent;

    final onTrackCount = widget.budgets.where((b) {
      final perc =
          b.limitCents > 0 ? (b.consumedCents / b.limitCents * 100) : 0.0;
      return perc < 80;
    }).length;

    final exceededCount = widget.budgets.where((b) {
      final perc =
          b.limitCents > 0 ? (b.consumedCents / b.limitCents * 100) : 0.0;
      return perc > 100;
    }).length;

    final filteredBudgets = _filteredAndSortedBudgets;

    return CustomScrollView(
      slivers: [
        // Summary section — hero gradient card with overall usage
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BudgetHeroCard(
                  totalLimit: totalLimit,
                  totalSpent: totalSpent,
                  totalRemaining: totalRemaining,
                  locale: l10n.localeName,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard(
                        label: l10n.onTrack,
                        count: onTrackCount,
                        color: AppColors.primary,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatusCard(
                        label: l10n.exceeded,
                        count: exceededCount,
                        color: AppColors.error,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Filter & Sort bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: l10n.all,
                          count: widget.budgets.length,
                          isSelected: _filter == BudgetFilter.all,
                          onTap: () =>
                              setState(() => _filter = BudgetFilter.all),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: l10n.onTrack,
                          count: onTrackCount,
                          isSelected: _filter == BudgetFilter.onTrack,
                          onTap: () =>
                              setState(() => _filter = BudgetFilter.onTrack),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: l10n.nearLimit,
                          count: widget.budgets.where((b) {
                            final perc = b.limitCents > 0
                                ? (b.consumedCents / b.limitCents * 100)
                                : 0.0;
                            return perc >= 80 && perc <= 100;
                          }).length,
                          isSelected: _filter == BudgetFilter.nearLimit,
                          onTap: () =>
                              setState(() => _filter = BudgetFilter.nearLimit),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: l10n.exceeded,
                          count: exceededCount,
                          isSelected: _filter == BudgetFilter.exceeded,
                          onTap: () =>
                              setState(() => _filter = BudgetFilter.exceeded),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PopupMenuButton<BudgetSort>(
                  icon: const Icon(Icons.sort),
                  onSelected: (sort) => setState(() => _sort = sort),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: BudgetSort.percentage,
                      child: Row(
                        children: [
                          Icon(
                            Icons.percent,
                            size: 20,
                            color: _sort == BudgetSort.percentage
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.byUsagePercent),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: BudgetSort.amount,
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 20,
                            color: _sort == BudgetSort.amount
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.byAmount),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: BudgetSort.name,
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            size: 20,
                            color: _sort == BudgetSort.name
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.byName),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Budget list
        if (filteredBudgets.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list_off,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.noBudgetsMatchFilter,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final budget = filteredBudgets[index];
                  return _SwipeableBudgetCard(
                    budget: budget,
                    onDeleted: () {
                      ref.invalidate(budgetsProvider);
                      ref.invalidate(budgetsWithConsumedProvider);
                    },
                  );
                },
                childCount: filteredBudgets.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero gradient card showing the total budget limit for the current period,
/// how much has been spent, and a progress bar toward the total limit.
class _BudgetHeroCard extends StatelessWidget {
  final int totalLimit;
  final int totalSpent;
  final int totalRemaining;
  final String locale;

  const _BudgetHeroCard({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = totalLimit > 0 ? totalSpent / totalLimit : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primaryDark, AppColors.primaryStrong]
              : [AppColors.primary, AppColors.primaryStrong],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetOverview,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.formatVNDFromCents(totalLimit, locale: locale),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.spent}: ${CurrencyFormatter.formatVNDFromCents(totalSpent, locale: locale)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                '${l10n.remaining}: ${CurrencyFormatter.formatVNDFromCents(totalRemaining, locale: locale)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
              final confirmed =
                  await _showDeleteConfirmDialog(context, l10n, categoryAsync);
              if (!context.mounted) return;
              if (confirmed) {
                await _deleteBudget(ref, l10n, context);
              }
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: l10n.delete,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(AppSpacing.radiusLg),
              bottomRight: Radius.circular(AppSpacing.radiusLg),
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
      data: (category) => category?.name ?? l10n.unknown,
      orElse: () => l10n.unknown,
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
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: Text(l10n.delete),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteBudget(
      WidgetRef ref, AppLocalizations l10n, BuildContext context) async {
    try {
      final repository = ref.read(budgetRepositoryProvider);
      await repository.deleteBudget(budget.id);
      onDeleted();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.budgetDeleted)),
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'budget',
          action: 'delete_budget',
          screen: 'budgets_screen',
          extraContext: {
            'budget_id': budget.id,
          },
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showBudgetTransactions(context, ref),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: getCategoryColor(category.colorValue)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Center(
                                child: CategoryIconWidget(
                                  iconName: category.iconName,
                                  size: 18,
                                  color: getCategoryColor(category.colorValue),
                                ),
                              ),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              category?.name ?? l10n.unknown,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => Text(l10n.loading),
                      error: (_, __) => Text(l10n.unknown),
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
                  categoryName: category?.name ?? l10n.unknown,
                  currency: 'VND',
                ),
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => BudgetProgress(
                  budget: budget,
                  categoryName: l10n.unknown,
                  currency: 'VND',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${CurrencyFormatter.formatVNDFromCents(budget.consumedCents, locale: l10n.localeName)} / ${CurrencyFormatter.formatVNDFromCents(budget.limitCents, locale: l10n.localeName)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${l10n.remaining}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - budget.consumedCents, locale: l10n.localeName)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: budget.consumedCents > budget.limitCents
                                ? AppColors.error
                                : AppColors.primary,
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
    final l10n = AppLocalizations.of(context)!;
    final categoryAsync = ref.read(categoryProvider(budget.categoryId));
    final categoryName = categoryAsync.maybeWhen(
      data: (category) => category?.name ?? l10n.unknown,
      orElse: () => l10n.unknown,
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

    final percentage = budget.limitCents > 0
        ? (budget.consumedCents / budget.limitCents * 100)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.editBudgetAction),
                  ],
                ),
                onTap: () async {
                  await Future.delayed(Duration.zero);
                  if (context.mounted) {
                    final result = await Navigator.pushNamed(
                      context,
                      '/budget-edit',
                      arguments: budget,
                    );
                    if (result == true) {
                      ref.invalidate(budgetsProvider);
                      ref.invalidate(budgetsWithConsumedProvider);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero summary card with gradient
          Builder(builder: (context) {
            final theme = Theme.of(context);
            final statusColor = percentage > 100
                ? AppColors.error
                : percentage >= 80
                    ? AppColors.warning
                    : AppColors.primary;
            final statusContainerColor = percentage > 100
                ? AppColors.expenseContainer
                : percentage >= 80
                    ? AppColors.warningContainer
                    : AppColors.incomeContainer;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusContainerColor,
                    statusContainerColor.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.spent,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              CurrencyFormatter.formatVNDFromCents(
                                  budget.consumedCents,
                                  locale: l10n.localeName),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.limit}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents, locale: l10n.localeName)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '${l10n.remaining}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - budget.consumedCents, locale: l10n.localeName)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: budget.consumedCents > budget.limitCents
                              ? AppColors.error
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Transactions list
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final budgetTransactions = transactions.where((t) {
                  return t.categoryId == budget.categoryId &&
                      t.type == TransactionType.expense &&
                      t.dateTime.isAfter(
                          periodStart.subtract(const Duration(seconds: 1))) &&
                      t.dateTime
                          .isBefore(periodEnd.add(const Duration(seconds: 1)));
                }).toList();

                if (budgetTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.noTransactions,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                final Map<DateTime, List<Transaction>> groupedByDate = {};
                for (final t in budgetTransactions) {
                  final date = DateTime(
                      t.dateTime.year, t.dateTime.month, t.dateTime.day);
                  if (!groupedByDate.containsKey(date)) {
                    groupedByDate[date] = [];
                  }
                  groupedByDate[date]!.add(t);
                }

                final sortedDates = groupedByDate.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final dayTransactions = groupedByDate[date]!;
                    final dayTotal = dayTransactions.fold<int>(
                        0, (sum, t) => sum + t.amountCents);

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(context, date),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    '-${CurrencyFormatter.formatVNDFromCents(dayTotal, locale: l10n.localeName)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...dayTransactions.map((t) => ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.expense
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
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
                                  formatLocalizedTime(context, t.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                trailing: Text(
                                  '-${CurrencyFormatter.formatVNDFromCents(t.amountCents, locale: l10n.localeName)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
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
              error: (err, _) =>
                  Center(child: Text(l10n.errorWithMessage('$err'))),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    return formatLocalizedDateWithWeekday(context, date);
  }
}
