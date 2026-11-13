import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_money_management/src/ui/widgets/app_metric_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_status_chip.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(ThemeData theme, Widget child) => MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    );

Color _textColor(WidgetTester t, String s) =>
    t.widget<Text>(find.text(s)).style!.color!;

void main() {
  final themes = {
    'light': AppTheme.lightTheme(),
    'dark': AppTheme.darkTheme(),
  };

  for (final e in themes.entries) {
    final theme = e.value;
    final surface = theme.colorScheme.surface;

    group('AppStatusChip ${e.key}', () {
      final chips = <String, AppStatusChip>{
        'success': AppStatusChip.success(label: 'ok', icon: Icons.check),
        'warning': AppStatusChip.warning(label: 'warn', icon: Icons.check),
        'error': AppStatusChip.error(label: 'err', icon: Icons.check),
        'info': AppStatusChip.info(label: 'inf', icon: Icons.check),
        'warning-outlined':
            AppStatusChip.warning(label: 'wo', isOutlined: true),
        'error-outlined': AppStatusChip.error(label: 'eo', isOutlined: true),
      };
      for (final c in chips.entries) {
        testWidgets(c.key, (tester) async {
          await tester.pumpWidget(_host(theme, c.value));
          final chip = c.value;
          final isDark = theme.brightness == Brightness.dark;
          final fill = chip.isOutlined
              ? surface
              : Color.alphaBlend(
                  chip.color.withValues(alpha: isDark ? 0.22 : 0.12), surface);
          final fg = _textColor(tester, chip.label);
          expect(
              AppSurfaceTokens.contrast(fg, fill), greaterThanOrEqualTo(4.5));
          final icon = find.byType(Icon);
          if (icon.evaluate().isNotEmpty) {
            expect(tester.widget<Icon>(icon).color, fg);
          }
        });
      }
    });

    group('AppMetricCard ${e.key}', () {
      final cases = <String, AppMetricCard>{
        'neutral': const AppMetricCard(
            label: 'L', value: 'V', subtitle: 'S', icon: Icons.add),
        'positive': const AppMetricCard.hero(
            label: 'L',
            value: 'V',
            subtitle: 'S',
            icon: Icons.add,
            tone: MetricCardTone.positive),
        'warning': const AppMetricCard(
            label: 'L',
            value: 'V',
            subtitle: 'S',
            icon: Icons.add,
            tone: MetricCardTone.warning),
        'danger-status': const AppMetricCard.status(
            label: 'L',
            value: 'V',
            icon: Icons.add,
            tone: MetricCardTone.danger),
        'custom-bg': const AppMetricCard(
            label: 'L',
            value: 'V',
            subtitle: 'S',
            icon: Icons.add,
            color: AppColors.warning,
            backgroundColor: Color(0xFFFFF3C4)),
      };
      for (final c in cases.entries) {
        testWidgets(c.key, (tester) async {
          await tester.pumpWidget(_host(theme, c.value));
          final card = tester.widget<Card>(find.byType(Card));
          final bg = Color.alphaBlend(
              card.color ?? theme.cardTheme.color ?? surface, surface);
          expect(AppSurfaceTokens.contrast(_textColor(tester, 'V'), bg),
              greaterThanOrEqualTo(4.5));
          expect(AppSurfaceTokens.contrast(_textColor(tester, 'L'), bg),
              greaterThanOrEqualTo(4.5));
          if (c.value.subtitle != null) {
            expect(AppSurfaceTokens.contrast(_textColor(tester, 'S'), bg),
                greaterThanOrEqualTo(4.5));
          }
          final icon = tester.widget<Icon>(find.byType(Icon));
          final tint =
              Color.alphaBlend(icon.color!.withValues(alpha: 0.15), bg);
          expect(AppSurfaceTokens.contrast(icon.color!, bg),
              greaterThanOrEqualTo(3));
          expect(AppSurfaceTokens.contrast(icon.color!, tint),
              greaterThanOrEqualTo(3));
        });
      }
    });
  }
}
