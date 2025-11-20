// path: lib/src/ui/widgets/transaction_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/transaction.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final VoidCallback? onTap;

  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(transaction.currency),
      decimalDigits: 2,
    );

    final amount = transaction.amountCents / 100;
    final color = transaction.type == TransactionType.expense
        ? AppColors.expense
        : AppColors.income;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: categoryColor?.withOpacity(0.1) ?? AppColors.primary.withOpacity(0.1),
        child: Icon(
          categoryIcon ?? Icons.category,
          color: categoryColor ?? AppColors.primary,
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
            '${transaction.type == TransactionType.expense ? '-' : '+'}${formatter.format(amount)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            DateFormat('HH:mm').format(transaction.dateTime),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
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

