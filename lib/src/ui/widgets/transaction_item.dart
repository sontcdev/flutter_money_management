// path: lib/src/ui/widgets/transaction_item.dart
import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String? categoryName;
  final String? accountName;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.categoryName,
    this.accountName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = NumberFormat.currency(symbol: '');
    final dateFormat = DateFormat('MMM dd, yyyy');

    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = isExpense ? AppColors.expense : AppColors.income;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isExpense ? AppColors.expense.withValues(alpha: 0.1) : AppColors.income.withValues(alpha: 0.1),
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: amountColor,
        ),
      ),
      title: Text(
        categoryName ?? l10n.category,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        '${dateFormat.format(transaction.dateTime)} • ${accountName ?? l10n.account}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isExpense ? '-' : '+'}${format.format(transaction.amountCents / 100)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            Text(
              transaction.note!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

