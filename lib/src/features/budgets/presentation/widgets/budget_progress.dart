import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class BudgetProgress extends StatelessWidget {
  final Budget budget;
  final String categoryName;
  final String currency;

  const BudgetProgress({
    super.key,
    required this.budget,
    required this.categoryName,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = localeNameOf(context);
    final consumedFormatted = CurrencyFormatter.formatFromCents(
      budget.consumedCents,
      currency,
      locale: locale,
    );
    final limitFormatted = CurrencyFormatter.formatFromCents(
      budget.limitCents,
      currency,
      locale: locale,
    );
    final remainingFormatted = CurrencyFormatter.formatFromCents(
      budget.remainingCents.abs(),
      currency,
      locale: locale,
    );

    final progress = budget.progressPercentage / 100;

    Color progressColor = AppColors.success;
    if (budget.isExceeded) {
      progressColor = AppColors.error;
    } else if (progress > 0.8) {
      progressColor = AppColors.warning;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoryName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              consumedFormatted,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              budget.isExceeded ? l10n.exceeded : l10n.remaining,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              remainingFormatted,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: progressColor,
                  ),
            ),
          ],
        ),
        Text(
          '${l10n.limit}: $limitFormatted',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
