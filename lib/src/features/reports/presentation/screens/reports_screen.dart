import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/chart_widget.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class ReportsScreen extends HookConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final selectedPeriod =
        useState(0); // 0: Tháng này, 1: Tùy chỉnh (tháng), 2: Tùy chỉnh (năm)
    final customMonth = useState<DateTime?>(null);
    final customYear = useState<int?>(null);
    final reportTypeFilter = useState(0); // 0: All, 1: Expense, 2: Income

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => syncCurrentWorkspaceData(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              AppCard(
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
                              isSelected: selectedPeriod.value == 1 ||
                                  selectedPeriod.value == 2,
                              onTap: () async {
                                final result = await _showCustomPeriodPicker(
                                  context,
                                  customMonth.value,
                                  customYear.value,
                                );
                                if (result != null) {
                                  if (result['type'] == 'month') {
                                    customMonth.value =
                                        result['value'] as DateTime;
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
                      if (selectedPeriod.value == 1 &&
                          customMonth.value != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '${l10n.month} ${customMonth.value!.month}/${customMonth.value!.year}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                      if (selectedPeriod.value == 2 &&
                          customYear.value != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '${l10n.year} ${customYear.value}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ),

              const SizedBox(height: 16),

              // Summary Card
              transactionsAsync.when(
                data: (transactions) {
                  final filteredTransactions = _filterTransactions(
                    transactions,
                    selectedPeriod.value,
                    monthStartDay,
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2-up summary cards: Tổng chi / Tổng thu
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryStatCard(
                              label: l10n.totalExpense,
                              amount: totalExpense,
                              color: AppColors.expense,
                              icon: Icons.arrow_upward,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _SummaryStatCard(
                              label: l10n.totalIncome,
                              amount: totalIncome,
                              color: AppColors.income,
                              icon: Icons.arrow_downward,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  balance >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: balance >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.balance,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.formatVNDFromCents(
                                balance,
                                locale: l10n.localeName,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: balance >= 0
                                        ? AppColors.income
                                        : AppColors.expense,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '${l10n.transactionCount}: ${filteredTransactions.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
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
                    child: Text(l10n.errorWithMessage('$err')),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6-month expense trend
              transactionsAsync.when(
                data: (transactions) {
                  final monthlyData =
                      _buildLastSixMonthsExpense(transactions);
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalExpense,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        BarChartWidget(
                          data: monthlyData,
                          labelFormatter: _formatCompactAmount,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Type Filter for Reports
              AppCard(
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
                          color: AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReportTypeButton(
                          label: l10n.income,
                          isSelected: reportTypeFilter.value == 2,
                          onTap: () => reportTypeFilter.value = 2,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
              ),

              const SizedBox(height: 16),

              // Budget Reports Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.budgetReports,
                    style: Theme.of(context).textTheme.headlineSmall,
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
                              Icon(Icons.pie_chart_outline,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 8),
                              Text(l10n.noBudgets),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/budget-edit'),
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
                          final dateRange = _getDateRange(
                              selectedPeriod.value,
                              customMonth.value,
                              customYear.value,
                              monthStartDay);

                          // Filter budgets based on category type
                          final categoryMap = {
                            for (var c in categories) c.id: c
                          };
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
                                      t.dateTime.isAfter(dateRange.start
                                          .subtract(
                                              const Duration(seconds: 1))) &&
                                      t.dateTime.isBefore(dateRange.end
                                          .add(const Duration(seconds: 1))))
                                  .fold<int>(
                                      0, (sum, t) => sum + t.amountCents);

                              final percentage = budget.limitCents > 0
                                  ? (consumedCents / budget.limitCents * 100)
                                  : 0.0;
                              final isExceeded =
                                  consumedCents > budget.limitCents;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: AppCard(
                                  onTap: () =>
                                      _showBudgetTransactionsWithPeriod(
                                    context,
                                    ref,
                                    budget,
                                    category.name,
                                    dateRange.start,
                                    dateRange.end,
                                  ),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: getCategoryColor(
                                                        category.colorValue)
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppSpacing.radiusMd),
                                              ),
                                              child: Center(
                                                child: CategoryIconWidget(
                                                  iconName: category.iconName,
                                                  size: 18,
                                                  color: getCategoryColor(
                                                      category.colorValue),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                  Text(
                                                    budget.periodType ==
                                                            PeriodType.monthly
                                                        ? l10n.monthly
                                                        : l10n.yearly,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isExceeded
                                                    ? AppColors.expense
                                                        .withValues(alpha: 0.1)
                                                    : AppColors.income
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppSpacing.radiusFull),
                                              ),
                                              child: Text(
                                                '${percentage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  color: isExceeded
                                                      ? AppColors.expense
                                                      : AppColors.income,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusFull),
                                          child: LinearProgressIndicator(
                                            value: (percentage / 100)
                                                .clamp(0.0, 1.0),
                                            minHeight: 8,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            valueColor: AlwaysStoppedAnimation(
                                              isExceeded
                                                  ? AppColors.expense
                                                  : getCategoryColor(
                                                      category.colorValue),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${CurrencyFormatter.formatVNDFromCents(consumedCents, locale: l10n.localeName)} / ${CurrencyFormatter.formatVNDFromCents(budget.limitCents, locale: l10n.localeName)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                '${l10n.remaining}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - consumedCents, locale: l10n.localeName)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: isExceeded
                                                          ? AppColors.expense
                                                          : AppColors.income,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                            child: Text(l10n.errorWithMessage('$err')),
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
                        child: Text(l10n.errorWithMessage('$err')),
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
                    child: Text(l10n.errorWithMessage('$err')),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category Breakdown
              Text(
                reportTypeFilter.value == 2
                    ? l10n.incomeByCategory
                    : l10n.expenseByCategory,
                style: Theme.of(context).textTheme.headlineSmall,
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

                      var filteredTransactions = _filterTransactions(
                              transactions,
                              selectedPeriod.value,
                              monthStartDay,
                              customMonth.value,
                              customYear.value)
                          .where((t) => t.type == transactionTypeFilter)
                          .toList();

                      // Also filter by category type if needed
                      if (reportTypeFilter.value == 1) {
                        final expenseCategories = categories
                            .where((c) => c.type == CategoryType.expense)
                            .map((c) => c.id)
                            .toSet();
                        filteredTransactions = filteredTransactions
                            .where(
                                (t) => expenseCategories.contains(t.categoryId))
                            .toList();
                      } else if (reportTypeFilter.value == 2) {
                        final incomeCategories = categories
                            .where((c) => c.type == CategoryType.income)
                            .map((c) => c.id)
                            .toSet();
                        filteredTransactions = filteredTransactions
                            .where(
                                (t) => incomeCategories.contains(t.categoryId))
                            .toList();
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
                      final Map<String, int> categoryTotals = {};
                      for (final t in filteredTransactions) {
                        // Transfers carry no category and never reach here.
                        final categoryId = t.categoryId;
                        if (categoryId == null) {
                          continue;
                        }
                        categoryTotals[categoryId] =
                            (categoryTotals[categoryId] ?? 0) + t.amountCents;
                      }

                      final totalExpense = filteredTransactions.fold<int>(
                          0, (sum, t) => sum + t.amountCents);

                      final sortedCategories = categoryTotals.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      final pieData = sortedCategories.map((entry) {
                        final category = categories.firstWhere(
                          (c) => c.id == entry.key,
                          orElse: () => categories.first,
                        );
                        final percentage = totalExpense > 0
                            ? (entry.value / totalExpense * 100)
                            : 0.0;
                        return ChartData(
                          label: category.name,
                          value: entry.value.toDouble(),
                          percentage: percentage,
                          color: getCategoryColor(category.colorValue),
                        );
                      }).toList();

                      return Column(
                        children: [
                          AppCard(
                            child: PieChartWidget(data: pieData),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            child: Column(
                            children: sortedCategories.map((entry) {
                              final category = categories.firstWhere(
                                (c) => c.id == entry.key,
                                orElse: () => categories.first,
                              );
                              final percentage = totalExpense > 0
                                  ? (entry.value / totalExpense * 100)
                                      .toStringAsFixed(1)
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
                                  reportTypeFilter.value == 2, // isIncomeReport
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: getCategoryColor(
                                              category.colorValue),
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusSm),
                                        ),
                                        child: Center(
                                          child: CategoryIconWidget(
                                            iconName: category.iconName,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              category.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500),
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(
                                                  AppSpacing.radiusFull),
                                              child: LinearProgressIndicator(
                                                value: totalExpense > 0
                                                    ? entry.value / totalExpense
                                                    : 0,
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        getCategoryColor(
                                                            category
                                                                .colorValue)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            CurrencyFormatter
                                                .formatVNDFromCents(entry.value,
                                                    locale: l10n.localeName),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Text(
                                            '$percentage%',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.3),
                                          size: 20),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            ),
                          ),
                        ],
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
                        child: Text(l10n.errorWithMessage('$err')),
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
                    child: Text(l10n.errorWithMessage('$err')),
                  ),
                ),
              ),
            ],
          ),
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
    String categoryId,
    String categoryName,
    String categoryIcon,
    int categoryColor,
    int selectedPeriod,
    DateTime? customMonth,
    int? customYear,
    bool isIncomeReport,
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
          isIncomeReport: isIncomeReport,
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
          budget:
              budget.copyWith(periodStart: periodStart, periodEnd: periodEnd),
          categoryName: categoryName,
        ),
      ),
    );
  }

  // Helper to get date range based on selected period
  ({DateTime start, DateTime end}) _getDateRange(
      int period, DateTime? customMonth, int? customYear, int monthStartDay) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 0: // This month - use cycle dates based on monthStartDay
        final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
        startDate = cycleRange.start;
        endDate = cycleRange.end;
        break;
      case 1: // Custom month - use cycle dates
        if (customMonth != null) {
          final cycleRange =
              CycleUtils.getCycleRangeForDate(customMonth, monthStartDay);
          startDate = cycleRange.start;
          endDate = cycleRange.end;
        } else {
          final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
          startDate = cycleRange.start;
          endDate = cycleRange.end;
        }
        break;
      case 2: // Custom year
        final year = customYear ?? now.year;
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59);
        break;
      default:
        final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
        startDate = cycleRange.start;
        endDate = cycleRange.end;
    }

    return (start: startDate, end: endDate);
  }

  List<Transaction> _filterTransactions(
      List<Transaction> transactions, int period, int monthStartDay,
      [DateTime? customMonth, int? customYear]) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 0: // Tháng này - use cycle dates
        final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
        startDate = cycleRange.start;
        endDate = cycleRange.end;
        break;
      case 1: // Tùy chỉnh - Tháng - use cycle dates
        if (customMonth != null) {
          final cycleRange =
              CycleUtils.getCycleRangeForDate(customMonth, monthStartDay);
          startDate = cycleRange.start;
          endDate = cycleRange.end;
        } else {
          final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
          startDate = cycleRange.start;
          endDate = cycleRange.end;
        }
        break;
      case 2: // Tùy chỉnh - Năm
        final year = customYear ?? now.year;
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59);
        break;
      default:
        final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
        startDate = cycleRange.start;
        endDate = cycleRange.end;
    }

    return transactions
        .where((t) =>
            t.dateTime
                .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            t.dateTime.isBefore(endDate.add(const Duration(seconds: 1))))
        .toList();
  }

  List<ChartData> _buildLastSixMonthsExpense(List<Transaction> transactions) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );

    return months.map((month) {
      final total = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.dateTime.year == month.year &&
              t.dateTime.month == month.month)
          .fold<double>(0, (sum, t) => sum + t.amountCents);
      final isCurrentMonth =
          month.year == now.year && month.month == now.month;
      return ChartData(
        label: 'T${month.month}',
        value: total,
        color: isCurrentMonth ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
      );
    }).toList();
  }

  String _formatCompactAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}tr';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}

// Category Transactions Screen
class CategoryTransactionsScreen extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final int selectedPeriod;
  final DateTime? customMonth;
  final int? customYear;
  final bool isIncomeReport;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.selectedPeriod,
    this.customMonth,
    this.customYear,
    this.isIncomeReport = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);

    // Calculate date range based on selected period using cycle dates
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    String periodLabel;

    switch (selectedPeriod) {
      case 0: // This month - use cycle dates based on monthStartDay
        final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
        startDate = cycleRange.start;
        endDate = cycleRange.end;
        periodLabel = '${l10n.month} ${now.month}/${now.year}';
        break;
      case 1: // Custom month - use cycle dates
        if (customMonth != null) {
          final cycleRange =
              CycleUtils.getCycleRangeForDate(customMonth!, monthStartDay);
          startDate = cycleRange.start;
          endDate = cycleRange.end;
          periodLabel =
              '${l10n.month} ${customMonth!.month}/${customMonth!.year}';
        } else {
          final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
          startDate = cycleRange.start;
          endDate = cycleRange.end;
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
        final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
        startDate = cycleRange.start;
        endDate = cycleRange.end;
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
                color: Color(categoryColor).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                  Text(categoryName,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(periodLabel,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // Filter transactions by category and period
          // Filter by transaction type based on report type
          final expectedType =
              isIncomeReport ? TransactionType.income : TransactionType.expense;
          final categoryTransactions = transactions.where((t) {
            return t.categoryId == categoryId &&
                t.type == expectedType &&
                t.dateTime
                    .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                t.dateTime.isBefore(endDate.add(const Duration(seconds: 1)));
          }).toList();

          if (categoryTransactions.isEmpty) {
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
                  const SizedBox(height: 16),
                  Text(l10n.noTransactions),
                ],
              ),
            );
          }

          // Calculate total
          final totalAmount = categoryTransactions.fold<int>(
              0, (sum, t) => sum + t.amountCents);

          // Group by date
          final Map<DateTime, List<Transaction>> groupedByDate = {};
          for (final t in categoryTransactions) {
            final date =
                DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
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
                  color: Color(categoryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: Color(categoryColor).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      isIncomeReport ? l10n.totalIncome : l10n.totalExpense,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatVNDFromCents(totalAmount,
                          locale: l10n.localeName),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Color(categoryColor)),
                    ),
                    Text(
                      '${categoryTransactions.length} ${l10n.transactionsCount}',
                      style: Theme.of(context).textTheme.bodySmall,
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
                    final dayTotal = dayTransactions.fold<int>(
                        0, (sum, t) => sum + t.amountCents);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppSpacing.radiusMd)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatLocalizedDate(context, date),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(categoryColor)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    '${isIncomeReport ? "+" : "-"}${CurrencyFormatter.formatVNDFromCents(dayTotal, locale: l10n.localeName)}',
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
                                  '${isIncomeReport ? "+" : "-"}${CurrencyFormatter.formatVNDFromCents(t.amountCents, locale: l10n.localeName)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isIncomeReport
                                        ? AppColors.income
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
        error: (err, _) => Center(child: Text(l10n.errorWithMessage('$err'))),
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
        title: Text(categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
      body: transactionsAsync.when(
        data: (transactions) {
          // Filter transactions by category and budget period
          final budgetTransactions = transactions.where((t) {
            return t.categoryId == budget.categoryId &&
                t.type == TransactionType.expense &&
                t.dateTime.isAfter(
                    budget.periodStart.subtract(const Duration(seconds: 1))) &&
                t.dateTime
                    .isBefore(budget.periodEnd.add(const Duration(seconds: 1)));
          }).toList();

          // Calculate consumed amount from filtered transactions
          final consumedCents =
              budgetTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);
          final percentage = budget.limitCents > 0
              ? (consumedCents / budget.limitCents * 100)
              : 0.0;
          final isExceeded = consumedCents > budget.limitCents;

          return Column(
            children: [
              // Budget summary header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.spent,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              CurrencyFormatter.formatVNDFromCents(
                                  consumedCents,
                                  locale: l10n.localeName),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isExceeded
                                ? AppColors.expense.withValues(alpha: 0.1)
                                : AppColors.income.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isExceeded
                                  ? AppColors.expense
                                  : AppColors.income,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      child: LinearProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          isExceeded
                              ? AppColors.expense
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n.limit}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents, locale: l10n.localeName)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${l10n.remaining}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents - consumedCents, locale: l10n.localeName)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isExceeded
                                    ? AppColors.expense
                                    : AppColors.income,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transactions list
              Expanded(
                child: budgetTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(l10n.noTransactions),
                          ],
                        ),
                      )
                    : _buildTransactionsList(
                        context, ref, budgetTransactions, l10n),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorWithMessage('$err'))),
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    WidgetRef ref,
    List<Transaction> budgetTransactions,
    AppLocalizations l10n,
  ) {
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
        final dayTotal =
            dayTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header with weekday and daily total
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusMd)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(context, date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '-${CurrencyFormatter.formatVNDFromCents(dayTotal, locale: l10n.localeName)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Transactions with icon and time
              ...dayTransactions.map((t) => ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: AppColors.expense,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      t.note ?? l10n.noNote,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      formatLocalizedTime(context, t.dateTime),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '-${CurrencyFormatter.formatVNDFromCents(t.amountCents, locale: l10n.localeName)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
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
  }

  String _formatDate(BuildContext context, DateTime date) {
    return formatLocalizedDateWithWeekday(context, date);
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
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _SummaryStatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyFormatter.formatVNDFromCents(
              amount,
              locale: localeNameOf(context),
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
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
      '${l10n.month} 1',
      '${l10n.month} 2',
      '${l10n.month} 3',
      '${l10n.month} 4',
      '${l10n.month} 5',
      '${l10n.month} 6',
      '${l10n.month} 7',
      '${l10n.month} 8',
      '${l10n.month} 9',
      '${l10n.month} 10',
      '${l10n.month} 11',
      '${l10n.month} 12',
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Center(
                        child: Text(
                          l10n.byMonth,
                          style: TextStyle(
                            color: selectedTab.value == 0
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: selectedTab.value == 0
                                ? FontWeight.w600
                                : FontWeight.normal,
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
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Center(
                        child: Text(
                          l10n.byYear,
                          style: TextStyle(
                            color: selectedTab.value == 1
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: selectedTab.value == 1
                                ? FontWeight.w600
                                : FontWeight.normal,
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
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).textTheme.bodyLarge?.color,
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
                      selectedYear.value == now.year && monthNum == now.month;

                  return Material(
                    color: isCurrentSelection
                        ? Theme.of(context).colorScheme.primary
                        : isCurrentMonth
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, {
                        'type': 'month',
                        'value': DateTime(selectedYear.value, monthNum),
                      }),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Center(
                        child: Text(
                          months[index],
                          style: TextStyle(
                            color: isCurrentSelection
                                ? Theme.of(context).colorScheme.onPrimary
                                : (isCurrentMonth
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                            fontWeight: isCurrentSelection || isCurrentMonth
                                ? FontWeight.bold
                                : null,
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
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, {
                        'type': 'year',
                        'value': year,
                      }),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Center(
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            color: isCurrentSelection
                                ? Theme.of(context).colorScheme.onPrimary
                                : (isCurrentYear
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                            fontWeight: isCurrentSelection || isCurrentYear
                                ? FontWeight.bold
                                : null,
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
          color: isSelected
              ? selectedColor
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
