import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/quick_input_review_sheet.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

final _now = DateTime(2026, 10, 9);
final _categories = [
  Category(
    id: 'food',
    name: 'Food',
    type: CategoryType.expense,
    iconName: 'restaurant',
    colorValue: Colors.blue.toARGB32(),
    createdAt: _now,
    updatedAt: _now,
  ),
];
final _wallets = [
  Wallet(
    id: 'momo',
    workspaceId: 'workspace',
    name: 'Momo',
    iconName: 'wallet',
    colorValue: Colors.blue.toARGB32(),
    isDefault: true,
    createdAt: _now,
    updatedAt: _now,
  ),
];

VoiceParseResult _item(String note) => VoiceParseResult(
      rawText: note,
      note: note,
      amountVnd: 30000,
      date: _now,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Food',
      walletId: 'momo',
      walletName: 'Momo',
    );

Future<List<bool?>> _open(WidgetTester tester, List<VoiceParseResult> items,
    {Future<bool> Function(VoiceParseResult)? onSave}) async {
  final results = <bool?>[];
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async => results.add(await showQuickInputReviewSheet(
            context,
            results: items,
            categories: _categories,
            wallets: _wallets,
            onSave: onSave ?? (_) async => true,
          )),
          child: const Text('Open review'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open review'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _tapClose(WidgetTester tester) async {
  final close = find.widgetWithText(TextButton, 'Close');
  await tester.ensureVisible(close);
  await tester.tap(close);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Close with pending items asks, Keep editing stays open',
      (tester) async {
    final results = await _open(tester, [_item('Cafe'), _item('Lunch')]);
    await _tapClose(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Discard 2 pending items?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickInputReviewSheet), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
    expect(results, isEmpty);
  });

  testWidgets('Close then Discard pops with false', (tester) async {
    final results = await _open(tester, [_item('Cafe')]);
    await _tapClose(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickInputReviewSheet), findsNothing);
    expect(results, [false]);
  });

  testWidgets('Close without pending items closes without prompt',
      (tester) async {
    final results = await _open(tester, [_item('Cafe')]);
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await _tapClose(tester);
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(QuickInputReviewSheet), findsNothing);
    expect(results, [false]);
  });

  testWidgets('system back with pending items asks, Discard pops false',
      (tester) async {
    final results = await _open(tester, [_item('Cafe')]);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickInputReviewSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickInputReviewSheet), findsNothing);
    expect(results, [false]);
  });

  testWidgets('system back without pending items closes without prompt',
      (tester) async {
    final results = await _open(tester, [_item('Cafe')]);
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(QuickInputReviewSheet), findsNothing);
    // System back without pending items pops with null; the caller only
    // treats `== true` as saved.
    expect(results, [isNot(true)]);
  });
}
