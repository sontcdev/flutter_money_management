// path: lib/src/ui/widgets/app_card.dart

import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final Clip? clipBehavior;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation,
    this.clipBehavior,
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
        margin: margin,
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: content,
        ),
      );
    }

    return Card(
      color: color,
      elevation: elevation,
      margin: margin,
      clipBehavior: clipBehavior,
      child: content,
    );
  }
}
