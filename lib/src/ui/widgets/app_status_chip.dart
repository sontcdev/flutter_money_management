// path: lib/src/ui/widgets/app_status_chip.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_surface_tokens.dart';

/// Standardized status chip for displaying status badges
class AppStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isOutlined;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isOutlined = false,
  });

  /// Success status (green)
  factory AppStatusChip.success({
    required String label,
    IconData? icon,
    bool isOutlined = false,
  }) {
    return AppStatusChip(
      label: label,
      color: AppColors.success,
      icon: icon,
      isOutlined: isOutlined,
    );
  }

  /// Warning status (amber)
  factory AppStatusChip.warning({
    required String label,
    IconData? icon,
    bool isOutlined = false,
  }) {
    return AppStatusChip(
      label: label,
      color: AppColors.warning,
      icon: icon,
      isOutlined: isOutlined,
    );
  }

  /// Error/Danger status (red)
  factory AppStatusChip.error({
    required String label,
    IconData? icon,
    bool isOutlined = false,
  }) {
    return AppStatusChip(
      label: label,
      color: AppColors.error,
      icon: icon,
      isOutlined: isOutlined,
    );
  }

  /// Info status (blue)
  factory AppStatusChip.info({
    required String label,
    IconData? icon,
    bool isOutlined = false,
  }) {
    return AppStatusChip(
      label: label,
      color: AppColors.info,
      icon: icon,
      isOutlined: isOutlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final fill = isOutlined
        ? surface
        : Color.alphaBlend(
            color.withValues(alpha: isDark ? 0.22 : 0.12), surface);
    // Same hue, shifted toward onSurface until it reads on the actual fill.
    final foreground = AppSurfaceTokens.ensureContrast(
      color,
      fill,
      toward: theme.colorScheme.onSurface,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOutlined
            ? Colors.transparent
            : color.withValues(alpha: isDark ? 0.22 : 0.12),
        border: isOutlined ? Border.all(color: color, width: 1.5) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          // Flexible lets a long label wrap inside bounded width instead of
          // overflowing the Row.
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
