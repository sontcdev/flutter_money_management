import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/chart_widget.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(ThemeData theme, Widget child) => MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, height: 300, child: child)),
      ),
    );

void main() {
  final themes = {
    'light': AppTheme.lightTheme(primaryColor: const Color(0xFF1565C0)),
    'dark': AppTheme.darkTheme(primaryColor: const Color(0xFF1565C0)),
  };

  test('pieLabelColor reaches 4.5:1 on varied slice fills', () {
    const fills = [
      Colors.yellow,
      Colors.amber,
      Colors.lime,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.grey,
      Colors.cyan,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Color(0xFF777777),
      Color(0xFF808080),
    ];
    for (final fill in fills) {
      final label = pieLabelColor(fill);
      expect(AppSurfaceTokens.contrast(label, fill), greaterThanOrEqualTo(4.5),
          reason: 'fill $fill label $label');
    }
  });

  for (final entry in themes.entries) {
    final theme = entry.value;

    testWidgets('pie fallback uses theme primary and readable labels '
        '(${entry.key})', (tester) async {
      await tester.pumpWidget(_host(
        theme,
        PieChartWidget(data: [
          ChartData(label: 'a', value: 60, percentage: 60),
          ChartData(
              label: 'b', value: 40, percentage: 40, color: Colors.yellow),
        ]),
      ));
      await tester.pump(const Duration(seconds: 1));
      final pie = tester.widget<PieChart>(find.byType(PieChart));
      final sections = pie.data.sections;
      expect(sections[0].color, theme.colorScheme.primary);
      expect(sections[0].color, isNot(Colors.blue));
      for (final s in sections) {
        expect(
          AppSurfaceTokens.contrast(s.titleStyle!.color!, s.color),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('bar fallback and axis labels (${entry.key})', (tester) async {
      await tester.pumpWidget(_host(
        theme,
        BarChartWidget(
          data: [ChartData(label: 'x', value: 10)],
          labelFormatter: (v) => v.toStringAsFixed(0),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      final bar = tester.widget<BarChart>(find.byType(BarChart));
      expect(bar.data.barGroups.first.barRods.first.color,
          theme.colorScheme.primary);

      final label = tester.widget<Text>(find.text('x'));
      final color = label.style!.color!;
      expect(color, theme.colorScheme.onSurfaceVariant);
      final bg = theme.scaffoldBackgroundColor;
      final ratio = AppSurfaceTokens.contrast(color, bg);
      // ignore: avoid_print
      print('axis ${entry.key}: $ratio on scaffold, '
          '${AppSurfaceTokens.contrast(color, theme.colorScheme.surface)} '
          'on surface');
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(
        AppSurfaceTokens.contrast(color, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  }
}
