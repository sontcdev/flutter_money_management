import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/theme/report_theme.dart';

class CalendarDateCell extends StatelessWidget {
  final DateTime date;
  final List<AmountBadge> badges;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const CalendarDateCell({
    super.key,
    required this.date,
    required this.badges,
    this.isSelected = false,
    this.isToday = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = date.month == DateTime.now().month;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? ReportTheme.selectedDateBackground
              : (isToday ? ReportTheme.todayBackground : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(
                  color: ReportTheme.incomeColor.withValues(alpha: 0.3),
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
                        ? Colors
                            .black // Black text on light background (selected/today)
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
    final amountText = formatter.format(badge.amountCents.abs() / 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      decoration: BoxDecoration(
        color: badge.isIncome
            ? ReportTheme.incomeColor.withValues(alpha: 0.15)
            : ReportTheme.expenseColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        amountText,
        style: TextStyle(
          fontSize: 7,
          color: badge.isIncome
              ? ReportTheme.incomeColor
              : ReportTheme.expenseColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
