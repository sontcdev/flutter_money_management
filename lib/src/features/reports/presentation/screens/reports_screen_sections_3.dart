part of 'reports_screen.dart';

class _BudgetSummaryHeader extends StatelessWidget {
  const _BudgetSummaryHeader({
    required this.budget,
    required this.consumedCents,
    required this.percentage,
    required this.isExceeded,
  });

  final Budget budget;
  final int consumedCents;
  final double percentage;
  final bool isExceeded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
                    child: _PeriodTab(
                      label: l10n.byMonth,
                      selected: selectedTab.value == 0,
                      onTap: () => selectedTab.value = 0,
                    ),
                  ),
                  Expanded(
                    child: _PeriodTab(
                      label: l10n.byYear,
                      selected: selectedTab.value == 1,
                      onTap: () => selectedTab.value = 1,
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
              _MonthGrid(
                selectedYear: selectedYear.value,
                initialMonth: initialMonth,
                now: now,
                months: months,
              ),
            ] else ...[
              // Theo năm: Year grid
              _YearGrid(
                years: years,
                initialYear: initialYear,
                now: now,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.selectedYear,
    required this.initialMonth,
    required this.now,
    required this.months,
  });

  final int selectedYear;
  final DateTime initialMonth;
  final DateTime now;
  final List<String> months;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
            selectedYear == initialMonth.year &&
                monthNum == initialMonth.month;
        final isCurrentMonth =
            selectedYear == now.year && monthNum == now.month;

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
              'value': DateTime(selectedYear, monthNum),
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
    );
  }
}

class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.years,
    required this.initialYear,
    required this.now,
  });

  final List<int> years;
  final int initialYear;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
    );
  }
}
