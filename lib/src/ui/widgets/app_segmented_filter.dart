// path: lib/src/ui/widgets/app_segmented_filter.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';

/// Standardized segmented filter for consistent filtering UI
class AppSegmentedFilter<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry? padding;

  const AppSegmentedFilter({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.sm,
          ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: List.generate(
            options.length,
            (index) {
              final option = options[index];
              final isSelected = option.value == selectedValue;

              return Expanded(
                child: _FilterButton(
                  label: option.label,
                  icon: option.icon,
                  isSelected: isSelected,
                  color: option.color,
                  onTap: () => onChanged(option.value),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FilterOption<T> {
  final String label;
  final T value;
  final IconData? icon;
  final Color? color;

  const FilterOption({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    this.icon,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.primary;
    final thumbColor =
        isDark ? AppColors.segmentThumbDark : theme.colorScheme.surface;
    final selectedForeground = color != null ? effectiveColor : theme.colorScheme.onSurface;
    final unselectedForeground = theme.colorScheme.onSurface.withValues(
      alpha: 0.55,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          constraints: const BoxConstraints(
            minHeight: AppSpacing.buttonHeight - 4,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? thumbColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.shadow
                          .withValues(alpha: isDark ? 0.3 : 0.12),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppSpacing.iconSizeSm,
                  color: isSelected ? selectedForeground : unselectedForeground,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color:
                        isSelected ? selectedForeground : unselectedForeground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
