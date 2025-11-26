// path: lib/src/ui/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';

class ReportsScreen extends HookConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final selectedPeriod = useState(0); // 0: Tháng này, 1: Tùy chỉnh (tháng), 2: Tùy chỉnh (năm)
    final customMonth = useState<DateTime?>(null);
    final customYear = useState<int?>(null);
    final reportTypeFilter = useState(0); // 0: All, 1: Expense, 2: Income

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PeriodButton(
                            label: l10n.thisMonth,
                            isSelected: selectedPeriod.value == 0,
                            onTap: () => selectedPeriod.value = 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PeriodButton(
                            label: l10n.custom,
                            isSelected: selectedPeriod.value == 1 || selectedPeriod.value == 2,
                            onTap: () async {
                              final result = await _showCustomPeriodPicker(
                                context, 
                                customMonth.value, 
                                customYear.value,
                              );
                              if (result != null) {
                                if (result['type'] == 'month') {
                                  customMonth.value = result['value'] as DateTime;
                                  customYear.value = null;
                                  selectedPeriod.value = 1;
                                } else {
                                  customYear.value = result['value'] as int;
                                  customMonth.value = null;
                                  selectedPeriod.value = 2;
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedPeriod.value == 1 && customMonth.value != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${l10n.month} ${customMonth.value!.month}/${customMonth.value!.year}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (selectedPeriod.value == 2 && customYear.value != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${l10n.year} ${customYear.value}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary Card
            transactionsAsync.when(
              data: (transactions) {
                final filteredTransactions = _filterTransactions(
                  transactions, 
                  selectedPeriod.value, 
                  customMonth.value,
                  customYear.value,
                );
                
                final totalIncome = filteredTransactions
                    .where((t) => t.type == TransactionType.income)
                    .fold<int>(0, (sum, t) => sum + t.amountCents);
                
                final totalExpense = filteredTransactions
                    .where((t) => t.type == TransactionType.expense)
                    .fold<int>(0, (sum, t) => sum + t.amountCents);
                
                final balance = totalIncome - totalExpense;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.overviewReport,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _SummaryRow(
                          label: l10n.totalIncome,
                          amount: totalIncome,
                          color: AppColors.income,
                          icon: Icons.arrow_downward,
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: l10n.totalExpense,
                          amount: totalExpense,
                          color: AppColors.expense,
                          icon: Icons.arrow_upward,
                        ),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: l10n.balance,
                          amount: balance,
                          color: balance >= 0 ? AppColors.income : AppColors.expense,
                          icon: balance >= 0 ? Icons.trending_up : Icons.trending_down,
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.transactionCount}: ${filteredTransactions.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('${l10n.error}: $err'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Type Filter for Reports
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ReportTypeButton(
                        label: l10n.all,
                        isSelected: reportTypeFilter.value == 0,
                        onTap: () => reportTypeFilter.value = 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReportTypeButton(
                        label: l10n.expense,
                        isSelected: reportTypeFilter.value == 1,
                        onTap: () => reportTypeFilter.value = 1,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReportTypeButton(
                        label: l10n.income,
                        isSelected: reportTypeFilter.value == 2,
                        onTap: () => reportTypeFilter.value = 2,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Budget Reports Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.budgetReports,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/budgets'),
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Combine budgets, categories and transactions for budget reports
            budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(l10n.noBudgets),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/budget-edit'),
                              child: Text(l10n.addBudget),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return categoriesAsync.when(
                  data: (categories) {
                    return transactionsAsync.when(
                      data: (transactions) {
                        // Get date range based on selected period
                        final dateRange = _getDateRange(selectedPeriod.value, customMonth.value, customYear.value);
                        
                        // Filter budgets based on category type
                        final categoryMap = {for (var c in categories) c.id: c};
                        List<Budget> filteredBudgets;
                        if (reportTypeFilter.value == 1) {
                          filteredBudgets = budgets.where((b) {
                            final cat = categoryMap[b.categoryId];
                            return cat?.type == CategoryType.expense;
                          }).toList();
                        } else if (reportTypeFilter.value == 2) {
                          filteredBudgets = budgets.where((b) {
                            final cat = categoryMap[b.categoryId];
                            return cat?.type == CategoryType.income;
                          }).toList();
                        } else {
                          filteredBudgets = budgets;
                        }

                        if (filteredBudgets.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  reportTypeFilter.value == 1 
                                      ? l10n.noExpenseBudgets 
                                      : reportTypeFilter.value == 2 
                                          ? l10n.noIncomeBudgets
                                          : l10n.noBudgets,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: filteredBudgets.map((budget) {
                            final category = categories.firstWhere(
                              (c) => c.id == budget.categoryId,
                              orElse: () => categories.first,
                            );
                            
                            // Calculate consumed based on selected period
                            final consumedCents = transactions
                                .where((t) =>
                                    t.categoryId == budget.categoryId &&
                                    t.type == TransactionType.expense &&
                                    t.dateTime.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
                                    t.dateTime.isBefore(dateRange.end.add(const Duration(seconds: 1))))
                                .fold<int>(0, (sum, t) => sum + t.amountCents);
                            
                            final percentage = budget.limitCents > 0
                                ? (consumedCents / budget.limitCents * 100)
                                : 0.0;
                            final isExceeded = consumedCents > budget.limitCents;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _showBudgetTransactionsWithPeriod(
                                  context, ref, budget, category.name,
                                  dateRange.start, dateRange.end,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Color(category.colorValue).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                category.iconName,
                                                style: const TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  budget.periodType == PeriodType.monthly 
                                                      ? l10n.monthly 
                                                      : l10n.yearly,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isExceeded 
                                              ? Colors.red.withOpacity(0.1) 
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: isExceeded ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (percentage / 100).clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation(
                                        isExceeded ? Colors.red : Color(category.colorValue),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${l10n.spent}: ${CurrencyFormatter.formatVNDFromCents(consumedCents)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '${l10n.limit}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                      },
                      loading: () => const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (err, _) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: $err'),
                        ),
                      ),
                    );
                  },
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (err, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: $err'),
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi: $err'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category Breakdown
            Text(
              reportTypeFilter.value == 2 ? l10n.incomeByCategory : l10n.expenseByCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
                return categoriesAsync.when(
                  data: (categories) {
                    // Filter by transaction type based on reportTypeFilter
                    final transactionTypeFilter = reportTypeFilter.value == 2 
                        ? TransactionType.income 
                        : TransactionType.expense;
                    
                    var filteredTransactions = _filterTransactions(transactions, selectedPeriod.value, customMonth.value, customYear.value)
                        .where((t) => t.type == transactionTypeFilter)
                        .toList();
                    
                    // Also filter by category type if needed
                    if (reportTypeFilter.value == 1) {
                      final expenseCategories = categories.where((c) => c.type == CategoryType.expense).map((c) => c.id).toSet();
                      filteredTransactions = filteredTransactions.where((t) => expenseCategories.contains(t.categoryId)).toList();
                    } else if (reportTypeFilter.value == 2) {
                      final incomeCategories = categories.where((c) => c.type == CategoryType.income).map((c) => c.id).toSet();
                      filteredTransactions = filteredTransactions.where((t) => incomeCategories.contains(t.categoryId)).toList();
                    }
                    
                    if (filteredTransactions.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              reportTypeFilter.value == 2 
                                  ? l10n.noIncomeThisPeriod
                                  : l10n.noExpenseThisPeriod,
                            ),
                          ),
                        ),
                      );
                    }

                    // Group by category
                    final Map<int, int> categoryTotals = {};
                    for (final t in filteredTransactions) {
                      categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0) + t.amountCents;
                    }

                    final totalExpense = filteredTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);

                    final sortedCategories = categoryTotals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: sortedCategories.map((entry) {
                            final category = categories.firstWhere(
                              (c) => c.id == entry.key,
                              orElse: () => categories.first,
                            );
                            final percentage = totalExpense > 0 
                                ? (entry.value / totalExpense * 100).toStringAsFixed(1)
                                : '0';
                            
                            return InkWell(
                              onTap: () => _showCategoryTransactions(
                                context, 
                                ref, 
                                category.id, 
                                category.name, 
                                category.iconName,
                                category.colorValue,
                                selectedPeriod.value,
                                customMonth.value,
                                customYear.value,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Color(category.colorValue),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        category.iconName,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: totalExpense > 0 ? entry.value / totalExpense : 0,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: AlwaysStoppedAnimation(Color(category.colorValue)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatVNDFromCents(entry.value),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '$percentage%',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                                ],
                              ),
                            ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (err, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Lỗi: $err'),
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCustomPeriodPicker(
    BuildContext context, 
    DateTime? currentMonth,
    int? currentYear,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CustomPeriodPickerSheet(
        initialMonth: currentMonth ?? DateTime.now(),
        initialYear: currentYear ?? DateTime.now().year,
      ),
    );
  }

  void _showCategoryTransactions(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
    String categoryName,
    String categoryIcon,
    int categoryColor,
    int selectedPeriod,
    DateTime? customMonth,
    int? customYear,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryTransactionsScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          selectedPeriod: selectedPeriod,
          customMonth: customMonth,
          customYear: customYear,
        ),
      ),
    );
  }

  void _showBudgetTransactionsWithPeriod(
    BuildContext context, 
    WidgetRef ref, 
    Budget budget, 
    String categoryName,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetTransactionsScreen(
          budget: budget.copyWith(periodStart: periodStart, periodEnd: periodEnd),
          categoryName: categoryName,
        ),
      ),
    );
  }

  // Helper to get date range based on selected period
  ({DateTime start, DateTime end}) _getDateRange(int period, DateTime? customMonth, int? customYear) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 0: // This month
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 1: // Custom month
        if (customMonth != null) {
          startDate = DateTime(customMonth.year, customMonth.month, 1);
          endDate = DateTime(customMonth.year, customMonth.month + 1, 0, 23, 59, 59);
        } else {
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        }
        break;
      case 2: // Custom year
        final year = customYear ?? now.year;
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    return (start: startDate, end: endDate);
  }

  List<Transaction> _filterTransactions(
    List<Transaction> transactions, 
    int period, 
    [DateTime? customMonth, int? customYear]
  ) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 0: // Tháng này
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 1: // Tùy chỉnh - Tháng
        if (customMonth != null) {
          startDate = DateTime(customMonth.year, customMonth.month, 1);
          endDate = DateTime(customMonth.year, customMonth.month + 1, 0, 23, 59, 59);
        } else {
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        }
        break;
      case 2: // Tùy chỉnh - Năm
        final year = customYear ?? now.year;
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    return transactions.where((t) =>
      t.dateTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
      t.dateTime.isBefore(endDate.add(const Duration(seconds: 1)))
    ).toList();
  }
}

// Category Transactions Screen
class CategoryTransactionsScreen extends ConsumerWidget {
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final int selectedPeriod;
  final DateTime? customMonth;
  final int? customYear;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.selectedPeriod,
    this.customMonth,
    this.customYear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    
    // Calculate date range based on selected period
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    String periodLabel;

    switch (selectedPeriod) {
      case 0: // This month
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        periodLabel = '${l10n.month} ${now.month}/${now.year}';
        break;
      case 1: // Custom month
        if (customMonth != null) {
          startDate = DateTime(customMonth!.year, customMonth!.month, 1);
          endDate = DateTime(customMonth!.year, customMonth!.month + 1, 0, 23, 59, 59);
          periodLabel = '${l10n.month} ${customMonth!.month}/${customMonth!.year}';
        } else {
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          periodLabel = '${l10n.month} ${now.month}/${now.year}';
        }
        break;
      case 2: // Custom year
        final year = customYear ?? now.year;
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59);
        periodLabel = '${l10n.year} $year';
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        periodLabel = '${l10n.month} ${now.month}/${now.year}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(categoryColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(categoryIcon, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoryName, style: const TextStyle(fontSize: 16)),
                  Text(periodLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // Filter transactions by category and period
          final categoryTransactions = transactions.where((t) {
            return t.categoryId == categoryId &&
                t.type == TransactionType.expense &&
                t.dateTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                t.dateTime.isBefore(endDate.add(const Duration(seconds: 1)));
          }).toList();

          if (categoryTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(l10n.noTransactions),
                ],
              ),
            );
          }

          // Calculate total
          final totalAmount = categoryTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);

          // Group by date
          final Map<DateTime, List<Transaction>> groupedByDate = {};
          for (final t in categoryTransactions) {
            final date = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
            if (!groupedByDate.containsKey(date)) {
              groupedByDate[date] = [];
            }
            groupedByDate[date]!.add(t);
          }

          final sortedDates = groupedByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              // Total summary card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(categoryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(categoryColor).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.totalExpense,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatVNDFromCents(totalAmount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(categoryColor),
                      ),
                    ),
                    Text(
                      '${categoryTransactions.length} ${l10n.transactionsCount}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Transactions list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final dayTransactions = groupedByDate[date]!;
                    final dayTotal = dayTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(categoryColor).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${CurrencyFormatter.formatVNDFromCents(dayTotal)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(categoryColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Transactions
                          ...dayTransactions.map((t) => ListTile(
                            title: Text(t.note ?? l10n.noNote),
                            trailing: Text(
                              '-${CurrencyFormatter.formatVNDFromCents(t.amountCents)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
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
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}

// Budget Transactions Screen
class BudgetTransactionsScreen extends ConsumerWidget {
  final Budget budget;
  final String categoryName;

  const BudgetTransactionsScreen({
    super.key,
    required this.budget,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.transactions}: $categoryName'),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // Filter transactions by category and budget period
          final budgetTransactions = transactions.where((t) {
            return t.categoryId == budget.categoryId &&
                t.type == TransactionType.expense &&
                t.dateTime.isAfter(budget.periodStart.subtract(const Duration(days: 1))) &&
                t.dateTime.isBefore(budget.periodEnd.add(const Duration(days: 1)));
          }).toList();

          if (budgetTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(l10n.noTransactions),
                ],
              ),
            );
          }

          // Group by date
          final Map<DateTime, List<Transaction>> groupedByDate = {};
          for (final t in budgetTransactions) {
            final date = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
            if (!groupedByDate.containsKey(date)) {
              groupedByDate[date] = [];
            }
            groupedByDate[date]!.add(t);
          }

          final sortedDates = groupedByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayTransactions = groupedByDate[date]!;
              final dayTotal = dayTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header with distinct color for daily total
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${CurrencyFormatter.formatVNDFromCents(dayTotal)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Transactions
                    ...dayTransactions.map((t) => ListTile(
                      title: Text(t.note ?? l10n.noNote),
                      trailing: Text(
                        '-${CurrencyFormatter.formatVNDFromCents(t.amountCents)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
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
        error: (err, _) => Center(child: Text('${l10n.error}: $err')),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.formatVNDFromCents(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _CustomPeriodPickerSheet extends HookWidget {
  final DateTime initialMonth;
  final int initialYear;

  const _CustomPeriodPickerSheet({
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedTab = useState(0); // 0: By month, 1: By year
    final selectedYear = useState(initialMonth.year);
    final now = DateTime.now();
    final years = List.generate(10, (i) => now.year - 5 + i);
    final months = [
      '${l10n.month} 1', '${l10n.month} 2', '${l10n.month} 3', '${l10n.month} 4',
      '${l10n.month} 5', '${l10n.month} 6', '${l10n.month} 7', '${l10n.month} 8',
      '${l10n.month} 9', '${l10n.month} 10', '${l10n.month} 11', '${l10n.month} 12',
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.selectPeriod,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tab: By month / By year
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectedTab.value = 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedTab.value == 0 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          l10n.byMonth,
                          style: TextStyle(
                            color: selectedTab.value == 0 ? Colors.white : Colors.grey[700],
                            fontWeight: selectedTab.value == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectedTab.value = 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedTab.value == 1 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          l10n.byYear,
                          style: TextStyle(
                            color: selectedTab.value == 1 ? Colors.white : Colors.grey[700],
                            fontWeight: selectedTab.value == 1 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          if (selectedTab.value == 0) ...[
            // By month: Year selector
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  final isSelected = year == selectedYear.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(year.toString()),
                      selected: isSelected,
                      onSelected: (_) => selectedYear.value = year,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Month grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthNum = index + 1;
                  final isCurrentSelection = 
                      selectedYear.value == initialMonth.year && 
                      monthNum == initialMonth.month;
                  final isCurrentMonth = 
                      selectedYear.value == now.year && 
                      monthNum == now.month;
                  
                  return Material(
                    color: isCurrentSelection
                        ? Theme.of(context).colorScheme.primary
                        : isCurrentMonth
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, {
                        'type': 'month',
                        'value': DateTime(selectedYear.value, monthNum),
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          months[index],
                          style: TextStyle(
                            color: isCurrentSelection ? Colors.white : null,
                            fontWeight: isCurrentSelection || isCurrentMonth ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // Theo năm: Year grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  final isCurrentSelection = year == initialYear;
                  final isCurrentYear = year == now.year;
                  
                  return Material(
                    color: isCurrentSelection
                        ? Theme.of(context).colorScheme.primary
                        : isCurrentYear
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, {
                        'type': 'year',
                        'value': year,
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            color: isCurrentSelection ? Colors.white : null,
                            fontWeight: isCurrentSelection || isCurrentYear ? FontWeight.bold : null,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _ReportTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
