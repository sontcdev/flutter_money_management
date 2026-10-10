import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/models/uncategorized_category.dart';
import 'package:flutter_money_management/src/features/reports/models/report_period.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/chart_widget.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/report_sections.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_segmented_filter.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

Widget _buildReportsLoadError(
  AppLocalizations l10n, {
  required VoidCallback onRetry,
}) {
  return LoadErrorState(
    title: l10n.dataLoadFailed,
    message: l10n.dataLoadFailedHint,
    retryLabel: l10n.retry,
    onRetry: onRetry,
    compact: true,
  );
}

class ReportsScreen extends HookConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final period = useState(ReportPeriod.current(ReportPeriodUnit.month));
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
              ReportPeriodSelector(
                period: period.value,
                monthStartDay: monthStartDay,
                onChanged: (value) => period.value = value,
                onPickPeriod: () async {
                  final current = period.value;
                  final result = await _showCustomPeriodPicker(
                    context,
                    current.range(monthStartDay).end,
                    current.anchor.year,
                  );
                  if (result == null) return;
                  period.value = result['type'] == 'month'
                      ? ReportPeriod(
                          ReportPeriodUnit.month,
                          result['value'] as DateTime,
                        )
                      : ReportPeriod(
                          ReportPeriodUnit.year,
                          DateTime(result['value'] as int),
                        );
                },
              ),

              const SizedBox(height: 16),

              // Summary Card
              transactionsAsync.when(
                data: (transactions) {
                  final current = transactions
                      .where((t) =>
                          period.value.contains(t.dateTime, monthStartDay))
                      .toList();
                  final previousPeriod = period.value.previous(monthStartDay);
                  final previous = transactions
                      .where((t) =>
                          previousPeriod.contains(t.dateTime, monthStartDay))
                      .toList();
                  int total(List<Transaction> items, TransactionType type) =>
                      items
                          .where((t) => t.type == type)
                          .fold<int>(0, (sum, t) => sum + t.amountCents);
                  return ReportSummarySection(
                    totalIncome: total(current, TransactionType.income),
                    totalExpense: total(current, TransactionType.expense),
                    previousIncome: total(previous, TransactionType.income),
                    previousExpense: total(previous, TransactionType.expense),
                    transactionCount: current.length,
                  );
                },
                loading: () => const SectionSkeleton(height: 180),
                error: (err, _) => AppCard(
                  child: _buildReportsLoadError(
                    l10n,
                    onRetry: () => ref.invalidate(transactionsProvider),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6-month expense trend
              transactionsAsync.when(
                data: (transactions) => ReportTrendSection(
                  data: _buildLastSixMonthsExpense(
                    transactions,
                    l10n.localeName,
                  ),
                ),
                loading: () => const SectionSkeleton(height: 220),
                error: (err, _) => InlineLoadErrorState(
                  onRetry: () => ref.invalidate(transactionsProvider),
                ),
              ),

              const SizedBox(height: 16),

              const ReportCalendarEntryCard(),

              const SizedBox(height: 16),

              // Type Filter for Reports
              AppSegmentedFilter<int>(
                padding: EdgeInsets.zero,
                selectedValue: reportTypeFilter.value,
                onChanged: (value) => reportTypeFilter.value = value,
                options: [
                  FilterOption(label: l10n.all, value: 0),
                  FilterOption(
                    label: l10n.expense,
                    value: 1,
                    color: context.semanticColors.expense,
                  ),
                  FilterOption(
                    label: l10n.income,
                    value: 2,
                    color: context.semanticColors.income,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Budget Reports Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.budgetReports,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
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
                    return AppCard(
                      child: EmptyState.compact(
                        icon: Icons.pie_chart_outline,
                        title: l10n.noBudgets,
                        message: '',
                        actionLabel: l10n.addBudget,
                        onAction: () =>
                            Navigator.pushNamed(context, '/budget-edit'),
                      ),
                    );
                  }

                  return categoriesAsync.when(
                    data: (categories) {
                      return transactionsAsync.when(
                        data: (transactions) {
                          // Get date range based on selected period
                          final dateRange =
                              period.value.range(monthStartDay);

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
                            return AppCard(
                              child: Center(
                                child: Text(
                                  reportTypeFilter.value == 1
                                      ? l10n.noExpenseBudgets
                                      : reportTypeFilter.value == 2
                                          ? l10n.noIncomeBudgets
                                          : l10n.noBudgets,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: filteredBudgets.map((budget) {
                              final category = categories.firstWhere(
                                (c) => c.id == budget.categoryId,
                                orElse: () => uncategorizedCategory(
                                  budget.categoryId,
                                  l10n.uncategorized,
                                ),
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

                              return _BudgetReportCard(
                                budget: budget,
                                category: category,
                                consumedCents: consumedCents,
                                onTap: () =>
                                    _showBudgetTransactionsWithPeriod(
                                  context,
                                  ref,
                                  budget,
                                  category.name,
                                  dateRange.start,
                                  dateRange.end,
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const SectionSkeleton(height: 160),
                        error: (err, _) => AppCard(
                          child: _buildReportsLoadError(
                            l10n,
                            onRetry: () => ref.invalidate(transactionsProvider),
                          ),
                        ),
                      );
                    },
                    loading: () => const SectionSkeleton(height: 160),
                    error: (err, _) => AppCard(
                      child: _buildReportsLoadError(
                        l10n,
                        onRetry: () => ref.invalidate(categoriesProvider),
                      ),
                    ),
                  );
                },
                loading: () => const SectionSkeleton(height: 160),
                error: (err, _) => AppCard(
                  child: _buildReportsLoadError(
                    l10n,
                    onRetry: () => ref.invalidate(budgetsProvider),
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

                      var filteredTransactions = transactions
                          .where((t) =>
                              t.type == transactionTypeFilter &&
                              period.value.contains(t.dateTime, monthStartDay))
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
                        return AppCard(
                          child: Center(
                            child: Text(
                              reportTypeFilter.value == 2
                                  ? l10n.noIncomeThisPeriod
                                  : l10n.noExpenseThisPeriod,
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
                          orElse: () => uncategorizedCategory(
                            entry.key,
                            l10n.uncategorized,
                          ),
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
                                  orElse: () => uncategorizedCategory(
                                    entry.key,
                                    l10n.uncategorized,
                                  ),
                                );
                                return _CategoryBreakdownRow(
                                  category: category,
                                  amountCents: entry.value,
                                  totalCents: totalExpense,
                                  onTap: () => _showCategoryTransactions(
                                    context,
                                    category.id,
                                    category.name,
                                    category.iconName,
                                    category.colorValue,
                                    period.value.range(monthStartDay),
                                    period.value.label(l10n, monthStartDay),
                                    reportTypeFilter.value ==
                                        2, // isIncomeReport
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SectionSkeleton(height: 160),
                    error: (err, _) => AppCard(
                      child: _buildReportsLoadError(
                        l10n,
                        onRetry: () => ref.invalidate(categoriesProvider),
                      ),
                    ),
                  );
                },
                loading: () => const SectionSkeleton(height: 160),
                error: (err, _) => AppCard(
                  child: _buildReportsLoadError(
                    l10n,
                    onRetry: () => ref.invalidate(transactionsProvider),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (context) => _CustomPeriodPickerSheet(
        initialMonth: currentMonth ?? DateTime.now(),
        initialYear: currentYear ?? DateTime.now().year,
      ),
    );
  }

  void _showCategoryTransactions(
    BuildContext context,
    String categoryId,
    String categoryName,
    String categoryIcon,
    int categoryColor,
    ReportDateRange range,
    String periodLabel,
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
          startDate: range.start,
          endDate: range.end,
          periodLabel: periodLabel,
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

  List<ChartData> _buildLastSixMonthsExpense(
    List<Transaction> transactions,
    String locale,
  ) {
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
          .fold<double>(0, (sum, t) => sum + t.amountCents / 100);
      final isCurrentMonth = month.year == now.year && month.month == now.month;
      return ChartData(
        label: DateFormat.MMM(locale).format(month),
        value: total,
        color: isCurrentMonth
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.35),
      );
    }).toList();
  }
}

class _BudgetReportCard extends StatelessWidget {
  const _BudgetReportCard({
    required this.budget,
    required this.category,
    required this.consumedCents,
    required this.onTap,
  });

  final Budget budget;
  final Category category;
  final int consumedCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percentage = budget.limitCents > 0
        ? (consumedCents / budget.limitCents * 100)
        : 0.0;
    final isExceeded = consumedCents > budget.limitCents;
    String format(int cents) => CurrencyFormatter.formatVNDFromCents(
          cents,
          locale: l10n.localeName,
        );

    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
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
                            AppSpacing.radiusCard),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExceeded
                        ? context.semanticColors.expense
                            .withValues(alpha: 0.1)
                        : context.semanticColors.income
                            .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(
                            AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isExceeded
                          ? context.semanticColors.expense
                          : context.semanticColors.income,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
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
                            ? context.semanticColors.expense
                            : getCategoryColor(
                                category.colorValue),
                      ),
                    ),
                  ),
                ),
                if (isExceeded) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.warning_amber_rounded,
                    size: AppSpacing.iconSizeSm,
                    color: context.semanticColors.expense,
                    semanticLabel: l10n.exceeded,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${format(consumedCents)} / ${format(budget.limitCents)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${l10n.remaining}: '
                    '${format(budget.limitCents - consumedCents)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: isExceeded
                              ? context.semanticColors.expense
                              : context.semanticColors.income,
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
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.category,
    required this.amountCents,
    required this.totalCents,
    required this.onTap,
  });

  final Category category;
  final int amountCents;
  final int totalCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percentage = totalCents > 0
        ? (amountCents / totalCents * 100).toStringAsFixed(1)
        : '0';
    final iconColor = ThemeData.estimateBrightnessForColor(
              getCategoryColor(category.colorValue),
            ) ==
            Brightness.dark
        ? AppColors.textLight
        : AppColors.textDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
          AppSpacing.radiusCard),
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
                    AppSpacing.radiusCard),
              ),
              child: Center(
                child: CategoryIconWidget(
                  iconName: category.iconName,
                  size: AppSpacing.iconSizeXs,
                  color: iconColor,
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
                    borderRadius:
                        BorderRadius.circular(
                            AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: totalCents > 0
                          ? amountCents /
                              totalCents
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
                      .formatVNDFromCents(
                          amountCents,
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
  }
}

// Category Transactions Screen
class CategoryTransactionsScreen extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;
  final bool isIncomeReport;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
    this.isIncomeReport = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(categoryColor).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Center(
                child: Text(
                  categoryIcon,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
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

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.zero,
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
                                  top: Radius.circular(AppSpacing.radiusCard)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatLocalizedDate(context, date),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(categoryColor)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusCard),
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
                                        ? context.semanticColors.income
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
        error: (err, _) => _buildReportsLoadError(
          l10n,
          onRetry: () => ref.invalidate(transactionsProvider),
        ),
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
            tooltip: l10n.editCategory,
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
                                ? context.semanticColors.expense
                                    .withValues(alpha: 0.1)
                                : context.semanticColors.income
                                    .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: isExceeded
                                  ? context.semanticColors.expense
                                  : context.semanticColors.income,
                              fontWeight: FontWeight.bold,
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
                              ? context.semanticColors.expense
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isExceeded
                                        ? context.semanticColors.expense
                                        : context.semanticColors.income,
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
        error: (err, _) => _buildReportsLoadError(
          l10n,
          onRetry: () => ref.invalidate(transactionsProvider),
        ),
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

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header with weekday and daily total
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusCard)),
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
                            BorderRadius.circular(AppSpacing.radiusCard),
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
                        color: context.semanticColors.expense
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusCard),
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: context.semanticColors.expense,
                        size: AppSpacing.iconSizeSm,
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
    final months = List.generate(
      12,
      (i) => DateFormat.MMMM(l10n.localeName).format(DateTime(2000, i + 1)),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  tooltip: l10n.close,
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusCard),
                        ),
                        child: Center(
                          child: Text(
                            l10n.byMonth,
                            style: TextStyle(
                              color: selectedTab.value == 0
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusCard),
                        ),
                        child: Center(
                          child: Text(
                            l10n.byYear,
                            style: TextStyle(
                              color: selectedTab.value == 1
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, {
                        'type': 'month',
                        'value': DateTime(selectedYear.value, monthNum),
                      }),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
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
            ] else ...[
              // Theo năm: Year grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, {
                        'type': 'year',
                        'value': year,
                      }),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                      child: Center(
                        child: Text(
                          year.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
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
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
