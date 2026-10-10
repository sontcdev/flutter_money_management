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

part 'transactions_screen_sections.dart';

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

    Future<bool> confirmSwipe(Transaction t, DismissDirection d) =>
        _confirmSwipe(context, ref, l10n, t, d);

    Future<void> deleteWithUndo(Transaction t) =>
        _deleteWithUndo(context, ref, l10n, pendingDeleteIds, t);

    return Scaffold(
      appBar: AppBar(
        title: showSearch.value
            ? _SearchField(
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
          _SearchToggleButton(
            showSearch: showSearch.value,
            onPressed: () {
              showSearch.value = !showSearch.value;
              if (!showSearch.value) {
                cancelSearchDebounce();
                searchQuery.value = '';
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter with improved visual clarity
          _TransactionFilterBar(
            selectedValue: selectedFilter.value,
            onChanged: (value) => selectedFilter.value = value,
          ),

          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // Apply filters
                final filteredTransactions = _applyFilters(
                  transactions,
                  pendingDeleteIds: pendingDeleteIds.value,
                  filter: selectedFilter.value,
                  searchQuery: searchQuery.value,
                  localeName: l10n.localeName,
                );

                // Handle empty states
                if (filteredTransactions.isEmpty) {
                  return _TransactionsEmptyView(
                    hasSearchQuery: searchQuery.value.isNotEmpty,
                    filter: selectedFilter.value,
                    onRefresh: () => syncCurrentWorkspaceData(ref),
                    onClearSearch: () {
                      cancelSearchDebounce();
                      showSearch.value = false;
                      searchQuery.value = '';
                    },
                    onClearFilter: () {
                      selectedFilter.value = TransactionFilter.all;
                    },
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

  Future<bool> _canManage(WidgetRef ref, Transaction transaction) async {
    try {
      return await ref.read(
        transactionCanManageProvider(transaction.id).future,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _confirmSwipe(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Transaction transaction,
    DismissDirection direction,
  ) async {
    if (!await _canManage(ref, transaction)) {
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

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ValueNotifier<Set<String>> pendingDeleteIds,
    Transaction transaction,
  ) async {
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

  List<Transaction> _applyFilters(
    List<Transaction> transactions, {
    required Set<String> pendingDeleteIds,
    required TransactionFilter filter,
    required String searchQuery,
    required String localeName,
  }) {
    var filteredTransactions =
        transactions.where((t) => !pendingDeleteIds.contains(t.id)).toList();

    // Filter by type
    if (filter == TransactionFilter.expense) {
      filteredTransactions = filteredTransactions
          .where((t) => t.type == TransactionType.expense)
          .toList();
    } else if (filter == TransactionFilter.income) {
      filteredTransactions = filteredTransactions
          .where((t) => t.type == TransactionType.income)
          .toList();
    } else if (filter == TransactionFilter.transfer) {
      filteredTransactions = filteredTransactions
          .where((t) => t.type == TransactionType.transfer)
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filteredTransactions = filteredTransactions.where((t) {
        final query = searchQuery.toLowerCase();
        final amount = CurrencyFormatter.formatVNDFromCents(
          t.amountCents,
          locale: localeName,
        ).toLowerCase();
        final note = (t.note ?? '').toLowerCase();
        return amount.contains(query) || note.contains(query);
      }).toList();
    }
    return filteredTransactions;
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
