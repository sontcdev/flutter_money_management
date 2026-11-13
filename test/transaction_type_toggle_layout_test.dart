import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_money_management/src/ui/widgets/transaction_type_toggle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final lang in ['vi', 'en', 'ja']) {
    for (final dark in [false, true]) {
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets('$lang dark=$dark $size x$scale', (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            TransactionType? picked;
            late AppLocalizations l10n;
            await tester.pumpWidget(MaterialApp(
              locale: Locale(lang),
              theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Builder(builder: (c) {
                l10n = AppLocalizations.of(c)!;
                return Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TransactionTypeToggle(
                      value: TransactionType.expense,
                      expenseLabel: l10n.expense,
                      incomeLabel: l10n.income,
                      transferLabel: l10n.transfer,
                      onChanged: (v) => picked = v,
                    ),
                  ),
                );
              }),
            ));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final label in [l10n.expense, l10n.income, l10n.transfer]) {
              final t = tester.widget<Text>(find.text(label));
              expect(t.overflow, isNot(TextOverflow.ellipsis));
              expect(t.maxLines, isNull);
              final rect = tester.getRect(find.text(label));
              final toggle = tester.getRect(find.byType(TransactionTypeToggle));
              expect(toggle.contains(rect.topLeft), isTrue);
              expect(toggle.contains(rect.bottomRight), isTrue);
            }
            await tester.tap(find.text(l10n.income));
            expect(picked, TransactionType.income);
            await tester.tap(find.text(l10n.transfer));
            expect(picked, TransactionType.transfer);
            await tester.tap(find.text(l10n.expense));
            expect(picked, TransactionType.expense);
          });
        }
      }
    }
  }
}
