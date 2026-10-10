import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/theme/report_theme.dart';

class CalendarDateCell extends StatelessWidget {
  final DateTime date;
  final DateTime displayedMonth;
  final List<AmountBadge> badges;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const CalendarDateCell({
    super.key,
    required this.date,
    required this.displayedMonth,
    required this.badges,
    this.isSelected = false,
    this.isToday = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth =
        date.year == displayedMonth.year && date.month == displayedMonth.month;
    final semanticColors = context.semanticColors;

    return Semantics(
      button: true,
      selected: isSelected,
      label: _semanticLabel(context),
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Builder(
          builder: (context) => _buildCell(
            context,
            isCurrentMonth: isCurrentMonth,
            semanticColors: semanticColors,
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required bool isCurrentMonth,
    required AppSemanticColors semanticColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: MediaQuery.textScalerOf(context)
            .scale(ReportTheme.cellHeight)
            .clamp(ReportTheme.cellHeight, double.infinity),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? semanticColors.calendarSelected
              : (isToday ? semanticColors.calendarToday : Colors.transparent),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: isToday && !isSelected
              ? Border.all(
                  color: semanticColors.income.withValues(alpha: 0.3),
                  width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              date.day.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: (isSelected || isToday)
                        ? Theme.of(context).colorScheme.onSurface
                        : (isCurrentMonth
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color
                                ?.withValues(alpha: 0.4)),
                  ),
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 1),
              Expanded(
                child: Column(
                  children: badges
                      .take(2)
                      .map((badge) => _buildBadge(context, badge))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, AmountBadge badge) {
    final locale = Localizations.localeOf(context);
    final localeName = locale.countryCode?.isNotEmpty == true
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    final formatter = NumberFormat.compact(locale: localeName);
    final amountText =
        '${badge.isIncome ? '+' : '-'}${formatter.format(badge.amountCents.abs() / 100)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      decoration: BoxDecoration(
        color: badge.isIncome
            ? context.semanticColors.income.withValues(alpha: 0.15)
            : context.semanticColors.expense.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
      ),
      child: Text(
        amountText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badge.isIncome
                  ? context.semanticColors.income
                  : context.semanticColors.expense,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _semanticLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final parts = <String>[DateFormat.yMMMMd(localeName).format(date)];
    final formatter = NumberFormat.decimalPattern(localeName);
    for (final badge in badges) {
      final amount = formatter.format(badge.amountCents.abs() / 100);
      final label = badge.isIncome ? l10n?.income : l10n?.expense;
      parts.add(
        '${label ?? ''} ${badge.isIncome ? '+' : '-'}$amount'.trim(),
      );
    }
    return parts.join(', ');
  }
}
