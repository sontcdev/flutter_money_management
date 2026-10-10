import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/presentation/widgets/account_deletion_dialog.dart';

void main() {
  Future<void> open(
      WidgetTester tester, Future<void> Function() onDelete) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => showDialog<Object>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AccountDeletionDialog(
                        onDelete: onDelete, onWebRequest: () async {})),
                child: const Text('Open'),
              ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('requires exact confirmation and closes on success',
      (tester) async {
    var calls = 0;
    await open(tester, () async {
      calls++;
    });
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(AccountDeletionDialog), findsNothing);
  });

  testWidgets('failure keeps confirmation available for retry', (tester) async {
    await open(tester, () async {
      throw Exception('failure');
    });
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Deletion could not be completed. Retry to finish deleting your account.'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });

  testWidgets('deletion stays open and disables actions while pending',
      (tester) async {
    final deletion = Completer<void>();
    var calls = 0;
    await open(tester, () {
      calls++;
      return deletion.future;
    });
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    for (final button in tester.widgetList<TextButton>(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextButton)))) {
      expect(button.onPressed, isNull);
    }
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AccountDeletionDialog), findsOneWidget);
    expect(calls, 1);
    deletion.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AccountDeletionDialog), findsNothing);
  });
}
