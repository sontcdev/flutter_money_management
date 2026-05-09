// path: lib/src/theme/app_spacing.dart

/// Standardized spacing constants for consistent UI
class AppSpacing {
  AppSpacing._();

  // Base spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Semantic spacing
  static const double cardPadding = lg;
  static const double screenPadding = lg;
  static const double sectionGap = xl;
  static const double itemGap = md;
  static const double tinyGap = xs;

  // Component-specific
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double listItemHeight = 72.0;
  static const double iconSize = 24.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeLg = 32.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 999.0;

  // Additional spacing for hero sections and compact lists
  static const double heroSpacing = 40.0; // For large hero sections
  static const double compactGap = 6.0; // Tighter spacing for compact lists
}
