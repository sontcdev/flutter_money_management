import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryItem({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Use getCategoryColor for fallback to light gray
    final color = getCategoryColor(category.colorValue);
    final iconData = CategoryIcons.getIcon(category.iconName);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap ?? onEdit,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                iconData,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.error,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
