// path: lib/src/ui/widgets/app_segmented_filter.dart

import 'package:flutter/material.dart';
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
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.sm,
          ),
      child: Row(
        children: List.generate(
          options.length,
          (index) {
            final option = options[index];
            final isSelected = option.value == selectedValue;
            final isFirst = index == 0;
            final isLast = index == options.length - 1;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: isFirst ? 0 : AppSpacing.xs / 2,
                  right: isLast ? 0 : AppSpacing.xs / 2,
                ),
                child: _FilterButton(
                  label: option.label,
                  icon: option.icon,
                  isSelected: isSelected,
                  color: option.color,
                  onTap: () => onChanged(option.value),
                ),
              ),
            );
          },
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
    final effectiveColor = color ?? theme.colorScheme.primary;
    final unselectedBackground = theme.colorScheme.surfaceContainerHighest;
    final unselectedForeground = theme.colorScheme.onSurface.withValues(
      alpha: 0.6,
    );
    final selectedForeground =
        ThemeData.estimateBrightnessForColor(effectiveColor) ==
                Brightness.dark
            ? Colors.white
            : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : unselectedBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
                style: TextStyle(
                  color:
                      isSelected ? selectedForeground : unselectedForeground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
