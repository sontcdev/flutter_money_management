// path: lib/src/ui/widgets/transaction_list_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../providers/report_providers.dart';
import 'category_icon_widget.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionWithCategory transactionWithCategory;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TransactionListItem({
    super.key,
    required this.transactionWithCategory,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = transactionWithCategory.transaction;
    final categoryName = transactionWithCategory.categoryName;

    final formatter = NumberFormat.currency(
      locale: 'vi',
      symbol: 'đ',
      decimalDigits: 0,
    );

    final isExpense = transaction.type == TransactionType.expense;
    final amountText = isExpense
        ? '-${formatter.format(transaction.amountCents.abs() / 100)}'
        : '+${formatter.format(transaction.amountCents.abs() / 100)}';
    // Transaction amounts are black, only prefix +/- shows the type
    const amountColor = Colors.black87;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildCategoryIcon(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        transaction.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    // Use getCategoryColor for fallback to light gray
    final categoryColor = getCategoryColor(transactionWithCategory.categoryColorValue);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CategoryIconWidget(
          iconName: transactionWithCategory.categoryIconName,
          size: 24,
          color: categoryColor,
        ),
      ),
    );
  }
}
