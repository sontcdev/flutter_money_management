import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/reports_screen.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void check(ThemeData theme, bool dark) {
    final surface = theme.cardTheme.color!;
    final hist = ReportsScreen.historicalBarColor(
      AppColors.primary,
      surface,
      dark: dark,
    );
    expect(hist.a, 1.0, reason: 'fill must be opaque');
    expect(AppSurfaceTokens.contrast(hist, surface), greaterThanOrEqualTo(3));
    expect(hist, isNot(AppColors.primary));
  }

  test('historical bar >=3:1 on real light card surface', () {
    check(AppTheme.lightTheme(), false);
  });

  test('historical bar >=3:1 on real dark card surface', () {
    check(AppTheme.darkTheme(), true);
  });
}
