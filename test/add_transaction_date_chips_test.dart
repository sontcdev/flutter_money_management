import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';

void main() {
  const sizes = {'portrait': Size(390, 844), 'landscape': Size(844, 390)};
  for (final code in ['vi', 'en', 'ja']) {
    for (final scale in [1.0, 1.3]) {
      sizes.forEach((name, size) {
        testWidgets('date options readable $code x$scale $name',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                workspaceListProvider.overrideWith((ref) async => []),
                activeWorkspaceProvider.overrideWithValue(null),
              ],
              child: MaterialApp(
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('vi'),
                  Locale('en'),
                  Locale('ja')
                ],
                locale: Locale(code),
                builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(c)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const AddTransactionScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
              tester.element(find.byType(AddTransactionScreen)))!;
          for (final label in [l10n.today, l10n.yesterday]) {
            final f = find.text(label);
            await tester.ensureVisible(f);
            await tester.pumpAndSettle();
            expect(f, findsOneWidget);
            // Single line: height stays below two text lines.
            final h = tester.getSize(f).height;
            final single = scale * 14 * 1.6;
            expect(h, lessThan(single * 1.5), reason: label);
          }
          expect(tester.takeException(), isNull);
        });
      });
    }
  }
}
