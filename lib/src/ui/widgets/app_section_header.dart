// path: lib/src/ui/widgets/app_section_header.dart

import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Standardized section header for consistent UI hierarchy
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTrailingTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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
            ),
          ),
          if (trailing != null)
            onTrailingTap != null
                ? InkWell(
                    onTap: onTrailingTap,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: trailing,
                    ),
                  )
                : trailing!,
        ],
      ),
    );
  }
}
