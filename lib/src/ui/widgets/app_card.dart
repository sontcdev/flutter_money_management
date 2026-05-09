// path: lib/src/ui/widgets/app_card.dart

import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );

    if (onTap != null) {
      return Card(
        color: color,
        elevation: elevation,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: content,
        ),
      );
    }

    return Card(
      color: color,
      elevation: elevation,
      child: content,
    );
  }
}
