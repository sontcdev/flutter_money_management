import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/providers/budget_providers.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_activity_tab.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';

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
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Categories'),
              Tab(text: 'Budgets'),
              Tab(text: 'Transactions'),
              Tab(text: 'Members'),
              Tab(text: 'Activity'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add_outlined),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/workspace-management'),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        detailAsync.when(
          data: (detail) {
            if (detail == null) {
              return const SizedBox.shrink();
            }
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(detail.name.substring(0, 1).toUpperCase()),
                ),
                title: Text(detail.name),
                subtitle: Text(detail.description ?? detail.type),
                trailing: Text('${detail.memberCount} members'),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(l10n.errorWithMessage('$error')),
        ),
        const SizedBox(height: 16),
        budgetsAsync.when(
          data: (budgets) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Budget progress'),
                  const SizedBox(height: 8),
                  if (budgets.isEmpty)
                    const Text('No budgets yet')
                  else
                    ...budgets.take(5).map(
                          (budget) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CurrencyFormatter.formatVNDFromCents(
                                    budget.consumedCents,
                                    locale: l10n.localeName,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: budget.limitCents == 0
                                      ? 0
                                      : (budget.consumedCents /
                                              budget.limitCents)
                                          .clamp(0, 1)
                                          .toDouble(),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(l10n.errorWithMessage('$error')),
        ),
        const SizedBox(height: 16),
        transactionsAsync.when(
          data: (transactions) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent transactions'),
                  const SizedBox(height: 8),
                  if (transactions.isEmpty)
                    const Text('No transactions yet')
                  else
                    ...transactions.take(5).map(
                          (transaction) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(transaction.note ?? l10n.transactions),
                            subtitle:
                                Text(transaction.dateTime.toLocal().toString()),
                            trailing: Text(
                              CurrencyFormatter.formatVNDFromCents(
                                transaction.amountCents,
                                locale: l10n.localeName,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(l10n.errorWithMessage('$error')),
        ),
      ],
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      data: (categories) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/category-edit'),
              icon: const Icon(Icons.add),
              label: const Text('Add category'),
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Text('No categories yet')
          else
            ...categories.map(
              (category) => ListTile(
                title: Text(category.name),
                subtitle: Text(category.type.name),
              ),
            ),
        ],
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
      data: (budgets) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/budget-edit'),
              icon: const Icon(Icons.add),
              label: const Text('Add budget'),
            ),
          ),
          const SizedBox(height: 16),
          if (budgets.isEmpty)
            const Text('No budgets yet')
          else
            ...budgets.map(
              (budget) => ListTile(
                title: Text(
                  CurrencyFormatter.formatVNDFromCents(
                    budget.limitCents,
                    locale: l10n.localeName,
                  ),
                ),
                subtitle: Text(budget.periodType.name),
              ),
            ),
        ],
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
      data: (transactions) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(
                '/add-transaction',
                arguments: {'scopeMode': 'picker'},
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add transaction'),
            ),
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const Text('No transactions yet')
          else
            ...transactions.map(
              (transaction) => ListTile(
                title: Text(transaction.note ?? l10n.transactions),
                subtitle: Text(transaction.type == model.TransactionType.expense
                    ? l10n.expense
                    : l10n.income),
                trailing: Text(
                  CurrencyFormatter.formatVNDFromCents(
                    transaction.amountCents,
                    locale: l10n.localeName,
                  ),
                ),
              ),
            ),
        ],
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
      data: (members) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/workspace-management'),
              icon: const Icon(Icons.settings),
              label: const Text('Manage members'),
            ),
          ),
          const SizedBox(height: 16),
          if (members.isEmpty)
            Text(l10n.noMembersFound)
          else
            ...members.map(
              (member) => ListTile(
                title: Text(member.displayName ?? member.email ?? l10n.unknown),
                subtitle: Text(member.role),
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorWithMessage('$error'))),
    );
  }
}
