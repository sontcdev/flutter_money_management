import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_segmented_filter.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

enum TransactionFilter { all, expense, income }

class TransactionsScreen extends HookConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final selectedFilter = useState(TransactionFilter.all);
    final searchQuery = useState('');
    final showSearch = useState(false);

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
                onChanged: (value) => searchQuery.value = value,
              )
            : Text(l10n.transactions),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(showSearch.value ? Icons.close : Icons.search),
            onPressed: () {
              showSearch.value = !showSearch.value;
              if (!showSearch.value) {
                searchQuery.value = '';
              }
            },
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
                  color: AppColors.expense,
                ),
                FilterOption(
                  label: l10n.income,
                  value: TransactionFilter.income,
                  icon: Icons.arrow_downward,
                  color: AppColors.income,
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
                var filteredTransactions = transactions;

                // Filter by type
                if (selectedFilter.value == TransactionFilter.expense) {
                  filteredTransactions = filteredTransactions
                      .where((t) => t.type == TransactionType.expense)
                      .toList();
                } else if (selectedFilter.value == TransactionFilter.income) {
                  filteredTransactions = filteredTransactions
                      .where((t) => t.type == TransactionType.income)
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
                  if (searchQuery.value.isNotEmpty) {
                    return EmptyState.noSearchResult(
                      icon: Icons.search_off,
                      title: l10n.noTransactionsMatch,
                      message: l10n.adjustSearchTerms,
                      compact: true,
                    );
                  } else if (selectedFilter.value != TransactionFilter.all) {
                    return EmptyState(
                      icon: selectedFilter.value == TransactionFilter.expense
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      title: selectedFilter.value == TransactionFilter.expense
                          ? l10n.noExpenseTitle
                          : l10n.noIncomeTitle,
                      message: selectedFilter.value == TransactionFilter.expense
                          ? l10n.noExpenseTransactionsFound
                          : l10n.noIncomeTransactionsFound,
                      actionLabel: l10n.addTransaction,
                      onAction: () {
                        Navigator.pushNamed(context, '/add-transaction');
                      },
                      compact: true,
                      type: EmptyStateType.noFilterResult,
                    );
                  } else {
                    return EmptyState.firstRun(
                      icon: Icons.receipt_long,
                      title: l10n.startTracking,
                      message: l10n.onboardingSubtitle,
                      actionLabel: l10n.addTransaction,
                      onAction: () {
                        Navigator.pushNamed(context, '/add-transaction');
                      },
                    );
                  }
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
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(l10n.errorWithMessage('$error'))),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text(l10n.errorWithMessage('$error'))),
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

  const _TransactionGroup({
    required this.date,
    required this.transactions,
    required this.categoryMap,
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

    // Calculate totals
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Improved Date Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Row(
                children: [
                  if (totalIncome > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.incomeContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '+${CurrencyFormatter.formatVNDFromCents(totalIncome, locale: l10n.localeName)}',
                        style: TextStyle(
                          color: AppColors.income,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (totalExpense > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.expenseContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '-${CurrencyFormatter.formatVNDFromCents(totalExpense, locale: l10n.localeName)}',
                        style: TextStyle(
                          color: AppColors.expense,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Transactions using refactored TransactionItem
        ...transactions.map((transaction) {
          final category = categoryMap[transaction.categoryId];

          return TransactionItem(
            transaction: transaction,
            categoryName: category?.name ?? l10n.unknown,
            categoryIconName: category?.iconName,
            categoryColor:
                category != null ? getCategoryColor(category.colorValue) : null,
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
        }),
      ],
    );
  }
}
