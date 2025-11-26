// path: lib/src/ui/widgets/transaction_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/transaction.dart';
import '../../utils/currency_formatter.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final String? categoryIconName;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.categoryName,
    this.categoryIconName,
    this.categoryIcon,
    this.categoryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = CurrencyFormatter.formatFromCents(
      transaction.amountCents,
      transaction.currency,
    );

    final color = transaction.type == TransactionType.expense
        ? AppColors.expense
        : AppColors.income;

    final themeColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: categoryColor?.withOpacity(0.1) ?? themeColor.withOpacity(0.1),
        child: categoryIconName != null && categoryIconName!.isNotEmpty
            ? Text(
                categoryIconName!,
                style: const TextStyle(fontSize: 20),
              )
            : Icon(
                categoryIcon ?? Icons.category,
                color: categoryColor ?? themeColor,
              ),
      ),
      title: Text(
        categoryName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: transaction.note != null
          ? Text(
              transaction.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${transaction.type == TransactionType.expense ? '-' : '+'}$formattedAmount',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(transaction.dateTime),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

