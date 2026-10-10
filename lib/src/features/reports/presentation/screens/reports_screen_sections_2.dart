part of 'reports_screen.dart';

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
            _BudgetReportCardHeader(
              budget: budget,
              category: category,
              percentage: percentage,
              isExceeded: isExceeded,
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

class _BudgetReportCardHeader extends StatelessWidget {
  const _BudgetReportCardHeader({
    required this.budget,
    required this.category,
    required this.percentage,
    required this.isExceeded,
  });

  final Budget budget;
  final Category category;
  final double percentage;
  final bool isExceeded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
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

class _CategoryTotalCard extends StatelessWidget {
  const _CategoryTotalCard({
    required this.categoryTransactions,
    required this.totalAmount,
    required this.categoryColor,
    required this.isIncomeReport,
  });

  final List<Transaction> categoryTransactions;
  final int totalAmount;
  final int categoryColor;
  final bool isIncomeReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
    );
  }
}

class _CategoryDayCard extends StatelessWidget {
  const _CategoryDayCard({
    required this.date,
    required this.dayTransactions,
    required this.dayTotal,
    required this.categoryColor,
    required this.isIncomeReport,
  });

  final DateTime date;
  final List<Transaction> dayTransactions;
  final int dayTotal;
  final int categoryColor;
  final bool isIncomeReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
  }
}
