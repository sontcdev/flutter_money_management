import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/chart_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';

void main() {
  for (final locale in const [Locale('ja'), Locale('en'), Locale('vi')]) {
    for (final scale in [1.0, 1.3]) {
      for (final dark in [false, true]) {
        testWidgets('left ticks one line, no overlap '
            '${locale.languageCode} x$scale dark=$dark', (tester) async {
          late String resolved;
          await tester.pumpWidget(MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 300,
                  child: Builder(builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    resolved = l10n.localeName;
                    return BarChartWidget(
                      data: [
                        ChartData(label: 'a', value: 10500000),
                        ChartData(label: 'b', value: 3000000),
                      ],
                      labelFormatter: (value) => NumberFormat.compact(
                        locale: l10n.localeName,
                      ).format(value),
                    );
                  }),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          expect(resolved, locale.languageCode);
          final ticks = tester
              .widgetList<Text>(find.byType(Text))
              .where((t) => t.maxLines == 1 && t.softWrap == false)
              .toList();
          expect(ticks, isNotEmpty);
          final rects = <Rect>[];
          for (final t in ticks) {
            final f = find.byWidget(t);
            final size = tester.getSize(f);
            rects.add(tester.getRect(f));
            // single line: height ~ one line of 10pt * scale
            expect(size.height, lessThan(10 * scale * 1.6),
                reason: 'wrapped: ${t.data}');
          }
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              expect(rects[i].overlaps(rects[j]), isFalse,
                  reason: '${ticks[i].data} vs ${ticks[j].data}');
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('empty data shows noData', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BarChartWidget(data: const [], labelFormatter: (v) => '$v'),
      ),
    ));
    expect(find.byType(Center), findsWidgets);
  });
}
