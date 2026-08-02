import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/providers/budget_providers.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_activity_tab.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_metric_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_status_chip.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class WorkspaceDetailScreen extends HookConsumerWidget {
  const WorkspaceDetailScreen({super.key, this.workspaceId});

  final String? workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      if (workspaceId != null) {
        ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;
      }
      return null;
    }, [workspaceId]);

    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(workspaceDetailProvider);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: detailAsync.maybeWhen(
            data: (detail) => Text(detail?.name ?? l10n.activeWorkspace),
            orElse: () => Text(l10n.activeWorkspace),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.overview),
              Tab(text: l10n.categories),
              Tab(text: l10n.budgets),
              Tab(text: l10n.transactions),
              Tab(text: l10n.membersSection),
              Tab(text: l10n.activity),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'manage') {
                  Navigator.of(context).pushNamed('/workspace-management');
                  return;
                }
                if (value == 'switch') {
                  Navigator.of(context).pushNamed('/workspace-selection');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'manage',
                  child: Text(l10n.manageWorkspaces),
                ),
                PopupMenuItem(
                  value: 'switch',
                  child: Text(l10n.switchWorkspace),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _OverviewTab(),
            _CategoriesTab(),
            _BudgetsTab(),
            _TransactionsTab(),
            _MembersTab(),
            const WorkspaceActivityTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(workspaceDetailProvider);
    final budgetsAsync = ref.watch(budgetsWithConsumedProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return RefreshIndicator(
      onRefresh: () => _refreshWorkspace(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          detailAsync.when(
            data: (detail) {
              if (detail == null) {
                return const SizedBox.shrink();
              }
              return _WorkspaceHeroCard(detail: detail);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(l10n.errorWithMessage('$error')),
          ),
          const SizedBox(height: AppSpacing.lg),
          _WorkspaceMetricGrid(
            membersCount: detailAsync.valueOrNull?.memberCount,
            categoriesCount: categoriesAsync.valueOrNull?.length,
            budgetsCount: budgetsAsync.valueOrNull?.length,
            transactionsCount: transactionsAsync.valueOrNull?.length,
          ),
          const SizedBox(height: AppSpacing.lg),
          budgetsAsync.when(
            data: (budgets) => _BudgetProgressCard(budgets: budgets.take(5)),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(l10n.errorWithMessage('$error')),
          ),
          const SizedBox(height: AppSpacing.lg),
          transactionsAsync.when(
            data: (transactions) => _RecentTransactionsCard(
              transactions: transactions.take(5),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(l10n.errorWithMessage('$error')),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      data: (categories) => RefreshIndicator(
        onRefresh: () => _refreshWorkspace(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final result =
                      await Navigator.of(context).pushNamed('/category-edit');
                  if (result == true) {
                    ref.invalidate(categoriesProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addCategory),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (categories.isEmpty)
              EmptyState.compact(
                icon: Icons.category_outlined,
                title: l10n.noCategoriesYet,
                message: l10n.noCategoriesYetDesc,
              )
            else
              _GroupedListCard(
                children: categories
                    .map(
                      (category) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(category.name),
                        subtitle: Text(category.type.name),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorWithMessage('$error'))),
    );
  }
}

class _BudgetsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetsWithConsumedProvider);
    return budgetsAsync.when(
      data: (budgets) => RefreshIndicator(
        onRefresh: () => _refreshWorkspace(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final result =
                      await Navigator.of(context).pushNamed('/budget-edit');
                  if (result == true) {
                    ref.invalidate(budgetsProvider);
                    ref.invalidate(budgetsWithConsumedProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addBudget),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (budgets.isEmpty)
              EmptyState.compact(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.noBudgetsYet,
                message: l10n.createFirstBudget,
              )
            else
              _GroupedListCard(
                children: budgets
                    .map(
                      (budget) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          CurrencyFormatter.formatVNDFromCents(
                            budget.limitCents,
                            locale: l10n.localeName,
                          ),
                        ),
                        subtitle: Text(budget.periodType.name),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorWithMessage('$error'))),
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    return transactionsAsync.when(
      data: (transactions) => RefreshIndicator(
        onRefresh: () => _refreshWorkspace(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).pushNamed(
                    '/add-transaction',
                    arguments: {'scopeMode': 'picker'},
                  );
                  if (result == true) {
                    ref.invalidate(transactionsProvider);
                    ref.invalidate(budgetsWithConsumedProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addTransaction),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (transactions.isEmpty)
              EmptyState.compact(
                icon: Icons.receipt_long_outlined,
                title: l10n.noTransactionsYet,
                message: l10n.noTransactionsYetDesc,
              )
            else
              _GroupedListCard(
                children: transactions
                    .map(
                      (transaction) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(transaction.note ?? l10n.transactions),
                        subtitle: Text(formatLocalizedDateTime(
                          context,
                          transaction.dateTime.toLocal(),
                        )),
                        trailing: Text(
                          CurrencyFormatter.formatVNDFromCents(
                            transaction.amountCents,
                            locale: l10n.localeName,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorWithMessage('$error'))),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(workspaceMembersProvider);
    return membersAsync.when(
      data: (members) => RefreshIndicator(
        onRefresh: () => _refreshWorkspace(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/workspace-management'),
                icon: const Icon(Icons.settings),
                label: Text(l10n.manageMembers),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (members.isEmpty)
              EmptyState.compact(
                icon: Icons.group_outlined,
                title: l10n.noMembersFound,
                message: l10n.noMembersFoundDesc,
              )
            else
              ...members.map(
                (member) => _MemberSummaryTile(member: member),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorWithMessage('$error'))),
    );
  }
}

class _WorkspaceHeroCard extends StatelessWidget {
  const _WorkspaceHeroCard({required this.detail});

  final WorkspaceDetailSummary detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(detail.name.substring(0, 1).toUpperCase()),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      detail.description?.trim().isNotEmpty == true
                          ? detail.description!
                          : l10n.workspaceTypeValue(detail.type),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppStatusChip.info(label: l10n.roleValue(detail.currentUserRole)),
              AppStatusChip(
                label: l10n.memberCount(detail.memberCount),
                color: Theme.of(context).colorScheme.primary,
                icon: Icons.group_outlined,
              ),
              AppStatusChip(
                label: l10n.updatedAt(
                  formatLocalizedDateTime(context, detail.updatedAt.toLocal()),
                ),
                color: AppColors.textSecondary,
                icon: Icons.schedule_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceMetricGrid extends StatelessWidget {
  const _WorkspaceMetricGrid({
    required this.membersCount,
    required this.categoriesCount,
    required this.budgetsCount,
    required this.transactionsCount,
  });

  final int? membersCount;
  final int? categoriesCount;
  final int? budgetsCount;
  final int? transactionsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      AppMetricCard.status(
        label: l10n.membersSection,
        value: _countLabel(membersCount),
        icon: Icons.group_outlined,
      ),
      AppMetricCard.status(
        label: l10n.categories,
        value: _countLabel(categoriesCount),
        icon: Icons.category_outlined,
      ),
      AppMetricCard.status(
        label: l10n.budgets,
        value: _countLabel(budgetsCount),
        icon: Icons.account_balance_wallet_outlined,
      ),
      AppMetricCard.status(
        label: l10n.transactions,
        value: _countLabel(transactionsCount),
        icon: Icons.receipt_long_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: crossAxisCount == 4 ? 1.25 : 1.45,
          children: cards,
        );
      },
    );
  }

  String _countLabel(int? value) => value == null ? '...' : '$value';
}

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({required this.budgets});

  final Iterable<Budget> budgets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetList = budgets.toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetProgress,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (budgetList.isEmpty)
            EmptyState.compact(
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.noBudgetsYet,
              message: l10n.createFirstBudget,
            )
          else
            ...budgetList.map((budget) => _BudgetProgressRow(budget: budget)),
        ],
      ),
    );
  }
}

class _BudgetProgressRow extends StatelessWidget {
  const _BudgetProgressRow({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final limitCents = budget.limitCents;
    final consumedCents = budget.consumedCents;
    final progress = limitCents == 0
        ? 0.0
        : (consumedCents / limitCents).clamp(0.0, 1.0).toDouble();
    final exceeded = consumedCents > limitCents;
    final color = exceeded
        ? AppColors.error
        : progress >= 0.8
            ? AppColors.warning
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.budgetUsage(
                    CurrencyFormatter.formatVNDFromCents(
                      consumedCents,
                      locale: l10n.localeName,
                    ),
                    CurrencyFormatter.formatVNDFromCents(
                      limitCents,
                      locale: l10n.localeName,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              AppStatusChip(
                label: exceeded ? l10n.overBudget : l10n.onTrack,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: progress, color: color),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({required this.transactions});

  final Iterable<model.Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transactionList = transactions.toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentTransactions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (transactionList.isEmpty)
            EmptyState.compact(
              icon: Icons.receipt_long_outlined,
              title: l10n.noTransactionsYet,
              message: l10n.noTransactionsYetDesc,
            )
          else
            ...transactionList.map(
              (transaction) => _RecentTransactionTile(transaction: transaction),
            ),
        ],
      ),
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.transaction});

  final model.Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isExpense = transaction.type == model.TransactionType.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(transaction.note?.trim().isNotEmpty == true
          ? transaction.note!
          : l10n.transactions),
      subtitle: Text(formatLocalizedDateTime(
        context,
        transaction.dateTime.toLocal(),
      )),
      trailing: Text(
        CurrencyFormatter.formatVNDFromCents(
          transaction.amountCents,
          locale: l10n.localeName,
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MemberSummaryTile extends StatelessWidget {
  const _MemberSummaryTile({required this.member});

  final WorkspaceMemberSummary member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(_memberName(member, l10n)[0])),
      title: Text(_memberName(member, l10n)),
      subtitle: Text(member.email ?? l10n.userIdValue(_shortId(member.userId))),
      trailing: Wrap(
        spacing: AppSpacing.xs,
        children: [
          AppStatusChip.info(label: l10n.roleValue(member.role)),
          AppStatusChip.success(
              label: l10n.statusValue(member.membershipStatus)),
        ],
      ),
    );
  }
}

/// Card that hosts a tight vertical list of rows separated by hairline
/// dividers, used for category/budget/transaction lists to match the
/// mockup's grouped-row card pattern.
class _GroupedListCard extends StatelessWidget {
  const _GroupedListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: Theme.of(context).dividerColor),
            children[i],
          ],
        ],
      ),
    );
  }
}

Future<void> _refreshWorkspace(WidgetRef ref) async {
  await syncCurrentWorkspaceData(ref);
  ref.invalidate(workspaceDetailProvider);
  ref.invalidate(workspaceMembersProvider);
  ref.invalidate(workspacePendingInvitesProvider);
}

String _memberName(WorkspaceMemberSummary member, AppLocalizations l10n) {
  final displayName = member.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }
  final email = member.email?.trim();
  if (email != null && email.isNotEmpty) {
    return email;
  }
  return l10n.userShortLabel(_shortId(member.userId));
}

String _shortId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return '${value.substring(0, 8)}...';
}
