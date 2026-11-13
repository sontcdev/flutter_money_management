import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';

const double _tintAlpha = 0.15;

Color _iconForeground(BuildContext context, Color tint) {
  final theme = Theme.of(context);
  return AppSurfaceTokens.ensureContrastOnAll(
    tint,
    [
      for (final bg in {
        theme.colorScheme.surface,
        theme.scaffoldBackgroundColor
      })
        Color.alphaBlend(tint.withValues(alpha: _tintAlpha), bg),
    ],
    minRatio: 3,
    toward: theme.colorScheme.onSurface,
  );
}

enum _CategoryAction { edit, delete }

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
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap ?? onEdit,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
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
                color: color.withValues(alpha: _tintAlpha),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Icon(
                iconData,
                color: _iconForeground(context, color),
                size: AppSpacing.iconSizeSm,
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
            if (onEdit != null || onDelete != null)
              PopupMenuButton<_CategoryAction>(
                onSelected: (action) {
                  switch (action) {
                    case _CategoryAction.edit:
                      onEdit?.call();
                    case _CategoryAction.delete:
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: _CategoryAction.edit,
                      child: Text(l10n.edit),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: _CategoryAction.delete,
                      child: Text(l10n.delete),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
