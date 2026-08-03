import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

enum TransactionItemDensity {
  normal,
  compact,
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final String? categoryIconName;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final VoidCallback? onTap;
  final TransactionItemDensity density;
  final bool showDate;
  final bool showTime;
  final bool showChevron;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.categoryName,
    this.categoryIconName,
    this.categoryIcon,
    this.categoryColor,
    this.onTap,
    this.density = TransactionItemDensity.normal,
    this.showDate = true,
    this.showTime = false,
    this.showChevron = false,
  });

  // Convenience constructor for compact display
  const TransactionItem.compact({
    super.key,
    required this.transaction,
    required this.categoryName,
    this.categoryIconName,
    this.categoryIcon,
    this.categoryColor,
    this.onTap,
    this.showDate = true,
    this.showTime = false,
    this.showChevron = false,
  }) : density = TransactionItemDensity.compact;

  @override
  Widget build(BuildContext context) {
    final formattedAmount = CurrencyFormatter.formatFromCents(
      transaction.amountCents,
      transaction.currency,
    );

    // Transfers move money between wallets, so they are neither red nor green.
    final Color color;
    switch (transaction.type) {
      case TransactionType.expense:
        color = AppColors.expense;
        break;
      case TransactionType.income:
        color = AppColors.income;
        break;
      case TransactionType.transfer:
        color = Theme.of(context).colorScheme.onSurface;
        break;
    }

    final isCompact = density == TransactionItemDensity.compact;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: isCompact ? AppSpacing.compactGap : AppSpacing.sm,
      ),
      leading: _buildLeading(context),
      title: Text(
        categoryName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context, formattedAmount, color),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (categoryIconName == null && categoryIcon == null) return null;

    final tint = categoryColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      alignment: Alignment.center,
      child: categoryIconName != null
          ? CategoryIconWidget(
              iconName: categoryIconName!,
              size: 20,
              color: tint,
            )
          : Icon(categoryIcon, size: 20, color: tint),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final hasNote = transaction.note != null && transaction.note!.isNotEmpty;

    // Show note and date together if both exist
    if (hasNote && showDate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transaction.note!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      );
    }

    // Show only note if no date
    if (hasNote) {
      return Text(
        transaction.note!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    // Show only date if no note
    if (showDate) {
      return Text(
        _formatDate(context),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
      );
    }

    return null;
  }

  Widget _buildTrailing(
      BuildContext context, String formattedAmount, Color color) {
    final isCompact = density == TransactionItemDensity.compact;

    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_amountPrefix$formattedAmount',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: AppSpacing.iconSizeSm,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$_amountPrefix$formattedAmount',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (showDate) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatDate(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  /// Transfers keep no sign: the money stays inside the workspace.
  String get _amountPrefix {
    switch (transaction.type) {
      case TransactionType.expense:
        return '-';
      case TransactionType.income:
        return '+';
      case TransactionType.transfer:
        return '';
    }
  }

  String _formatDate(BuildContext context) {
    if (showTime) {
      return formatLocalizedDateTime(context, transaction.dateTime);
    }
    return formatLocalizedDate(context, transaction.dateTime);
  }
}
