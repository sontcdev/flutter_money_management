// path: lib/src/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  /// Tabular-figure style for currency amounts, using the platform's system
  /// font (SF Pro on iOS, Roboto on Android) so digits align in columns.
  static TextStyle monoAmountStyle({
    required Color color,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Builds an SF Pro-style text style. Passing `fontFamily: null` lets the
  /// platform resolve its native system font (SF Pro on iOS, Roboto on
  /// Android), which is the foundation of the iOS visual language.
  static TextStyle _sf({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double letterSpacing = 0,
    double height = 1.3,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamilyFallback: const ['-apple-system', 'SF Pro Text', 'Roboto'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static TextTheme _textTheme({
    required Color primaryText,
    required Color secondaryText,
  }) {
    return TextTheme(
      // Hero amounts / very large numbers
      displayLarge: _sf(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: 0.37,
        height: 1.05,
        tabular: true,
      ),
      // Large title (iOS 34pt)
      displayMedium: _sf(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: 0.37,
        height: 1.2,
      ),
      // Title 1
      displaySmall: _sf(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: 0.36,
        height: 1.2,
      ),
      headlineLarge: _sf(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: 0.36,
        height: 1.2,
      ),
      // Title 2
      headlineMedium: _sf(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: -0.26,
        height: 1.25,
      ),
      // Title 3
      headlineSmall: _sf(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: -0.45,
        height: 1.25,
      ),
      // Headline / inline nav title
      titleLarge: _sf(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: -0.43,
        height: 1.3,
      ),
      titleMedium: _sf(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: -0.32,
        height: 1.3,
      ),
      titleSmall: _sf(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: -0.24,
        height: 1.3,
      ),
      // Body (iOS 17pt)
      bodyLarge: _sf(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: primaryText,
        letterSpacing: -0.43,
        height: 1.4,
      ),
      // Callout / subhead
      bodyMedium: _sf(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primaryText,
        letterSpacing: -0.24,
        height: 1.4,
      ),
      // Footnote
      bodySmall: _sf(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        letterSpacing: -0.08,
        height: 1.4,
      ),
      // Button label
      labelLarge: _sf(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: -0.43,
        height: 1.2,
      ),
      // Segmented / small controls
      labelMedium: _sf(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: -0.08,
        height: 1.2,
      ),
      // Caption / tab bar
      labelSmall: _sf(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryText,
        letterSpacing: 0.06,
        height: 1.2,
      ),
    );
  }

  static ThemeData lightTheme({Color? primaryColor}) {
    final primary = primaryColor ?? AppColors.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: const [AppSemanticColors.light],
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary.withValues(alpha: 0.8),
        error: AppColors.error,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surface2,
        onPrimary: _onAccent(primary),
        onSecondary: AppColors.textDark,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _sf(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.43,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: _onAccent(primary),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCta),
          ),
          textStyle: _sf(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
            letterSpacing: -0.43,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.separator, width: 1),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCta),
          ),
          textStyle: _sf(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.43,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _sf(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: primary,
            letterSpacing: -0.43,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.separator, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.separator, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: _sf(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.textFaint,
          letterSpacing: -0.43,
        ),
      ),
      textTheme: _textTheme(
        primaryText: AppColors.textPrimary,
        secondaryText: AppColors.textSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: 0.5,
        space: 0.5,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusHero),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: _onAccent(primary),
        elevation: 2,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textFaint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: _sf(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        unselectedLabelStyle: _sf(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textFaint,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: _sf(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.24,
        ),
        unselectedLabelStyle: _sf(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: -0.24,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: _sf(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: -0.08,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),
      switchTheme: _switchTheme(primary, AppColors.surface, AppColors.border),
    );
  }

  static ThemeData darkTheme({Color? primaryColor}) {
    final primary = _darkAccent(primaryColor ?? AppColors.primaryDark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const [AppSemanticColors.dark],
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary.withValues(alpha: 0.8),
        error: AppColors.errorDark,
        surface: AppColors.surfaceDark,
        surfaceContainerHighest: AppColors.surface2Dark,
        onPrimary: _onAccent(primary),
        onSecondary: AppColors.textLight,
        onSurface: AppColors.textLight,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shadowColor: AppColors.shadowDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _sf(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
          letterSpacing: -0.43,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: AppColors.shadowDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: _onAccent(primary),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCta),
          ),
          textStyle: _sf(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            letterSpacing: -0.43,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textLight,
          side: const BorderSide(color: AppColors.separatorDark, width: 1),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCta),
          ),
          textStyle: _sf(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
            letterSpacing: -0.43,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _sf(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: primary,
            letterSpacing: -0.43,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.separatorDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.separatorDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: _sf(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.textLightFaint,
          letterSpacing: -0.43,
        ),
      ),
      textTheme: _textTheme(
        primaryText: AppColors.textLight,
        secondaryText: AppColors.textLightSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.separatorDark,
        thickness: 0.5,
        space: 0.5,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusHero),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: _onAccent(primary),
        elevation: 2,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textLightFaint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: _sf(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        unselectedLabelStyle: _sf(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textLightFaint,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.textLightSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: _sf(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.24,
        ),
        unselectedLabelStyle: _sf(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textLightSecondary,
          letterSpacing: -0.24,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2Dark,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: _sf(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textLight,
          letterSpacing: -0.08,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),
      switchTheme:
          _switchTheme(primary, AppColors.surfaceDark, AppColors.borderDark),
    );
  }

  static SwitchThemeData _switchTheme(
      Color primary, Color thumb, Color offTrack) {
    return SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? primary : offTrack,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
  }

  static Color _onAccent(Color accent) {
    return _contrast(AppColors.textDark, accent) >
            _contrast(AppColors.textLight, accent) + 0.1
        ? AppColors.textDark
        : AppColors.textLight;
  }

  static Color _darkAccent(Color accent) {
    var color = accent;
    for (var step = 1;
        step <= 10 && _contrast(color, AppColors.surfaceDark) < 4.5;
        step++) {
      color = Color.lerp(accent, AppColors.textLight, step / 10)!;
    }
    return color;
  }
}
