import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_date_cell.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/transaction_group_header.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

const _accents = <Color>[
  Color(0xFF00884B),
  Color(0xFFFFD60A),
  Color(0xFF7C4DFF)
];

Widget _app(ThemeData theme, Widget child) => MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: SizedBox(width: 800, child: child))),
    );

TextStyle _style(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style!;

void main() {
  final themes = <String, ThemeData Function(Color)>{
    'light': (c) => AppTheme.lightTheme(primaryColor: c),
    'dark': (c) => AppTheme.darkTheme(primaryColor: c),
  };

  for (final e in themes.entries) {
    for (final accent in _accents) {
      final name = '${e.key} ${accent.toARGB32().toRadixString(16)}';
      testWidgets('calendar cell readable: $name', (t) async {
        final theme = e.value(accent);
        final sem = theme.extension<AppSemanticColors>()!;
        final scaffold = theme.scaffoldBackgroundColor;
        final states = {
          'selected': (sem.calendarSelected, true, false, 10),
          'today': (sem.calendarToday, false, true, 11),
          'adjacent': (scaffold, false, false, 31),
        };
        for (final s in states.entries) {
          final (base, sel, today, day) = s.value;
          final date = s.key == 'adjacent'
              ? DateTime(2026, 10, day)
              : DateTime(2026, 11, day);
          await t.pumpWidget(_app(
            theme,
            SizedBox(
              height: 90,
              child: CalendarDateCell(
                date: date,
                displayedMonth: DateTime(2026, 11),
                isSelected: sel,
                isToday: today,
                onTap: () {},
                badges: [
                  AmountBadge(amountCents: 12300000, isIncome: true),
                  AmountBadge(amountCents: 4500000, isIncome: false),
                ],
              ),
            ),
          ));
          expect(
            AppSurfaceTokens.contrast(_style(t, '$day').color!, base),
            greaterThanOrEqualTo(4.5),
            reason: '${s.key} day',
          );
          for (final (acc, text) in [
            (sem.income, '123K'),
            (sem.expense, '45K'),
          ]) {
            final bg = Color.alphaBlend(acc.withValues(alpha: 0.15), base);
            expect(
              AppSurfaceTokens.contrast(_style(t, text).color!, bg),
              greaterThanOrEqualTo(4.5),
              reason: '${s.key} badge $text',
            );
          }
        }
      });

      for (final hl in [false, true]) {
        testWidgets('group header readable: $name hl=$hl', (t) async {
          final theme = e.value(accent);
          final sem = theme.extension<AppSemanticColors>()!;
          await t.pumpWidget(_app(
            theme,
            TransactionGroupHeader(
              date: DateTime(2026, 11, 10),
              totalIncome: 123000,
              totalExpense: 45000,
              isHighlighted: hl,
            ),
          ));
          final fill = hl
              ? sem.calendarSelected.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3);
          final hbg = Color.alphaBlend(fill, theme.scaffoldBackgroundColor);
          for (final (acc, f) in [(sem.income, '+'), (sem.expense, '-')]) {
            final txt = find.textContaining(f).evaluate().first.widget as Text;
            final bg = Color.alphaBlend(acc.withValues(alpha: 0.1), hbg);
            expect(
              AppSurfaceTokens.contrast(txt.style!.color!, bg),
              greaterThanOrEqualTo(4.5),
              reason: 'amount $f',
            );
          }
        });
      }
    }
  }
}
