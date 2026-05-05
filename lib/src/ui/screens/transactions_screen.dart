// path: lib/src/ui/screens/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_segmented_filter.dart';
import '../widgets/category_icon_widget.dart';
import '../widgets/empty_state.dart';

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
          // Filter
          AppSegmentedFilter<TransactionFilter>(
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
                    final amount = CurrencyFormatter.formatVNDFromCents(t.amountCents).toLowerCase();
                    final note = (t.note ?? '').toLowerCase();
                    return amount.contains(query) || note.contains(query);
                  }).toList();
                }
                
                if (filteredTransactions.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long,
                    title: l10n.noTransactions,
                    message: searchQuery.value.isNotEmpty
                        ? 'No transactions match your search'
                        : 'Start tracking your finances',
                    actionLabel: l10n.addTransaction,
                    onAction: () {
                      Navigator.pushNamed(context, '/add-transaction');
                    },
                  );
                }
                
                // Group by date
                final groupedTransactions = _groupTransactionsByDate(filteredTransactions);
                
                return categoriesAsync.when(
                  data: (categories) {
                    final categoryMap = {for (var c in categories) c.id: c};
                    
                    return ListView.builder(
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
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  List<_TransactionDateGroup> _groupTransactionsByDate(List<Transaction> transactions) {
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
  final Map<int, Category> categoryMap;

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
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, dd MMM yyyy').format(date);
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
        // Date Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  if (totalIncome > 0) ...[
                    Text(
                      '+${CurrencyFormatter.formatVNDFromCents(totalIncome)}',
                      style: TextStyle(
                        color: AppColors.income,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (totalExpense > 0)
                    Text(
                      '-${CurrencyFormatter.formatVNDFromCents(totalExpense)}',
                      style: TextStyle(
                        color: AppColors.expense,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Transactions
        ...transactions.map((transaction) {
          final category = categoryMap[transaction.categoryId];
          final isExpense = transaction.type == TransactionType.expense;
          final amountColor = isExpense ? AppColors.expense : AppColors.income;
          final amountPrefix = isExpense ? '-' : '+';
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: category != null
                  ? getCategoryColor(category.colorValue).withOpacity(0.1)
                  : Colors.grey[200],
              child: category != null
                  ? CategoryIconWidget(
                      iconName: category.iconName,
                      size: 20,
                      color: getCategoryColor(category.colorValue),
                    )
                  : const Icon(Icons.category, size: 20),
            ),
            title: Text(category?.name ?? 'Unknown'),
            subtitle: transaction.note != null && transaction.note!.isNotEmpty
                ? Text(
                    transaction.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Text(
              '$amountPrefix${CurrencyFormatter.formatVNDFromCents(transaction.amountCents)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
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
