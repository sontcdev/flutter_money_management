import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/models/report_period.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/chart_widget.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_metric_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_segmented_filter.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';

class ReportPeriodSelector extends StatelessWidget {
  final ReportPeriod period;
  final int monthStartDay;
  final ValueChanged<ReportPeriod> onChanged;
  final VoidCallback onPickPeriod;

  const ReportPeriodSelector({
    super.key,
    required this.period,
    required this.monthStartDay,
    required this.onChanged,
    required this.onPickPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final caption = period.caption(monthStartDay);
    final hasNext = period.hasNext(monthStartDay, DateTime.now());
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppSegmentedFilter<ReportPeriodUnit>(
            padding: EdgeInsets.zero,
            selectedValue: period.unit,
            onChanged: (unit) => onChanged(ReportPeriod.current(unit)),
            options: [
              FilterOption(label: l10n.week, value: ReportPeriodUnit.week),
              FilterOption(label: l10n.month, value: ReportPeriodUnit.month),
              FilterOption(label: l10n.year, value: ReportPeriodUnit.year),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: l10n.previousPeriod,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onChanged(period.previous(monthStartDay)),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  onTap: onPickPeriod,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        Text(
                          period.label(l10n, monthStartDay),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (caption != null)
                          Text(
                            caption,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.nextPeriod,
                icon: const Icon(Icons.chevron_right),
                onPressed: hasNext
                    ? () => onChanged(period.next(monthStartDay))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportSummarySection extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int previousIncome;
  final int previousExpense;
  final int transactionCount;

  const ReportSummarySection({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.previousIncome,
    required this.previousExpense,
    required this.transactionCount,
  });

  String? _delta(AppLocalizations l10n, int current, int previous) {
    if (previous == 0) return null;
    final ratio = (current - previous) / previous;
    final percent = NumberFormat(
      '+#,##0%;-#,##0%',
      l10n.localeName,
    ).format(ratio);
    return l10n.vsPreviousPeriod(percent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semanticColors = context.semanticColors;
    final balance = totalIncome - totalExpense;
    final balanceColor =
        balance >= 0 ? semanticColors.income : semanticColors.expense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppMetricCard(
                label: l10n.totalExpense,
                value: CurrencyFormatter.formatVNDFromCents(
                  totalExpense,
                  locale: l10n.localeName,
                ),
                icon: Icons.arrow_upward,
                color: semanticColors.expense,
                subtitle: _delta(l10n, totalExpense, previousExpense),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppMetricCard(
                label: l10n.totalIncome,
                value: CurrencyFormatter.formatVNDFromCents(
                  totalIncome,
                  locale: l10n.localeName,
                ),
                icon: Icons.arrow_downward,
                color: semanticColors.income,
                subtitle: _delta(l10n, totalIncome, previousIncome),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Row(
            children: [
              Icon(
                balance >= 0 ? Icons.trending_up : Icons.trending_down,
                color: balanceColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.balance,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.formatVNDFromCents(
                  balance,
                  locale: l10n.localeName,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: balanceColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            '${l10n.transactionCount}: $transactionCount',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class ReportTrendSection extends StatelessWidget {
  final List<ChartData> data;

  const ReportTrendSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lastSixMonths,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          BarChartWidget(
            data: data,
            labelFormatter: (value) =>
                NumberFormat.compact(locale: l10n.localeName).format(value),
            valueFormatter: (value) =>
                CurrencyFormatter.formatVND(value, locale: l10n.localeName),
          ),
        ],
      ),
    );
  }
}

class ReportCalendarEntryCard extends StatelessWidget {
  const ReportCalendarEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => Navigator.pushNamed(context, '/report-calendar'),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.calendar,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
