import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations_en.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/screens/wallet_edit_screen.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/wallets/repositories/wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeWalletRepository implements WalletRepository {
  final List<Wallet> created = [];

  @override
  Future<Wallet> createWallet(
    Wallet wallet, {
    String? workspaceIdOverride,
  }) async {
    created.add(wallet);
    return wallet;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _l10n = AppLocalizationsEn();

Widget _app(_FakeWalletRepository repo, {Wallet? wallet}) => ProviderScope(
      overrides: [walletRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        WalletEditScreen(wallet: wallet, workspaceId: 'w1'),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

Wallet _wallet() => Wallet(
      id: 'wl1',
      workspaceId: 'w1',
      name: 'Main',
      walletType: WalletType.bank,
      iconName: 'account_balance',
      colorValue: 0xFF0077FF,
      openingBalanceMinor: 150000,
      currencyCode: 'VND',
      isDefault: false,
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('clean form pops without dialog (edit mode)', (tester) async {
    await _open(tester, _app(_FakeWalletRepository(), wallet: _wallet()));
    expect(find.byType(WalletEditScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(WalletEditScreen), findsNothing);
    expect(find.text(_l10n.discardChangesTitle), findsNothing);
  });

  testWidgets('clean create form pops without dialog', (tester) async {
    await _open(tester, _app(_FakeWalletRepository()));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WalletEditScreen), findsNothing);
    expect(find.text(_l10n.discardChangesTitle), findsNothing);
  });

  testWidgets('dirty back asks; Keep stays, Discard pops', (tester) async {
    await _open(tester, _app(_FakeWalletRepository(), wallet: _wallet()));

    await tester.enterText(find.byType(TextFormField).first, 'Renamed');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(_l10n.discardChangesTitle), findsOneWidget);

    await tester.tap(find.text(_l10n.keepEditing));
    await tester.pumpAndSettle();
    expect(find.byType(WalletEditScreen), findsOneWidget);
    expect(find.text(_l10n.discardChangesTitle), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.discard));
    await tester.pumpAndSettle();
    expect(find.byType(WalletEditScreen), findsNothing);
  });

  testWidgets('reverting an edit makes the form clean again', (tester) async {
    await _open(tester, _app(_FakeWalletRepository(), wallet: _wallet()));
    await tester.enterText(find.byType(TextFormField).first, 'Other');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, ' Main ');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WalletEditScreen), findsNothing);
    expect(find.text(_l10n.discardChangesTitle), findsNothing);
  });

  testWidgets('empty name shows inline error and does not save',
      (tester) async {
    final repo = _FakeWalletRepository();
    await _open(tester, _app(repo));

    await tester.ensureVisible(find.text(_l10n.save));
    await tester.tap(find.text(_l10n.save));
    await tester.pump();

    expect(find.text(_l10n.categoryNameRequiredError), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(repo.created, isEmpty);
    expect(find.byType(WalletEditScreen), findsOneWidget);
  });

  testWidgets('Next moves focus to balance; Done submits save', (tester) async {
    final repo = _FakeWalletRepository();
    await _open(tester, _app(repo));

    final fields = find.byType(TextFormField);
    await tester.tap(fields.first);
    await tester.pump();
    await tester.enterText(fields.first, 'Cash');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final balanceField = tester.widget<EditableText>(
      find.descendant(of: fields.last, matching: find.byType(EditableText)),
    );
    expect(balanceField.focusNode.hasFocus, isTrue);

    await tester.enterText(fields.last, '5000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
    expect(repo.created.single.name, 'Cash');
    expect(find.byType(WalletEditScreen), findsNothing);
  });
}
