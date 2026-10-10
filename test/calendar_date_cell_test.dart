import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_date_cell.dart';
import 'package:flutter_money_management/src/theme/report_theme.dart';

Widget _app(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi'), Locale('ja')],
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: appChild!,
    ),
    home: Scaffold(
      body: Center(child: SizedBox(width: 56, child: child)),
    ),
  );
}

CalendarDateCell _cell({
  bool isSelected = false,
  List<AmountBadge>? badges,
  VoidCallback? onTap,
}) {
  return CalendarDateCell(
    date: DateTime(2026, 5, 14),
    displayedMonth: DateTime(2026, 5),
    badges: badges ??
        [
          AmountBadge(amountCents: 150000, isIncome: true),
          AmountBadge(amountCents: 25050, isIncome: false),
        ],
    isSelected: isSelected,
    onTap: onTap ?? () {},
  );
}

void main() {
  testWidgets('reads date, income and expense as one phrase', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(_cell(isSelected: true)));

    expect(
      tester.getSemantics(find.byType(CalendarDateCell)),
      matchesSemantics(
        label: 'May 14, 2026, Income +1,500, Expense -250.5',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('reads only the date when there are no badges', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(_cell(badges: const [])));

    expect(
      tester.getSemantics(find.byType(CalendarDateCell)),
      matchesSemantics(
        label: 'May 14, 2026',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('tapping the cell calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(_cell(onTap: () => taps++)));

    await tester.tap(find.byType(CalendarDateCell));
    expect(taps, 1);
  });

  testWidgets('badge text is at least labelSmall size', (tester) async {
    await tester.pumpWidget(_app(_cell()));

    final badgeText = tester.widget<Text>(find.text('+1.5K'));
    expect(badgeText.style?.fontSize, isNotNull);
    expect(badgeText.style!.fontSize, greaterThanOrEqualTo(10));
  });

  testWidgets('clamps large text scale to 1.3 inside the cell', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_cell(), textScale: 3.0));

    final context = tester.element(find.text('14'));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(13, 0.001));
    expect(
      tester.getSize(find.byType(CalendarDateCell)).height,
      greaterThanOrEqualTo(ReportTheme.cellHeight),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cell is never shorter than the base height', (tester) async {
    await tester.pumpWidget(_app(_cell(badges: const []), textScale: 0.8));

    expect(
      tester.getSize(find.byType(CalendarDateCell)).height,
      greaterThanOrEqualTo(ReportTheme.cellHeight),
    );
  });
}
