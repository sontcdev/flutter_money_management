// path: lib/src/ui/widgets/budget_progress.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';

class BudgetProgress extends StatelessWidget {
  final Budget budget;

  const BudgetProgress({Key? key, required this.budget}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(symbol: '₫', decimalDigits: 0);
    final consumed = budget.consumedCents;
    final limit = budget.limitCents;
    final remaining = limit - consumed;
    final progress = consumed / limit;
    final percentUsed = (progress * 100).clamp(0, 100);

    // Determine color based on usage
    Color progressColor;
    if (percentUsed >= 100) {
      progressColor = Colors.red;
    } else if (percentUsed >= 90) {
      progressColor = Colors.orange;
    } else if (percentUsed >= 75) {
      progressColor = Colors.amber;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 10,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      format.format(consumed / 100),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Limit',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      format.format(limit / 100),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  format.format(remaining / 100),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remaining < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            if (budget.overdraftCents > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Overdraft: ${format.format(budget.overdraftCents / 100)}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Period: ${DateFormat('MMM dd, yyyy').format(budget.periodStart)} - ${DateFormat('MMM dd, yyyy').format(budget.periodEnd)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

