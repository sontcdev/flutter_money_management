// path: lib/src/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Softer, more pleasant blue-purple
  static const Color primary =
      Color(0xFF6366F1); // Indigo - modern & professional
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Secondary colors - Warmer accent
  static const Color secondary = Color(0xFFF59E0B); // Amber - warm & friendly
  static const Color secondaryDark = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFFBBF24);

  // Background colors - Softer, less harsh
  static const Color background = Color(0xFFFAFAFC); // Very light grey-blue
  static const Color backgroundDark = Color(0xFF0F0F14);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A21);

  // Text colors - Better contrast
  static const Color textPrimary =
      Color(0xFF1F2937); // Darker grey for better readability
  static const Color textSecondary = Color(0xFF6B7280); // Medium grey
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F0F14);

  // Status colors - More vibrant & clear
  static const Color success = Color(0xFF10B981); // Emerald green
  static const Color error = Color(0xFFEF4444); // Softer red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Expense/Income colors - Clear differentiation
  static const Color expense = Color(0xFFEF4444); // Red
  static const Color income = Color(0xFF10B981); // Green

  // Category colors (palette - Modern & Vibrant)
  static const List<Color> categoryColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFF84CC16), // Lime
  ];

  // Border colors - Softer
  static const Color border = Color(0xFFE5E7EB); // Light grey
  static const Color borderDark = Color(0xFF374151);

  // Elevation/Shadow colors
  static const Color shadow = Color(0x0F000000); // Lighter shadow
  static const Color shadowDark = Color(0x40000000);

  // Semantic surface colors for finance UI
  static const Color surfaceSubtle =
      Color(0xFFF8F9FA); // Very subtle background
  static const Color surfaceMuted =
      Color(0xFFF3F4F6); // Muted surface for secondary content
  static const Color surfaceDarkSubtle =
      Color(0xFF1F1F26); // Dark mode subtle surface

  // Container colors for transaction types
  static const Color incomeContainer =
      Color(0xFFD1FAE5); // Light green container
  static const Color incomeContainerDark =
      Color(0xFF064E3B); // Dark green container
  static const Color expenseContainer =
      Color(0xFFFEE2E2); // Light red container
  static const Color expenseContainerDark =
      Color(0xFF7F1D1D); // Dark red container

  // Status container colors
  static const Color warningContainer =
      Color(0xFFFEF3C7); // Light amber container
  static const Color warningContainerDark =
      Color(0xFF78350F); // Dark amber container
  static const Color infoContainer = Color(0xFFDBEAFE); // Light blue container
  static const Color infoContainerDark =
      Color(0xFF1E3A8A); // Dark blue container
  static const Color successContainer =
      Color(0xFFD1FAE5); // Light green container
  static const Color successContainerDark =
      Color(0xFF064E3B); // Dark green container

  // Muted text helpers
  static const Color textMuted = Color(0xFF9CA3AF); // More muted than secondary
  static const Color textDisabled = Color(0xFFD1D5DB); // Disabled state text
}
