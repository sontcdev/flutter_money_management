// path: lib/src/ui/widgets/budget_progress.dart
import 'package:flutter/material.dart';
import '../../models/budget.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';

class BudgetProgress extends StatelessWidget {
  final Budget budget;
  final NumberFormat? formatter;

  const BudgetProgress({
    super.key,
    required this.budget,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final format = formatter ?? NumberFormat.currency(symbol: '');
    final progress = budget.limitCents > 0
        ? (budget.consumedCents / budget.limitCents).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded = budget.consumedCents > budget.limitCents;
    final remaining = budget.limitCents - budget.consumedCents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              format.format(budget.consumedCents / 100),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isExceeded ? AppColors.error : AppColors.textPrimary,
                  ),
            ),
            Text(
              format.format(budget.limitCents / 100),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(
            isExceeded ? AppColors.error : AppColors.primary,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          isExceeded
              ? 'Overdraft: ${format.format(budget.overdraftCents / 100)}'
              : 'Remaining: ${format.format(remaining / 100)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isExceeded ? AppColors.error : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

