import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final cellBase = isSelected
        ? semanticColors.calendarSelected
        : (isToday
            ? semanticColors.calendarToday
            : Theme.of(context).scaffoldBackgroundColor);
    final dayColor = AppSurfaceTokens.ensureContrast(
      (isSelected || isToday || isCurrentMonth)
          ? scheme.onSurface
          : scheme.onSurfaceVariant,
      cellBase,
      toward: scheme.onSurface,
    );

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
                  color: semanticColors.income.withValues(alpha: 0.3), width: 1)
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
                    color: dayColor,
                  ),
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 1),
              Expanded(
                child: Column(
                  children: badges
                      .take(2)
                      .map((badge) => _buildBadge(context, badge, cellBase))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, AmountBadge badge, Color cellBase) {
    final scheme = Theme.of(context).colorScheme;
    final accent = badge.isIncome
        ? context.semanticColors.income
        : context.semanticColors.expense;
    final fill = accent.withValues(alpha: 0.15);
    final textColor = AppSurfaceTokens.ensureContrast(
      accent,
      Color.alphaBlend(fill, cellBase),
      toward: scheme.onSurface,
    );
    final locale = Localizations.localeOf(context);
    final localeName = locale.countryCode?.isNotEmpty == true
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    final formatter = NumberFormat.compact(locale: localeName);
    final amountText = formatter.format(badge.amountCents.abs() / 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
      ),
      child: Text(
        amountText,
        style: TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
