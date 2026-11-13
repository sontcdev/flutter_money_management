import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/presentation/screens/edit_transaction_screen.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_attachment_repository.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';

class _TransactionRepository extends Mock implements TransactionRepository {}

class _AttachmentRepository extends Mock
    implements TransactionAttachmentRepository {}

Future<void> _pump(WidgetTester tester, {String? note}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime(2026, 10, 10);
  final repository = _TransactionRepository();
  final attachments = _AttachmentRepository();
  when(() => repository.getTransactionById('transaction')).thenAnswer(
    (_) async => model.Transaction(
      id: 'transaction',
      amountCents: 3000000,
      currency: 'VND',
      dateTime: now,
      type: model.TransactionType.expense,
      categoryId: 'food',
      walletId: 'cash',
      note: note,
      createdAt: now,
      updatedAt: now,
    ),
  );
  when(() =>
          attachments.getLatestReceiptAttachmentByTransactionId('transaction'))
      .thenAnswer((_) async => null);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
      themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
      themeColorProvider.overrideWith((ref) => ThemeColorNotifier(prefs)),
      fontScaleProvider.overrideWith((ref) => FontScaleNotifier(prefs)),
      activeWorkspaceProvider.overrideWithValue(Workspace(
        id: 'workspace',
        name: 'Workspace',
        type: 'shared',
        ownerId: 'other-user',
        role: 'member',
        memberCount: 2,
        createdAt: now,
        updatedAt: now,
      )),
      transactionRepositoryProvider.overrideWithValue(repository),
      transactionAttachmentRepositoryProvider.overrideWithValue(attachments),
      transactionCanManageProvider('transaction')
          .overrideWith((ref) async => true),
      transactionReceiptImageUrlProvider('transaction')
          .overrideWith((ref) async => null),
      categoriesProvider.overrideWith((ref) async => [
            Category(
              id: 'food',
              name: 'Food',
              iconName: 'restaurant',
              colorValue: Colors.blue.toARGB32(),
              createdAt: now,
              updatedAt: now,
            )
          ]),
      walletsProvider.overrideWith((ref) async => [
            Wallet(
              id: 'cash',
              workspaceId: 'workspace',
              name: 'Cash',
              iconName: 'wallet',
              colorValue: Colors.blue.toARGB32(),
              createdAt: now,
              updatedAt: now,
            )
          ]),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) =>
                  const EditTransactionScreen(transactionId: 'transaction'),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('clean form pops without a discard dialog', (tester) async {
    await _pump(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(EditTransactionScreen), findsNothing);
  });

  testWidgets('changed amount asks to discard; Keep stays, Discard pops',
      (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '5000000');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(AlertDialog)))!;
    expect(find.text(l10n.discardChangesTitle), findsOneWidget);

    await tester.tap(find.text(l10n.keepEditing));
    await tester.pumpAndSettle();
    expect(find.byType(EditTransactionScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.discard));
    await tester.pumpAndSettle();
    expect(find.byType(EditTransactionScreen), findsNothing);
  });

  testWidgets('empty amount shows an inline error on save', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump(const Duration(milliseconds: 200));
    final l10n = AppLocalizations.of(
        tester.element(find.byType(EditTransactionScreen)))!;
    expect(find.text(l10n.amountRequiredError), findsOneWidget);
  });

  testWidgets('note section is expanded when a note exists', (tester) async {
    await _pump(tester, note: 'Lunch');
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('note section is collapsed when no note or receipt',
      (tester) async {
    await _pump(tester);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
