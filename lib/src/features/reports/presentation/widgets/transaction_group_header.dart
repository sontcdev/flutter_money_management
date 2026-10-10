import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class TransactionGroupHeader extends StatelessWidget {
  final DateTime date;
  final int totalIncome;
  final int totalExpense;
  final bool isHighlighted;

  const TransactionGroupHeader({
    super.key,
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final incomeAmount = CurrencyFormatter.formatVNDFromCents(
      totalIncome,
      locale: l10n.localeName,
    );
    final expenseAmount = CurrencyFormatter.formatVNDFromCents(
      totalExpense,
      locale: l10n.localeName,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? context.semanticColors.calendarSelected.withValues(alpha: 0.5)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDateLabel(context, date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Row(
            children: [
              if (totalIncome > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.semanticColors.income.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Text(
                    '+$incomeAmount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.semanticColors.income,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (totalExpense > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.semanticColors.expense
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Text(
                    '-$expenseAmount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.semanticColors.expense,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateLabel(BuildContext context, DateTime date) {
    return formatLocalizedDateWithWeekday(context, date);
  }
}
