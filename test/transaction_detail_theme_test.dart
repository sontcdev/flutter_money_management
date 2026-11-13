import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/repositories/category_repository.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';

class _TxRepo extends Mock implements TransactionRepository {}

class _CatRepo extends Mock implements CategoryRepository {}

const _amber = Color(0xFFFFC107);
const _pale = Color(0xFFFFF59D);
final _now = DateTime(2026, 10, 10);

Category _cat(String id, Color c) => Category(
      id: id,
      name: 'Cat $id',
      iconName: 'restaurant',
      colorValue: c.toARGB32(),
      createdAt: _now,
      updatedAt: _now,
    );

model.Transaction _tx(String categoryId) => model.Transaction(
      id: 'tx',
      amountCents: 3000000,
      currency: 'VND',
      dateTime: _now,
      type: model.TransactionType.expense,
      categoryId: categoryId,
      createdAt: _now,
      updatedAt: _now,
    );

Future<ThemeData> _pumpApp(
  WidgetTester tester,
  bool dark,
  Widget home, {
  List<Override> overrides = const [],
}) async {
  final theme = dark ? AppTheme.darkTheme() : AppTheme.lightTheme();
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  return theme;
}

void _expectIcon(ThemeData theme, Color tint, Color fg, Container box) {
  final deco = box.decoration! as BoxDecoration;
  expect(deco.color, tint.withValues(alpha: 0.15)); // stored tint kept
  for (final bg in {theme.colorScheme.surface, theme.scaffoldBackgroundColor}) {
    final fill = Color.alphaBlend(tint.withValues(alpha: 0.15), bg);
    expect(AppSurfaceTokens.contrast(fg, fill), greaterThanOrEqualTo(3));
  }
}

void main() {
  for (final dark in [false, true]) {
    for (final tint in [_amber, _pale]) {
      final label = '${dark ? 'dark' : 'light'} $tint';

      testWidgets('detail icon contrast $label', (tester) async {
        final tx = _TxRepo();
        final cats = _CatRepo();
        when(() => tx.getTransactionById('tx'))
            .thenAnswer((_) async => _tx('c'));
        when(() => cats.getAllCategories())
            .thenAnswer((_) async => [_cat('c', tint)]);
        final theme = await _pumpApp(
          tester,
          dark,
          const TransactionDetailScreen(transactionId: 'tx'),
          overrides: [
            transactionRepositoryProvider.overrideWithValue(tx),
            categoryRepositoryProvider.overrideWithValue(cats),
            transactionCanManageProvider('tx').overrideWith((_) async => false),
            transactionReceiptAttachmentProvider('tx')
                .overrideWith((_) async => null),
            transactionReceiptImageUrlProvider('tx')
                .overrideWith((_) async => null),
            walletsProvider.overrideWith((_) async => []),
          ],
        );
        final icon =
            tester.widget<CategoryIconWidget>(find.byType(CategoryIconWidget));
        final box = tester.widget<Container>(find
            .ancestor(
                of: find.byType(CategoryIconWidget),
                matching: find.byType(Container))
            .first);
        _expectIcon(theme, tint, icon.color!, box);
      });

      testWidgets('list item icon contrast $label', (tester) async {
        final theme = await _pumpApp(
          tester,
          dark,
          Scaffold(
            body: TransactionListItem(
              transactionWithCategory: TransactionWithCategory(
                transaction: _tx('c'),
                categoryName: 'Cat c',
                categoryIconName: 'restaurant',
                categoryColorValue: tint.toARGB32(),
              ),
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        );
        final icon =
            tester.widget<CategoryIconWidget>(find.byType(CategoryIconWidget));
        final box = tester.widget<Container>(find
            .ancestor(
                of: find.byType(CategoryIconWidget),
                matching: find.byType(Container))
            .first);
        _expectIcon(theme, tint, icon.color!, box);
      });
    }
  }
}
