part of 'reports_screen.dart';

class _ReportSummaryCard extends ConsumerWidget {
  const _ReportSummaryCard({
    required this.transactionsAsync,
    required this.period,
    required this.monthStartDay,
  });

  final AsyncValue<List<Transaction>> transactionsAsync;
  final ReportPeriod period;
  final int monthStartDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return transactionsAsync.when(
      data: (transactions) {
        final current = transactions
            .where((t) =>
                period.contains(t.dateTime, monthStartDay))
            .toList();
        final previousPeriod = period.previous(monthStartDay);
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
    );
  }
}

class _BudgetReportsSection extends ConsumerWidget {
  const _BudgetReportsSection({
    required this.budgetsAsync,
    required this.categoriesAsync,
    required this.transactionsAsync,
    required this.period,
    required this.monthStartDay,
    required this.reportTypeFilter,
  });

  final AsyncValue<List<Budget>> budgetsAsync;
  final AsyncValue<List<Category>> categoriesAsync;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final ReportPeriod period;
  final int monthStartDay;
  final int reportTypeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return budgetsAsync.when(
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
                    period.range(monthStartDay);

                // Filter budgets based on category type
                final categoryMap = {
                  for (var c in categories) c.id: c
                };
                List<Budget> filteredBudgets;
                if (reportTypeFilter == 1) {
                  filteredBudgets = budgets.where((b) {
                    final cat = categoryMap[b.categoryId];
                    return cat?.type == CategoryType.expense;
                  }).toList();
                } else if (reportTypeFilter == 2) {
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
                        reportTypeFilter == 1
                            ? l10n.noExpenseBudgets
                            : reportTypeFilter == 2
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
}

class _CategoryBreakdownSection extends ConsumerWidget {
  const _CategoryBreakdownSection({
    required this.transactionsAsync,
    required this.categoriesAsync,
    required this.period,
    required this.monthStartDay,
    required this.reportTypeFilter,
  });

  final AsyncValue<List<Transaction>> transactionsAsync;
  final AsyncValue<List<Category>> categoriesAsync;
  final ReportPeriod period;
  final int monthStartDay;
  final int reportTypeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return transactionsAsync.when(
      data: (transactions) {
        return categoriesAsync.when(
          data: (categories) {
            // Filter by transaction type based on reportTypeFilter
            final transactionTypeFilter = reportTypeFilter == 2
                ? TransactionType.income
                : TransactionType.expense;

            var filteredTransactions = transactions
                .where((t) =>
                    t.type == transactionTypeFilter &&
                    period.contains(t.dateTime, monthStartDay))
                .toList();

            // Also filter by category type if needed
            if (reportTypeFilter == 1) {
              final expenseCategories = categories
                  .where((c) => c.type == CategoryType.expense)
                  .map((c) => c.id)
                  .toSet();
              filteredTransactions = filteredTransactions
                  .where(
                      (t) => expenseCategories.contains(t.categoryId))
                  .toList();
            } else if (reportTypeFilter == 2) {
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
                    reportTypeFilter == 2
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
                          period.range(monthStartDay),
                          period.label(l10n, monthStartDay),
                          reportTypeFilter ==
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
}
