import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Neutral light-mode surface tokens shared by Today/Home (and later screens).
/// Dark mode never reads these values.
class AppSurfaceTokens {
  const AppSurfaceTokens._();

  static const Color background = AppColors.background;
  static const Color card = AppColors.surface;
  static const Color navy = AppColors.textPrimary;
  static const Color inactive = AppColors.textFaint;

  /// Decorative only. Carries no income/expense meaning.
  static const Color mint = Color(0xFF7EE0C3);

  /// Subtle two-stop gradient: [base] tinted into white. Text on it is [navy].
  static List<Color> heroGradient(Color base) => [
        Color.lerp(Colors.white, base, 0.12)!,
        Color.lerp(Colors.white, base, 0.26)!,
      ];

  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
  }

  /// Returns [color] shifted toward [toward] (default [navy]) until it reaches
  /// [minRatio] against every color in [backgrounds]. Keeps accent identity
  /// where it already contrasts. If the target itself cannot reach [minRatio],
  /// falls back to whichever of pure black or white contrasts best.
  static Color ensureContrastOnAll(
    Color color,
    List<Color> backgrounds, {
    double minRatio = 4.5,
    Color toward = navy,
  }) {
    bool ok(Color c) =>
        backgrounds.every((bg) => contrast(c, bg) >= minRatio);
    for (var step = 0; step <= 20; step++) {
      final c = Color.lerp(color, toward, step / 20)!;
      if (ok(c)) return c;
    }
    for (final c in [Colors.black, Colors.white]) {
      if (ok(c)) return c;
    }
    double worst(Color c) =>
        backgrounds.map((bg) => contrast(c, bg)).reduce((a, b) => a < b ? a : b);
    return worst(Colors.black) >= worst(Colors.white)
        ? Colors.black
        : Colors.white;
  }

  static Color ensureContrast(Color color, Color background,
      {double minRatio = 4.5, Color toward = navy}) {
    return ensureContrastOnAll(color, [background],
        minRatio: minRatio, toward: toward);
  }
}
