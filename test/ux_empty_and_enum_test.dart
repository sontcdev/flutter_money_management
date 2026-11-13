import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/providers/budget_providers.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/screens/categories_screen.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/workspace_detail_screen.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';

Widget _app(List<Override> overrides, Widget home, String locale) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: home,
    ),
  );
}

void main() {
  final now = DateTime(2025, 11, 1);
  final expenseCategory = Category(
    id: 'c1',
    name: 'Groceries',
    iconName: 'inventory_2',
    colorValue: 0xFF2196F3,
    type: CategoryType.expense,
    createdAt: now,
    updatedAt: now,
  );
  final incomeCategory = Category(
    id: 'c2',
    name: 'Salary',
    iconName: 'inventory_2',
    colorValue: 0xFF2196F3,
    type: CategoryType.income,
    createdAt: now,
    updatedAt: now,
  );
  Budget budget(PeriodType type) => Budget(
        id: 'b-${type.name}',
        categoryId: 'c1',
        periodType: type,
        periodStart: now,
        periodEnd: now,
        limitCents: 100000,
        consumedCents: 0,
        allowOverdraft: false,
        overdraftCents: 0,
        createdAt: now,
        updatedAt: now,
      );

  testWidgets('workspace detail shows localized labels (vi)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app([
      workspaceDetailProvider.overrideWith((ref) async => null),
      categoriesProvider
          .overrideWith((ref) async => [expenseCategory, incomeCategory]),
      budgetsWithConsumedProvider.overrideWith((ref) async => [
            budget(PeriodType.monthly),
            budget(PeriodType.yearly),
            budget(PeriodType.custom),
          ]),
      transactionsProvider.overrideWith((ref) async => []),
    ], const WorkspaceDetailScreen(), 'vi'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
        tester.element(find.byType(WorkspaceDetailScreen)))!;

    await tester.tap(find.descendant(
        of: find.byType(TabBar), matching: find.text(l10n.categories)));
    await tester.pumpAndSettle();
    expect(find.text(l10n.expense), findsOneWidget);
    expect(find.text(l10n.income), findsOneWidget);
    expect(find.text('expense'), findsNothing);
    expect(find.text('income'), findsNothing);

    DefaultTabController.of(tester.element(find.byType(TabBarView)))
        .animateTo(2);
    await tester.pumpAndSettle();
    expect(find.text(l10n.monthly), findsOneWidget);
    expect(find.text(l10n.yearly), findsOneWidget);
    expect(find.text(l10n.custom), findsOneWidget);
    expect(find.text('monthly'), findsNothing);
    expect(find.text('yearly'), findsNothing);
    expect(find.text('custom'), findsNothing);
  });

  testWidgets('categories: expense-only data on Income tab', (tester) async {
    await tester.pumpWidget(_app([
      canManageWorkspaceContentProvider.overrideWithValue(true),
      categoriesProvider.overrideWith((ref) async => [expenseCategory]),
    ], const CategoriesScreen(), 'en'));
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CategoriesScreen)))!;

    await tester.tap(find.text(l10n.income));
    await tester.pumpAndSettle();
    expect(find.text(l10n.noCategoriesInFilter), findsOneWidget);
    expect(find.text(l10n.noCategoriesInFilterMessage), findsOneWidget);
    expect(find.text(l10n.noCategories), findsNothing);
  });

  testWidgets('categories: truly empty keeps noCategories', (tester) async {
    await tester.pumpWidget(_app([
      canManageWorkspaceContentProvider.overrideWithValue(true),
      categoriesProvider.overrideWith((ref) async => <Category>[]),
    ], const CategoriesScreen(), 'en'));
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CategoriesScreen)))!;
    expect(find.text(l10n.noCategories), findsOneWidget);
    expect(find.text(l10n.noCategoriesInFilter), findsNothing);
  });
}
