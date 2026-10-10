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

part 'reports_screen_sections.dart';
part 'reports_screen_sections_2.dart';
part 'reports_screen_sections_3.dart';

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
                onPickPeriod: () =>
                    _pickPeriod(context, period, monthStartDay),
              ),

              const SizedBox(height: 16),

              // Summary Card
              _ReportSummaryCard(
                transactionsAsync: transactionsAsync,
                period: period.value,
                monthStartDay: monthStartDay,
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
              _BudgetReportsSection(
                budgetsAsync: budgetsAsync,
                categoriesAsync: categoriesAsync,
                transactionsAsync: transactionsAsync,
                period: period.value,
                monthStartDay: monthStartDay,
                reportTypeFilter: reportTypeFilter.value,
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
              _CategoryBreakdownSection(
                transactionsAsync: transactionsAsync,
                categoriesAsync: categoriesAsync,
                period: period.value,
                monthStartDay: monthStartDay,
                reportTypeFilter: reportTypeFilter.value,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPeriod(
    BuildContext context,
    ValueNotifier<ReportPeriod> period,
    int monthStartDay,
  ) async {
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
              _CategoryTotalCard(
                categoryTransactions: categoryTransactions,
                totalAmount: totalAmount,
                categoryColor: categoryColor,
                isIncomeReport: isIncomeReport,
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

                    return _CategoryDayCard(
                      date: date,
                      dayTransactions: dayTransactions,
                      dayTotal: dayTotal,
                      categoryColor: categoryColor,
                      isIncomeReport: isIncomeReport,
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
              _BudgetSummaryHeader(
                budget: budget,
                consumedCents: consumedCents,
                percentage: percentage,
                isExceeded: isExceeded,
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
