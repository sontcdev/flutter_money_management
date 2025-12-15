// path: lib/src/ui/widgets/transaction_group_header.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/report_theme.dart';

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
    final amountFormatter = NumberFormat.currency(
      locale: 'vi',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? ReportTheme.selectedDateBackground.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDateLabel(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Row(
            children: [
              if (totalIncome > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${amountFormatter.format(totalIncome / 100)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (totalExpense > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B3D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${amountFormatter.format(totalExpense / 100)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B3D),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final weekdayMap = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };

    final weekday = weekdayMap[date.weekday] ?? '';
    final dateStr = DateFormat('dd/MM/yyyy').format(date);

    return '$dateStr ($weekday)';
  }
}

