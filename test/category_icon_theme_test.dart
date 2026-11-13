import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_item.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

final _now = DateTime(2026, 10, 9);

Category _category(Color color) => Category(
      id: 'c',
      name: 'Cat',
      iconName: 'restaurant',
      colorValue: color.toARGB32(),
      createdAt: _now,
      updatedAt: _now,
    );

Transaction _tx(TransactionType type) => Transaction(
      id: 't',
      amountCents: 10000,
      currency: 'VND',
      dateTime: _now,
      type: type,
      createdAt: _now,
      updatedAt: _now,
    );

Future<ThemeData> _pump(
    WidgetTester tester, ThemeData theme, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ));
  return theme;
}

void _expectContrast(ThemeData theme, Color tint, Color iconColor) {
  for (final bg in {theme.colorScheme.surface, theme.scaffoldBackgroundColor}) {
    final fill = Color.alphaBlend(tint.withValues(alpha: 0.15), bg);
    expect(_contrast(iconColor, fill), greaterThanOrEqualTo(3));
  }
}

void main() {
  const amber = Color(0xFFFFC107);
  const pale = Color(0xFFFFF59D);

  final themes = {
    'light': AppTheme.lightTheme(),
    'dark': AppTheme.darkTheme(),
  };

  for (final entry in themes.entries) {
    for (final tint in [amber, pale]) {
      testWidgets('CategoryItem icon contrast ${entry.key} $tint',
          (tester) async {
        final theme = await _pump(
          tester,
          entry.value,
          CategoryItem(category: _category(tint)),
        );
        final icon = tester.widget<Icon>(find.byIcon(
          tester.widgetList<Icon>(find.byType(Icon)).first.icon!,
        ));
        _expectContrast(theme, tint, icon.color!);

        final box = tester
            .widgetList<Container>(find.byType(Container))
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((d) => d.color != null);
        expect(box.color, tint.withValues(alpha: 0.15));
      });

      testWidgets('TransactionItem icon contrast ${entry.key} $tint',
          (tester) async {
        for (final type in [TransactionType.expense, TransactionType.income]) {
          final theme = await _pump(
            tester,
            entry.value,
            TransactionItem(
              transaction: _tx(type),
              categoryName: 'Cat',
              categoryIconName: 'restaurant',
              categoryColor: tint,
            ),
          );
          final icon = tester.widgetList<Icon>(find.byType(Icon)).first;
          _expectContrast(theme, tint, icon.color!);

          final box = tester
              .widgetList<Container>(find.byType(Container))
              .map((c) => c.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.color != null);
          expect(box.color, tint.withValues(alpha: 0.15));
          // Amount keeps its financial color.
          final amount = tester.widget<Text>(find.textContaining('₫').first);
          expect(amount.style?.color, isNotNull);
        }
      });
    }
  }
}
