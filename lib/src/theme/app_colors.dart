// path: lib/src/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Color tokens derived from the OKLCH design system used in the app's
/// Claude Design mockups (brand hue 155 green, negative hue 25 red,
/// warn hue 85 amber, accent hue 260 blue). Values below are the sRGB
/// conversion of those OKLCH tokens so Flutter's [Color] can consume them.
class AppColors {
  AppColors._();

  // Brand / primary (green) — used as the default accent; the app also
  // supports a user-selectable accent color via ThemeColorNotifier, which
  // overrides `primary`/`primaryStrong`/`primarySoft` at theme-build time.
  static const Color primary = Color(0xFF00884B);
  static const Color primaryStrong = Color(0xFF00632D);
  static const Color primarySoft = Color(0xFFD1F1DB);
  static const Color primaryDark = Color(0xFF51B67A);
  static const Color primaryStrongDark = Color(0xFF73CE95);
  static const Color primarySoftDark = Color(0xFF12301E);

  // Surfaces
  static const Color background = Color(0xFFF8F6F2);
  static const Color backgroundDark = Color(0xFF110F09);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1D1A13);
  static const Color surface2 = Color(0xFFF1EFEA);
  static const Color surface2Dark = Color(0xFF27241C);

  // Text / ink
  static const Color textPrimary = Color(0xFF16140C);
  static const Color textSecondary = Color(0xFF5C584C);
  static const Color textFaint = Color(0xFF8F8C83);
  static const Color textLight = Color(0xFFF3F2ED);
  static const Color textLightSecondary = Color(0xFFB1AEA6);
  static const Color textLightFaint = Color(0xFF74716A);
  static const Color textDark = Color(0xFF16140C);

  // Borders
  static const Color border = Color(0xFFE0DED7);
  static const Color borderDark = Color(0xFF35332C);

  // Status
  static const Color error = Color(0xFFCF4040);
  static const Color errorDark = Color(0xFFF2716A);
  static const Color success = primary;
  static const Color successDark = primaryDark;
  static const Color warning = Color(0xFFD3A329);
  static const Color warningDark = Color(0xFFDDB049);
  static const Color info = Color(0xFF4678CC);
  static const Color infoDark = Color(0xFF73A5F6);

  // Expense/income
  static const Color expense = error;
  static const Color expenseDark = errorDark;
  static const Color income = primary;
  static const Color incomeDark = primaryDark;

  // Soft container backgrounds (chips, badges, highlighted rows)
  static const Color expenseContainer = Color(0xFFFFE3DF);
  static const Color expenseContainerDark = Color(0xFF47211E);
  static const Color incomeContainer = Color(0xFFD1F1DB);
  static const Color incomeContainerDark = Color(0xFF12301E);
  static const Color warningContainer = Color(0xFFFBEDD1);
  static const Color warningContainerDark = Color(0xFF392C0C);
  static const Color successContainer = incomeContainer;
  static const Color successContainerDark = incomeContainerDark;
  static const Color infoContainer = Color(0xFFD7E9FF);
  static const Color infoContainerDark = Color(0xFF1A2941);

  // Elevation/shadow
  static const Color shadow = Color(0x1A16140C);
  static const Color shadowDark = Color(0x59000000);

  // Category palette — vibrant, distinct hues for user-assigned categories.
  static const List<Color> categoryColors = [
    Color(0xFF00884B), // brand green
    Color(0xFF4678CC), // accent blue
    Color(0xFFD3A329), // amber
    Color(0xFFCF4040), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFF14B8A6), // teal
    Color(0xFF84CC16), // lime
    Color(0xFFF97316), // orange
  ];
}
