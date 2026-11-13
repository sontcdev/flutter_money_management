import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/edit_transaction_screen.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_attachment_repository.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';

class _TransactionRepository extends Mock implements TransactionRepository {}

class _AttachmentRepository extends Mock
    implements TransactionAttachmentRepository {}

const _amber = Color(0xFFFFC107);
const _pale = Color(0xFFF5F5DC);
const _dark = Color(0xFF1A237E);

final _now = DateTime(2026, 10, 10);

List<Category> _categories() => [
      for (final e in {
        'amber': _amber,
        'pale': _pale,
        'dark': _dark,
      }.entries)
        Category(
          id: e.key,
          name: 'Cat ${e.key}',
          iconName: 'restaurant',
          colorValue: e.value.toARGB32(),
          createdAt: _now,
          updatedAt: _now,
        ),
    ];

final _workspace = Workspace(
  id: 'workspace',
  name: 'Workspace',
  type: 'shared',
  ownerId: 'other-user',
  role: 'member',
  memberCount: 2,
  createdAt: _now,
  updatedAt: _now,
);

final _wallets = [
  Wallet(
    id: 'cash',
    workspaceId: 'workspace',
    name: 'Cash',
    iconName: 'wallet',
    colorValue: Colors.blue.toARGB32(),
    createdAt: _now,
    updatedAt: _now,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required bool edit,
  required bool dark,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final repository = _TransactionRepository();
  final attachments = _AttachmentRepository();
  when(() => repository.getTransactionById('transaction')).thenAnswer(
    (_) async => model.Transaction(
      id: 'transaction',
      amountCents: 3000000,
      currency: 'VND',
      dateTime: _now,
      type: model.TransactionType.expense,
      categoryId: 'amber',
      walletId: 'cash',
      createdAt: _now,
      updatedAt: _now,
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
      activeWorkspaceProvider.overrideWithValue(_workspace),
      workspaceListProvider.overrideWith((ref) async => [_workspace]),
      transactionRepositoryProvider.overrideWithValue(repository),
      transactionAttachmentRepositoryProvider.overrideWithValue(attachments),
      transactionCanManageProvider('transaction')
          .overrideWith((ref) async => true),
      transactionReceiptImageUrlProvider('transaction')
          .overrideWith((ref) async => null),
      categoriesProvider.overrideWith((ref) async => _categories()),
      categoriesForWorkspaceProvider
          .overrideWith((ref, id) async => _categories()),
      walletsProvider.overrideWith((ref) async => _wallets),
      walletsForWorkspaceProvider.overrideWith((ref, id) async => _wallets),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: edit
          ? const EditTransactionScreen(transactionId: 'transaction')
          : const AddTransactionScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final edit in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
          '${edit ? 'edit' : 'add'} ${dark ? 'dark' : 'light'}: category chip '
          'text and icon are readable over tint', (tester) async {
        await _pump(tester, edit: edit, dark: dark);
        final theme = Theme.of(tester.element(find.byType(Scaffold).first));
        for (final c in _categories()) {
          final base = Color(c.colorValue);
          final text = tester.widget<Text>(find.text(c.name));
          final icon = tester
              .widgetList<CategoryIconWidget>(find
                      .ancestor(
                          of: find.text(c.name), matching: find.byType(Row))
                      .first
                      .evaluate()
                      .isEmpty
                  ? find.byType(CategoryIconWidget)
                  : find.descendant(
                      of: find
                          .ancestor(
                              of: find.text(c.name), matching: find.byType(Row))
                          .first,
                      matching: find.byType(CategoryIconWidget)))
              .first;
          final tint = base.withValues(alpha: 0.2);
          for (final bg in [
            theme.colorScheme.surface,
            theme.scaffoldBackgroundColor
          ]) {
            final fill = Color.alphaBlend(tint, bg);
            expect(AppSurfaceTokens.contrast(text.style!.color!, fill),
                greaterThanOrEqualTo(4.5),
                reason: '${c.name} text');
            expect(AppSurfaceTokens.contrast(icon.color!, fill),
                greaterThanOrEqualTo(3.0),
                reason: '${c.name} icon');
          }
          // Border keeps the stored color; fill is the unchanged 20% tint.
          final box = tester.widget<Container>(find
              .ancestor(of: find.text(c.name), matching: find.byType(Container))
              .first);
          final deco = box.decoration! as BoxDecoration;
          expect(deco.color, tint);
          expect((deco.border! as Border).top.color, base);
        }
      });
    }
  }

  testWidgets('selected chip keeps thicker border and readable text',
      (tester) async {
    await _pump(tester, edit: true, dark: false);
    final box = tester.widget<Container>(find
        .ancestor(of: find.text('Cat amber'), matching: find.byType(Container))
        .first);
    final border = (box.decoration! as BoxDecoration).border! as Border;
    expect(border.top.width, 3);
    expect(border.top.color, _amber);
  });
}
