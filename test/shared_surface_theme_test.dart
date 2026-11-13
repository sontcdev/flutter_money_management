import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/ui/widgets/app_segmented_filter.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';

const _accents = <Color>[
  Color(0xFF00884B),
  Color(0xFFFFD60A),
  Color(0xFF7C4DFF),
  Color(0xFFFF80AB),
  Color(0xFF1B1B3A),
];

Widget _app(ThemeData theme, Widget child) => MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Form(child: child)),
    );

Color _textColor(WidgetTester t, Finder f) {
  final text = t.widget<Text>(
    find.descendant(of: f, matching: find.byType(Text)).first,
  );
  return text.style!.color!;
}

void main() {
  final themes = <String, ThemeData Function(Color)>{
    'light': (c) => AppTheme.lightTheme(primaryColor: c),
    'dark': (c) => AppTheme.darkTheme(primaryColor: c),
  };

  for (final entry in themes.entries) {
    for (final accent in _accents) {
      final label = '${entry.key} ${accent.toARGB32().toRadixString(16)}';

      testWidgets('AppInput toolbar contrast $label', (tester) async {
        final theme = entry.value(accent);
        await tester.pumpWidget(_app(theme, const AppInput(label: 'L')));
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        final bg = theme.scaffoldBackgroundColor;
        final l10n =
            AppLocalizations.of(tester.element(find.byType(AppInput)))!;
        for (final s in [l10n.done, l10n.skip]) {
          final c = _textColor(tester, find.widgetWithText(TextButton, s));
          expect(AppSurfaceTokens.contrast(c, bg), greaterThanOrEqualTo(4.5),
              reason: '$s on $label');
        }
      });

      testWidgets('EmptyState contrast $label', (tester) async {
        final theme = entry.value(accent);
        await tester.pumpWidget(_app(
          theme,
          const EmptyState(icon: Icons.inbox, title: 'T', message: 'Body'),
        ));
        final bg = theme.scaffoldBackgroundColor;
        final tint = Color.alphaBlend(
            theme.colorScheme.primary.withValues(alpha: 0.1), bg);
        final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
        expect(AppSurfaceTokens.contrast(icon.color!, tint),
            greaterThanOrEqualTo(3), reason: 'icon $label');
        final body = tester.widget<Text>(find.text('Body')).style!.color!;
        expect(AppSurfaceTokens.contrast(body, bg), greaterThanOrEqualTo(4.5),
            reason: 'body $label');
        expect(
            AppSurfaceTokens.contrast(body, theme.colorScheme.surface),
            greaterThanOrEqualTo(4.5),
            reason: 'body/surface $label');
      });

      testWidgets('AppSegmentedFilter contrast $label', (tester) async {
        final theme = entry.value(accent);
        final isDark = entry.key == 'dark';
        Widget build(int sel) => _app(
              theme,
              AppSegmentedFilter<int>(
                selectedValue: sel,
                onChanged: (_) {},
                options: [
                  const FilterOption(label: 'Plain', value: 0, icon: Icons.add),
                  FilterOption(
                      label: 'Custom',
                      value: 1,
                      icon: Icons.remove,
                      color: accent),
                ],
              ),
            );
        final bg = theme.scaffoldBackgroundColor;
        final track = Color.alphaBlend(
            theme.colorScheme.onSurface
                .withValues(alpha: isDark ? 0.08 : 0.05),
            bg);
        final thumb = isDark ? AppColors.segmentThumbDark : theme.colorScheme.surface;
        void check(String name, Finder text, Finder icon, Color back) {
          final tc = tester.widget<Text>(text).style!.color!;
          final ic = tester.widget<Icon>(icon).color!;
          final tr = AppSurfaceTokens.contrast(
              Color.alphaBlend(tc, back), back);
          final ir = AppSurfaceTokens.contrast(
              Color.alphaBlend(ic, back), back);
          // ignore: avoid_print
          print('RATIO $label $name text=${tr.toStringAsFixed(2)} icon=${ir.toStringAsFixed(2)}');
          expect(tr, greaterThanOrEqualTo(4.5), reason: '$name text $label');
          expect(ir, greaterThanOrEqualTo(3), reason: '$name icon $label');
        }

        await tester.pumpWidget(build(0));
        await tester.pumpAndSettle();
        check('default-selected', find.text('Plain'), find.byIcon(Icons.add), thumb);
        check('custom-unselected', find.text('Custom'), find.byIcon(Icons.remove), track);
        await tester.pumpWidget(build(1));
        await tester.pumpAndSettle();
        check('custom-selected', find.text('Custom'), find.byIcon(Icons.remove), thumb);
        check('default-unselected', find.text('Plain'), find.byIcon(Icons.add), track);
      });
    }
  }
}
