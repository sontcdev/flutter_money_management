import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';

const _accents = <Color>[
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFFEB3B),
  Color(0xFF0A84FF),
  Color(0xFF1B5E20),
  Color(0xFFE91E63),
  Color(0xFF9E9E9E),
];

Widget _app(ThemeData theme, Widget home) => MaterialApp(
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  final themes = <String, ThemeData Function(Color)>{
    'light': (c) => AppTheme.lightTheme(primaryColor: c),
    'dark': (c) => AppTheme.darkTheme(primaryColor: c),
  };

  group('AppButton loading spinner', () {
    for (final mode in themes.keys) {
      for (final accent in _accents) {
        for (final style in AppButtonStyle.values) {
          testWidgets('$mode ${accent.toARGB32().toRadixString(16)} $style',
              (tester) async {
            final theme = themes[mode]!(accent);
            await tester.pumpWidget(_app(
              theme,
              Scaffold(
                body: Center(
                  child: AppButton(
                    text: 'Go',
                    style: style,
                    isLoading: true,
                    onPressed: () {},
                  ),
                ),
              ),
            ));
            final spinner = tester.widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator));
            final color = spinner.valueColor!.value!;

            final filled = style == AppButtonStyle.filled ||
                style == AppButtonStyle.prominent;
            final backdrops = [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface,
            ];
            var fills = backdrops;
            if (filled) {
              final material = tester.widget<Material>(find
                  .descendant(
                    of: find.byType(ElevatedButton),
                    matching: find.byType(Material),
                  )
                  .first);
              final fill = material.color!;
              fills = [
                for (final b in backdrops) Color.alphaBlend(fill, b),
              ];
            }
            for (final f in fills) {
              expect(AppSurfaceTokens.contrast(color, f),
                  greaterThanOrEqualTo(3.0));
            }
          });
        }
      }
    }

    testWidgets('loading still blocks presses', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(
        AppTheme.lightTheme(),
        Scaffold(
          body: AppButton(
              text: 'Go', isLoading: true, onPressed: () => taps++),
        ),
      ));
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('showAppSnackBar', () {
    for (final mode in themes.keys) {
      for (final accent in _accents) {
        for (final type in [AppSnackBarType.success, AppSnackBarType.error]) {
          testWidgets('$mode ${accent.toARGB32().toRadixString(16)} $type',
              (tester) async {
            final theme = themes[mode]!(accent);
            await tester.pumpWidget(_app(
              theme,
              Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showAppSnackBar(
                      context,
                      'Saved message',
                      type: type,
                      onUndo: () {},
                    ),
                    child: const Text('show'),
                  ),
                ),
              ),
            ));
            await tester.tap(find.text('show'));
            await tester.pumpAndSettle();

            final snack = tester.widget<SnackBar>(find.byType(SnackBar));
            final fill = snack.backgroundColor!;
            final text = tester.widget<Text>(find.text('Saved message'));
            expect(AppSurfaceTokens.contrast(text.style!.color!, fill),
                greaterThanOrEqualTo(4.5));
            expect(snack.action!.textColor, isNotNull);
            expect(AppSurfaceTokens.contrast(snack.action!.textColor!, fill),
                greaterThanOrEqualTo(4.5));
          });
        }
      }
    }
  });
}
