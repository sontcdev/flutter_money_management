import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';

double _c(Color a, Color b) => AppSurfaceTokens.contrast(a, b);

void main() {
  group('light neutral tokens', () {
    test('text roles are readable on background, surface and surface2', () {
      for (final bg in [
        AppColors.background,
        AppColors.surface,
        AppColors.surface2,
      ]) {
        expect(_c(AppColors.textPrimary, bg), greaterThanOrEqualTo(7));
        expect(_c(AppColors.textSecondary, bg), greaterThanOrEqualTo(4.5));
        expect(_c(AppColors.textFaint, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('central surface tokens reference AppColors', () {
      expect(AppSurfaceTokens.background, AppColors.background);
      expect(AppSurfaceTokens.card, AppColors.surface);
      expect(AppSurfaceTokens.navy, AppColors.textPrimary);
      expect(AppSurfaceTokens.inactive, AppColors.textFaint);
    });

    test('hero gradient keeps navy readable for every accent', () {
      for (final accent in ThemeColorNotifier.availableColors.values) {
        for (final stop in AppSurfaceTokens.heroGradient(accent)) {
          expect(_c(AppSurfaceTokens.navy, stop), greaterThanOrEqualTo(4.5));
        }
      }
    });
  });

  group('semantic and dark values are unchanged', () {
    test('brand, status, income/expense, categories', () {
      expect(AppColors.primary, const Color(0xFF00884B));
      expect(AppColors.error, const Color(0xFFCF4040));
      expect(AppColors.warning, const Color(0xFFD3A329));
      expect(AppColors.info, const Color(0xFF4678CC));
      expect(AppColors.expense, AppColors.error);
      expect(AppColors.income, AppColors.primary);
      expect(AppColors.expenseContainer, const Color(0xFFFFE3DF));
      expect(AppColors.incomeContainer, const Color(0xFFD1F1DB));
      expect(AppColors.categoryColors.length, 10);
      expect(AppColors.categoryColors.first, const Color(0xFF00884B));
    });

    test('dark base tokens', () {
      expect(AppColors.backgroundDark, const Color(0xFF110F09));
      expect(AppColors.surfaceDark, const Color(0xFF1D1A13));
      expect(AppColors.surface2Dark, const Color(0xFF27241C));
      expect(AppColors.borderDark, const Color(0xFF35332C));
      expect(AppColors.textLight, const Color(0xFFF3F2ED));
      expect(AppColors.textLightSecondary, const Color(0xFFB1AEA6));
      expect(AppColors.textLightFaint, const Color(0xFF8F8C83));
      expect(AppColors.textDark, const Color(0xFF16140C));
    });
  });

  group('themes on actual components', () {
    test('light theme wires the cool neutrals', () {
      final t = AppTheme.lightTheme();
      expect(t.scaffoldBackgroundColor, AppColors.background);
      expect(t.colorScheme.surface, AppColors.surface);
      expect(t.colorScheme.surfaceContainerHighest, AppColors.surface2);
      expect(t.cardTheme.color, AppColors.surface);
      expect(t.dialogTheme.backgroundColor, AppColors.surface);
      expect(t.bottomSheetTheme.backgroundColor, AppColors.surface);
      expect(t.inputDecorationTheme.fillColor, AppColors.surface);
      expect(t.chipTheme.backgroundColor, AppColors.surface2);
    });

    test('dark theme base is unchanged', () {
      final t = AppTheme.darkTheme();
      expect(t.scaffoldBackgroundColor, AppColors.backgroundDark);
      expect(t.cardTheme.color, AppColors.surfaceDark);
      expect(t.colorScheme.surface, AppColors.surfaceDark);
      expect(t.chipTheme.backgroundColor, AppColors.surface2Dark);
      expect(t.colorScheme.onSurface, AppColors.textLight);
    });

    test('every accent keeps readable onPrimary and component text', () {
      final accents = [
        AppColors.primary,
        ...ThemeColorNotifier.availableColors.values,
      ];
      for (final a in accents) {
        for (final t in [
          AppTheme.lightTheme(primaryColor: a),
          AppTheme.darkTheme(primaryColor: a),
        ]) {
          final cs = t.colorScheme;
          expect(_c(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5),
              reason: 'onPrimary on accent $a');
          final btn = t.elevatedButtonTheme.style!;
          expect(btn.backgroundColor!.resolve({}), cs.primary);
          expect(btn.foregroundColor!.resolve({}), cs.onPrimary);
          expect(t.floatingActionButtonTheme.foregroundColor, cs.onPrimary);
          expect(_c(cs.onSurface, cs.surface), greaterThanOrEqualTo(7));
          expect(
              _c(t.chipTheme.labelStyle!.color!, t.chipTheme.backgroundColor!),
              greaterThanOrEqualTo(7));
        }
      }
    });

    test('light accent on card and background is ensured by helper', () {
      for (final a in ThemeColorNotifier.availableColors.values) {
        for (final bg in [
          AppColors.background,
          AppColors.surface,
          AppColors.surface2,
        ]) {
          expect(_c(AppSurfaceTokens.ensureContrast(a, bg), bg),
              greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('light component radii come from AppSpacing', () {
      final t = AppTheme.lightTheme();
      final card = t.cardTheme.shape as RoundedRectangleBorder;
      expect(card.borderRadius, BorderRadius.circular(12));
      final dialog = t.dialogTheme.shape as RoundedRectangleBorder;
      expect(dialog.borderRadius, BorderRadius.circular(20));
    });
  });

  group('accent text roles and selected chip (all accents, both modes)', () {
    final accents = <Color>[
      AppColors.primary,
      ...ThemeColorNotifier.availableColors.values,
    ];

    Color over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      final neutrals = dark
          ? [
              AppColors.backgroundDark,
              AppColors.surfaceDark,
              AppColors.surface2Dark,
            ]
          : [AppColors.background, AppColors.surface, AppColors.surface2];

      test('$mode: TextButton, tab and nav text >= 4.5 on neutrals', () {
        for (final a in accents) {
          final t = dark
              ? AppTheme.darkTheme(primaryColor: a)
              : AppTheme.lightTheme(primaryColor: a);
          final tb = t.textButtonTheme.style!;
          final roles = <String, Color?>{
            'textButton fg': tb.foregroundColor!.resolve({}),
            'textButton text': tb.textStyle!.resolve({})!.color,
            'tab label': t.tabBarTheme.labelColor,
            'tab selected style': t.tabBarTheme.labelStyle!.color,
            'nav item': t.bottomNavigationBarTheme.selectedItemColor,
            'nav label': t.bottomNavigationBarTheme.selectedLabelStyle!.color,
          };
          roles.forEach((name, color) {
            for (final bg in neutrals) {
              expect(_c(color!, bg), greaterThanOrEqualTo(4.5),
                  reason: '$mode $name accent $a on $bg');
            }
          });
          // Fill identity is preserved: ColorScheme.primary is the fill.
          expect(t.elevatedButtonTheme.style!.backgroundColor!.resolve({}),
              t.colorScheme.primary);
        }
      });

      test('$mode: selected chip label >= 4.5 on its composite fill', () {
        for (final a in accents) {
          final t = dark
              ? AppTheme.darkTheme(primaryColor: a)
              : AppTheme.lightTheme(primaryColor: a);
          final chip = t.chipTheme;
          for (final base in dark
              ? [AppColors.surfaceDark, AppColors.backgroundDark]
              : [AppColors.surface, AppColors.background]) {
            final fill = over(chip.selectedColor!, base);
            expect(_c(chip.labelStyle!.color!, fill),
                greaterThanOrEqualTo(4.5),
                reason: '$mode selected chip accent $a on $base');
          }
          // The primary fill itself must carry onPrimary text >= 4.5.
          expect(_c(t.colorScheme.onPrimary, t.colorScheme.primary),
              greaterThanOrEqualTo(4.5));
        }
      });
    }

    test('light Home nav: label >= 4.5 on white, icon >= 3 on pill', () {
      for (final a in accents) {
        final color = AppSurfaceTokens.ensureContrast(a, Colors.white);
        expect(_c(color, Colors.white), greaterThanOrEqualTo(4.5));
        final pill = over(a.withValues(alpha: 0.12), Colors.white);
        expect(_c(color, pill), greaterThanOrEqualTo(3.0),
            reason: 'nav icon on pill, accent $a');
      }
    });

    test('ensureContrast fallback is black/white when target cannot pass', () {
      const mid = Color(0xFF808080);
      final c = AppSurfaceTokens.ensureContrastOnAll(
        mid,
        [Colors.white, const Color(0xFF000000)],
        minRatio: 4.5,
        toward: mid,
      );
      expect(c == Colors.black || c == Colors.white, isTrue);
    });
  });
}
