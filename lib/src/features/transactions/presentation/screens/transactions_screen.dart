import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_segmented_filter.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

enum TransactionFilter { all, expense, income, transfer }

class TransactionsScreen extends HookConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    // Wallets are only needed to label transfers, so a missing value is fine.
    final walletMap = {
      for (final w
          in ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[])
        w.id: w,
    };

    final selectedFilter = useState(TransactionFilter.all);
    final searchQuery = useState('');
    final showSearch = useState(false);
    final pendingDeleteIds = useState<Set<String>>(const {});
    final searchDebounce = useRef<Timer?>(null);
    useEffect(() => () => searchDebounce.value?.cancel(), const []);

    void cancelSearchDebounce() {
      searchDebounce.value?.cancel();
      searchDebounce.value = null;
    }

    Future<bool> canManage(Transaction transaction) async {
      try {
        return await ref.read(
          transactionCanManageProvider(transaction.id).future,
        );
      } catch (_) {
        return false;
      }
    }

    Future<bool> confirmSwipe(
      Transaction transaction,
      DismissDirection direction,
    ) async {
      if (!await canManage(transaction)) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            l10n.transactionManageNotAllowed,
            type: AppSnackBarType.error,
          );
        }
        return false;
      }
      if (direction == DismissDirection.endToStart) return true;
      if (!context.mounted) return false;
      final result = await Navigator.pushNamed(
        context,
        '/edit-transaction',
        arguments: transaction.id,
      );
      if (result == true && context.mounted) {
        ref.invalidate(transactionsProvider);
        ref.invalidate(walletBalancesProvider);
      }
      return false;
    }

    Future<void> deleteWithUndo(Transaction transaction) async {
      final container = ProviderScope.containerOf(context, listen: false);
      final repository = ref.read(transactionRepositoryProvider);
      final receiptService = ref.read(transactionReceiptServiceProvider);
      pendingDeleteIds.value = {...pendingDeleteIds.value, transaction.id};

      void restore() {
        if (!context.mounted) return;
        pendingDeleteIds.value = {...pendingDeleteIds.value}
          ..remove(transaction.id);
      }

      final reason = await showAppSnackBar(
        context,
        l10n.transactionDeleted,
        onUndo: () {},
      ).closed;
      if (reason == SnackBarClosedReason.action) {
        restore();
        return;
      }
      try {
        await receiptService
            .removeReceipt(transaction.id)
            .catchError((Object _) {});
        await repository.deleteTransaction(transaction.id);
      } catch (e) {
        restore();
        if (context.mounted) {
          showAppSnackBar(
            context,
            mapSupabaseException(e).toString(),
            type: AppSnackBarType.error,
          );
        }
        return;
      }
      container
        ..invalidate(transactionsProvider)
        ..invalidate(budgetsProvider)
        ..invalidate(budgetsWithConsumedProvider)
        ..invalidate(walletBalancesProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: showSearch.value
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.search,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: (value) {
                  searchDebounce.value?.cancel();
                  searchDebounce.value = Timer(
                    const Duration(milliseconds: 300),
                    () => searchQuery.value = value,
                  );
                },
              )
            : Text(l10n.transactions),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: showSearch.value ? l10n.close : l10n.search,
                icon: Icon(showSearch.value ? Icons.close : Icons.search),
                onPressed: () {
                  showSearch.value = !showSearch.value;
                  if (!showSearch.value) {
                    cancelSearchDebounce();
                    searchQuery.value = '';
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter with improved visual clarity
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.md,
            ),
            child: AppSegmentedFilter<TransactionFilter>(
              options: [
                FilterOption(
                  label: l10n.all,
                  value: TransactionFilter.all,
                  icon: Icons.list,
                ),
                FilterOption(
                  label: l10n.expense,
                  value: TransactionFilter.expense,
                  icon: Icons.arrow_upward,
                  color: context.semanticColors.expense,
                ),
                FilterOption(
                  label: l10n.income,
                  value: TransactionFilter.income,
                  icon: Icons.arrow_downward,
                  color: context.semanticColors.income,
                ),
                FilterOption(
                  label: l10n.transfer,
                  value: TransactionFilter.transfer,
                  icon: Icons.swap_horiz,
                ),
              ],
              selectedValue: selectedFilter.value,
              onChanged: (value) => selectedFilter.value = value,
            ),
          ),

          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // Apply filters
                var filteredTransactions = transactions
                    .where((t) => !pendingDeleteIds.value.contains(t.id))
                    .toList();

                // Filter by type
                if (selectedFilter.value == TransactionFilter.expense) {
                  filteredTransactions = filteredTransactions
                      .where((t) => t.type == TransactionType.expense)
                      .toList();
                } else if (selectedFilter.value == TransactionFilter.income) {
                  filteredTransactions = filteredTransactions
                      .where((t) => t.type == TransactionType.income)
                      .toList();
                } else if (selectedFilter.value == TransactionFilter.transfer) {
                  filteredTransactions = filteredTransactions
                      .where((t) => t.type == TransactionType.transfer)
                      .toList();
                }

                // Filter by search query
                if (searchQuery.value.isNotEmpty) {
                  filteredTransactions = filteredTransactions.where((t) {
                    final query = searchQuery.value.toLowerCase();
                    final amount = CurrencyFormatter.formatVNDFromCents(
                      t.amountCents,
                      locale: l10n.localeName,
                    ).toLowerCase();
                    final note = (t.note ?? '').toLowerCase();
                    return amount.contains(query) || note.contains(query);
                  }).toList();
                }

                // Handle empty states
                if (filteredTransactions.isEmpty) {
                  Widget emptyState;
                  if (searchQuery.value.isNotEmpty) {
                    emptyState = EmptyState.noSearchResult(
                      icon: Icons.search_off,
                      title: l10n.noTransactionsMatch,
                      message: l10n.adjustSearchTerms,
                      actionLabel: l10n.clearFilter,
                      actionIcon: Icons.filter_alt_off,
                      onAction: () {
                        cancelSearchDebounce();
                        showSearch.value = false;
                        searchQuery.value = '';
                      },
                      compact: true,
                    );
                  } else if (selectedFilter.value != TransactionFilter.all) {
                    final (icon, title, message) =
                        switch (selectedFilter.value) {
                      TransactionFilter.expense => (
                          Icons.arrow_upward,
                          l10n.noExpenseTitle,
                          l10n.noExpenseTransactionsFound,
                        ),
                      TransactionFilter.transfer => (
                          Icons.swap_horiz,
                          l10n.noTransferTitle,
                          l10n.noTransferTransactionsFound,
                        ),
                      _ => (
                          Icons.arrow_downward,
                          l10n.noIncomeTitle,
                          l10n.noIncomeTransactionsFound,
                        ),
                    };
                    emptyState = EmptyState(
                      icon: icon,
                      title: title,
                      message: message,
                      actionLabel: l10n.addTransaction,
                      onAction: () {
                        Navigator.pushNamed(context, '/add-transaction');
                      },
                      secondaryActionLabel: l10n.clearFilter,
                      onSecondaryAction: () {
                        selectedFilter.value = TransactionFilter.all;
                      },
                      compact: true,
                      type: EmptyStateType.noFilterResult,
                    );
                  } else {
                    emptyState = EmptyState.firstRun(
                      icon: Icons.receipt_long,
                      title: l10n.startTracking,
                      message: l10n.onboardingSubtitle,
                      actionLabel: l10n.addTransaction,
                      onAction: () {
                        Navigator.pushNamed(context, '/add-transaction');
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => syncCurrentWorkspaceData(ref),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          child: emptyState,
                        ),
                      ],
                    ),
                  );
                }

                // Group by date
                final groupedTransactions =
                    _groupTransactionsByDate(filteredTransactions);

                return categoriesAsync.when(
                  data: (categories) {
                    final categoryMap = {for (var c in categories) c.id: c};

                    return RefreshIndicator(
                      onRefresh: () async {
                        await syncCurrentWorkspaceData(ref);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        itemCount: groupedTransactions.length,
                        itemBuilder: (context, index) {
                          final group = groupedTransactions[index];
                          return _TransactionGroup(
                            date: group.date,
                            transactions: group.transactions,
                            categoryMap: categoryMap,
                            walletMap: walletMap,
                            confirmSwipe: confirmSwipe,
                            onDelete: deleteWithUndo,
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => LoadErrorState(
                    title: l10n.dataLoadFailed,
                    message: l10n.dataLoadFailedHint,
                    retryLabel: l10n.retry,
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => LoadErrorState(
                title: l10n.dataLoadFailed,
                message: l10n.dataLoadFailedHint,
                retryLabel: l10n.retry,
                onRetry: () => ref.invalidate(transactionsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_TransactionDateGroup> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final groups = <DateTime, List<Transaction>>{};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.dateTime.year,
        transaction.dateTime.month,
        transaction.dateTime.day,
      );

      if (!groups.containsKey(date)) {
        groups[date] = [];
      }
      groups[date]!.add(transaction);
    }

    final sortedDates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedDates.map((date) {
      return _TransactionDateGroup(
        date: date,
        transactions: groups[date]!,
      );
    }).toList();
  }
}

class _TransactionDateGroup {
  final DateTime date;
  final List<Transaction> transactions;

  _TransactionDateGroup({
    required this.date,
    required this.transactions,
  });
}

class _TransactionGroup extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final Map<String, Category> categoryMap;
  final Map<String, Wallet> walletMap;
  final Future<bool> Function(Transaction, DismissDirection) confirmSwipe;
  final ValueChanged<Transaction> onDelete;

  const _TransactionGroup({
    required this.date,
    required this.transactions,
    required this.categoryMap,
    required this.walletMap,
    required this.confirmSwipe,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateLabel;
    if (date == today) {
      dateLabel = l10n.today;
    } else if (date == yesterday) {
      dateLabel = l10n.yesterday;
    } else {
      dateLabel = formatLocalizedFullDate(context, date);
    }

    // Calculate net total for the day (matches mockup's single net-amount label)
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    final net = totalIncome - totalExpense;
    final netColor = net < 0
        ? context.semanticColors.expense
        : net > 0
            ? context.semanticColors.income
            : null;
    final netLabel = net == 0
        ? ''
        : ' · ${net > 0 ? '+' : ''}${CurrencyFormatter.formatVNDFromCents(net, locale: l10n.localeName)}';

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date label with income/expense summary chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            child: Text.rich(
              TextSpan(
                text: dateLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
                children: [
                  if (netLabel.isNotEmpty)
                    TextSpan(
                      text: netLabel,
                      style: TextStyle(color: netColor),
                    ),
                ],
              ),
            ),
          ),

          // Transactions grouped in a rounded, bordered card (matches design)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: AppCard(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < transactions.length; i++) ...[
                    Builder(builder: (context) {
                      final transaction = transactions[i];
                      final category = categoryMap[transaction.categoryId];
                      final isTransfer =
                          transaction.type == TransactionType.transfer;
                      // Transfers have no category: label them "from -> to".
                      final fromWallet = walletMap[transaction.walletId];
                      final toWallet = walletMap[transaction.toWalletId];

                      final item = TransactionItem(
                        transaction: transaction,
                        categoryName: isTransfer
                            ? '${fromWallet?.name ?? l10n.unknown} → '
                                '${toWallet?.name ?? l10n.unknown}'
                            : category?.name ?? l10n.unknown,
                        categoryIconName:
                            isTransfer ? null : category?.iconName,
                        categoryIcon: isTransfer ? Icons.swap_horiz : null,
                        categoryColor: isTransfer
                            ? Theme.of(context).colorScheme.primary
                            : category != null
                                ? getCategoryColor(category.colorValue)
                                : null,
                        showDate: true, // Show date in subtitle
                        showChevron: true,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/transaction-detail',
                            arguments: transaction.id,
                          );
                        },
                      );
                      return Dismissible(
                        key: ValueKey(transaction.id),
                        background: _SwipeBackground(
                          icon: Icons.edit_outlined,
                          label: l10n.edit,
                          color: theme.colorScheme.primary,
                          foreground: theme.colorScheme.onPrimary,
                          alignment: Alignment.centerLeft,
                        ),
                        secondaryBackground: _SwipeBackground(
                          icon: Icons.delete_outline,
                          label: l10n.delete,
                          color: theme.colorScheme.error,
                          foreground: theme.colorScheme.onError,
                          alignment: Alignment.centerRight,
                        ),
                        confirmDismiss: (direction) =>
                            confirmSwipe(transaction, direction),
                        onDismissed: (_) => onDelete(transaction),
                        child: item,
                      );
                    }),
                    if (i != transactions.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Divider(
                          height: 1,
                          color: theme.dividerColor,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final Alignment alignment;

  const _SwipeBackground({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
