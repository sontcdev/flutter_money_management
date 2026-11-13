import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_date_cell.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';

void main() {
  for (final locale in const [Locale('vi'), Locale('en'), Locale('ja')]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.3]) {
        for (final size in const [Size(390, 844), Size(844, 390)]) {
          testWidgets(
              'badges readable and no overflow $locale dark=$dark x$scale $size',
              (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final theme = dark ? AppTheme.darkTheme() : AppTheme.lightTheme();
            await tester.pumpWidget(MaterialApp(
              theme: theme,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                    size: size, textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: Row(
                    children: [
                      for (final cents in [123456789012, 500])
                        Expanded(
                          child: CalendarDateCell(
                            date: DateTime(2025, 11, 5),
                            displayedMonth: DateTime(2025, 11, 1),
                            badges: [
                              AmountBadge(amountCents: cents, isIncome: true),
                              AmountBadge(amountCents: -cents, isIncome: false),
                            ],
                            onTap: () {},
                          ),
                        ),
                      for (var i = 0; i < 5; i++) const Spacer(),
                    ],
                  ),
                ),
              ),
            ));
            expect(tester.takeException(), isNull);
            expect(
                Localizations.localeOf(
                        tester.element(find.byType(CalendarDateCell).first))
                    .languageCode,
                locale.languageCode);
            final badgeTexts = tester
                .widgetList<Text>(find.descendant(
                    of: find.byType(CalendarDateCell),
                    matching: find.byType(Text)))
                .where((t) => t.style?.fontSize != null);
            expect(badgeTexts, isNotEmpty);
            for (final t in badgeTexts) {
              expect(t.style!.fontSize, greaterThanOrEqualTo(9));
            }
          });
        }
      }
    }
  }
}
