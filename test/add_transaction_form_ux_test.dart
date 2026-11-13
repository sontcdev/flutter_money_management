import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';

Workspace _ws(String id, String name) => Workspace(
      id: id,
      name: name,
      type: 'shared',
      ownerId: 'u',
      role: 'owner',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Future<void> _pump(WidgetTester tester, {bool twoWorkspaces = false}) async {
  final a = _ws('w1', 'Alpha');
  final b = _ws('w2', 'Beta');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceListProvider
            .overrideWith((ref) async => twoWorkspaces ? [a, b] : []),
        activeWorkspaceProvider.overrideWithValue(twoWorkspaces ? a : null),
        if (twoWorkspaces) ...[
          categoriesForWorkspaceProvider
              .overrideWith((ref, id) async => <Category>[]),
          walletsForWorkspaceProvider
              .overrideWith((ref, id) async => <Wallet>[]),
        ],
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('clean form pops without a dialog', (tester) async {
    await _pump(tester);
    expect(find.byType(AddTransactionScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AddTransactionScreen), findsNothing);
  });

  testWidgets('dirty form asks; Keep stays, Discard pops', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '5000');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AddTransactionScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(AddTransactionScreen), findsNothing);
  });

  testWidgets('empty amount submit shows inline error', (tester) async {
    await _pump(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AddTransactionScreen)),
    )!;

    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text(l10n.amountRequiredError), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '1000');
    await tester.pump();
    expect(find.text(l10n.amountRequiredError), findsNothing);

    // Let the keyboard-toolbar delay in AppInput elapse before teardown.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('non-empty amount that parses to no value still counts as dirty',
      (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.pump();
    final text = tester
        .widget<TextFormField>(find.byType(TextFormField).first)
        .controller!
        .text;
    expect(text.trim(), isNotEmpty);
    expect(CurrencyFormatter.parseVND(text), anyOf(isNull, 0));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('workspace-only change is dirty', (tester) async {
    await _pump(tester, twoWorkspaces: true);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing, reason: 'untouched = clean');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
