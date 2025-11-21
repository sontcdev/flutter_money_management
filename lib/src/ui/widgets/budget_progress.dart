// path: lib/src/ui/widgets/budget_progress.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/budget.dart';
import '../../utils/currency_formatter.dart';

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
    final consumedFormatted = CurrencyFormatter.formatFromCents(budget.consumedCents, currency);
    final limitFormatted = CurrencyFormatter.formatFromCents(budget.limitCents, currency);
    final remainingFormatted = CurrencyFormatter.formatFromCents(budget.remainingCents.abs(), currency);

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
              budget.isExceeded ? 'Exceeded' : 'Remaining',
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
          'Limit: $limitFormatted',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

