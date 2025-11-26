// path: lib/src/ui/widgets/transaction_group_header.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/report_theme.dart';

class TransactionGroupHeader extends StatelessWidget {
  final DateTime date;
  final int netAmount;
  final bool isHighlighted;

  const TransactionGroupHeader({
    super.key,
    required this.date,
    required this.netAmount,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final amountFormatter = NumberFormat.currency(
      locale: 'vi',
      symbol: 'đ',
      decimalDigits: 0,
    );

    final amountLabel = netAmount >= 0
        ? '+${amountFormatter.format(netAmount / 100)}'
        : amountFormatter.format(netAmount / 100);
    // Daily total uses theme color for positive, red for negative
    final amountColor = netAmount >= 0 
        ? Theme.of(context).colorScheme.primary  // Theme color for positive
        : const Color(0xFFD32F2F); // Red for negative

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              amountLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
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

