// path: lib/src/ui/widgets/summary_bar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class SummaryBar extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int net;

  const SummaryBar({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              'Thu nhập',
              formatter.format(totalIncome / 100),
              AppColors.income, // Green for income
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Chi tiêu',
              formatter.format(totalExpense / 100),
              AppColors.expense, // Red for expense
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Tổng',
              '${net >= 0 ? '+' : ''}${formatter.format(net / 100)}',
              net >= 0 ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

