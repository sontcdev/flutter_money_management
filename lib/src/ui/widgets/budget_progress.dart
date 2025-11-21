// path: lib/src/ui/widgets/budget_progress.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/budget.dart';

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
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );

    final consumed = budget.consumedCents / 100;
    final limit = budget.limitCents / 100;
    final remaining = budget.remainingCents / 100;
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
              formatter.format(consumed),
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
              budget.isExceeded
                  ? formatter.format(-remaining)
                  : formatter.format(remaining),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: progressColor,
                  ),
            ),
          ],
        ),
        Text(
          'Limit: ${formatter.format(limit)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'VND':
        return '₫';
      case 'EUR':
        return '€';
      default:
        return currency;
    }
  }
}

