// path: lib/src/ui/widgets/app_metric_card.dart

import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';

enum MetricCardSize {
  hero, // Large display for main metrics
  compact, // Smaller for secondary metrics
  status, // Status indicator style
}

enum MetricCardTone {
  neutral,
  positive,
  warning,
  danger,
}

/// Standardized metric card for displaying financial data
class AppMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final MetricCardSize size;
  final MetricCardTone tone;

  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.backgroundColor,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.size = MetricCardSize.compact,
    this.tone = MetricCardTone.neutral,
  });

  // Convenience constructors
  const AppMetricCard.hero({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.backgroundColor,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.tone = MetricCardTone.neutral,
  }) : size = MetricCardSize.hero;

  const AppMetricCard.status({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.backgroundColor,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.tone = MetricCardTone.neutral,
  }) : size = MetricCardSize.status;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _getEffectiveColor(context);
    final effectiveBackgroundColor = _getEffectiveBackgroundColor(context);

    final card = Card(
      color: effectiveBackgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: _getPadding(),
          child: _buildContent(context, effectiveColor),
        ),
      ),
    );

    return card;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case MetricCardSize.hero:
        return const EdgeInsets.all(AppSpacing.xl);
      case MetricCardSize.status:
        return const EdgeInsets.all(AppSpacing.md);
      case MetricCardSize.compact:
        return const EdgeInsets.all(AppSpacing.cardPadding);
    }
  }

  Color _getEffectiveColor(BuildContext context) {
    if (color != null) return color!;

    switch (tone) {
      case MetricCardTone.positive:
        return AppColors.success;
      case MetricCardTone.warning:
        return AppColors.warning;
      case MetricCardTone.danger:
        return AppColors.error;
      case MetricCardTone.neutral:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color? _getEffectiveBackgroundColor(BuildContext context) {
    if (backgroundColor != null) return backgroundColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (tone) {
      case MetricCardTone.positive:
        return isDark
            ? AppColors.successContainerDark
            : AppColors.successContainer;
      case MetricCardTone.warning:
        return isDark
            ? AppColors.warningContainerDark
            : AppColors.warningContainer;
      case MetricCardTone.danger:
        return isDark
            ? AppColors.expenseContainerDark
            : AppColors.expenseContainer;
      case MetricCardTone.neutral:
        return null; // Use default card color
    }
  }

  Widget _buildContent(BuildContext context, Color effectiveColor) {
    switch (size) {
      case MetricCardSize.hero:
        return _buildHeroContent(context, effectiveColor);
      case MetricCardSize.status:
        return _buildStatusContent(context, effectiveColor);
      case MetricCardSize.compact:
        return _buildCompactContent(context, effectiveColor);
    }
  }

  Widget _buildHeroContent(BuildContext context, Color effectiveColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.iconSizeLg,
                  color: effectiveColor,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: effectiveColor,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context, Color effectiveColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.iconSizeSm,
                  color: effectiveColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusContent(BuildContext context, Color effectiveColor) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: AppSpacing.iconSizeSm,
            color: effectiveColor,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: effectiveColor,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
