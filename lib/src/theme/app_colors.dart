// path: lib/src/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Pleasant blue color
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Secondary colors
  static const Color secondary = Color(0xFFFCAC12);
  static const Color secondaryDark = Color(0xFFDC8C02);
  static const Color secondaryLight = Color(0xFFFFC542);

  // Background colors
  static const Color background = Color(0xFFFFFBFE);
  static const Color backgroundDark = Color(0xFF0D0E0F);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C1C1E);

  // Text colors
  static const Color textPrimary = Color(0xFF212325);
  static const Color textSecondary = Color(0xFF91919F);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0D0E0F);

  // Status colors
  static const Color success = Color(0xFF00A86B);
  static const Color error = Color(0xFFFD3C4A);
  static const Color warning = Color(0xFFFCAC12);
  static const Color info = Color(0xFF0077FF);

  // Expense/Income colors
  static const Color expense = Color(0xFFFD3C4A);
  static const Color income = Color(0xFF00A86B);

  // Category colors (palette from Figma)
  static const List<Color> categoryColors = [
    Color(0xFFFCAC12), // Yellow
    Color(0xFF7F3DFF), // Violet
    Color(0xFFFD3C4A), // Red
    Color(0xFF0077FF), // Blue
    Color(0xFF00A86B), // Green
    Color(0xFFFF6B00), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF9C27B0), // Purple
    Color(0xFF4CAF50), // Light Green
  ];

  // Border colors
  static const Color border = Color(0xFFF1F1FA);
  static const Color borderDark = Color(0xFF2C2C2E);

  // Elevation/Shadow colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);
}

