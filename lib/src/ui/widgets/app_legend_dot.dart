// path: lib/src/ui/widgets/app_legend_dot.dart

import 'package:flutter/material.dart';

/// Small colored dot used in chart legends, matching `.legend-dot` in the
/// Claude Design mockups.
class AppLegendDot extends StatelessWidget {
  final Color color;
  final double size;

  const AppLegendDot({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
