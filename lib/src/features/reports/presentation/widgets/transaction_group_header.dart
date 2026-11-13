import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerFill = isHighlighted
        ? context.semanticColors.calendarSelected.withValues(alpha: 0.5)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final headerBg =
        Color.alphaBlend(headerFill, theme.scaffoldBackgroundColor);
    Color readable(Color accent, double alpha) =>
        AppSurfaceTokens.ensureContrast(
          accent,
          Color.alphaBlend(accent.withValues(alpha: alpha), headerBg),
          toward: scheme.onSurface,
        );
    final incomeColor = readable(context.semanticColors.income, 0.1);
    final expenseColor = readable(context.semanticColors.expense, 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: headerFill),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDateLabel(context, date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppSurfaceTokens.ensureContrast(
                    scheme.onSurface,
                    headerBg,
                    toward: scheme.onSurface,
                  ),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Text(
                    '+$incomeAmount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: incomeColor,
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
                    color:
                        context.semanticColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Text(
                    '-$expenseAmount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: expenseColor,
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
