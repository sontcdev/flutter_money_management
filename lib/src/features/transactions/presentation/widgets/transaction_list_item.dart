import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';

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
    final locale = Localizations.localeOf(context);
    final localeName = locale.countryCode?.isNotEmpty == true
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;

    final Color amountColor;
    final String amountPrefix;
    switch (transaction.type) {
      case TransactionType.expense:
        amountColor = context.semanticColors.expense;
        amountPrefix = '-';
        break;
      case TransactionType.income:
        amountColor = context.semanticColors.income;
        amountPrefix = '+';
        break;
      case TransactionType.transfer:
        amountColor = Theme.of(context).colorScheme.onSurface;
        amountPrefix = '';
        break;
    }

    final amountText =
        '$amountPrefix${CurrencyFormatter.formatFromCents(transaction.amountCents.abs(), transaction.currency, locale: localeName)}';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _buildCategoryIcon(context),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        transaction.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              amountText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: AppSpacing.iconSizeSm,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final categoryColor =
        getCategoryColor(transactionWithCategory.categoryColorValue);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      alignment: Alignment.center,
      child: CategoryIconWidget(
        iconName: transactionWithCategory.categoryIconName,
        size: AppSpacing.iconSizeSm,
        color: categoryColor,
      ),
    );
  }
}
