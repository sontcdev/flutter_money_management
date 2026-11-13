import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budget_edit_screen.dart';
import 'package:flutter_money_management/src/features/budgets/repositories/budget_repository.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/screens/category_edit_screen.dart';
import 'package:flutter_money_management/src/features/categories/repositories/category_repository.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCategoryRepository implements CategoryRepository {
  int creates = 0;
  Completer<void>? gate;

  @override
  Future<Category> createCategory(
    Category category, {
    String? workspaceIdOverride,
  }) async {
    creates++;
    if (gate != null) await gate!.future;
    return category.copyWith(id: 'new');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBudgetRepository implements BudgetRepository {
  int updates = 0;
  Completer<void>? gate;

  @override
  Future<void> updateBudget(
    Budget budget, {
    String? workspaceIdOverride,
  }) async {
    updates++;
    if (gate != null) await gate!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _now = DateTime(2026, 1, 1);

Category _category() => Category(
      id: 'c1',
      name: 'Food',
      iconName: 'shopping_cart',
      colorValue: 0xFF9E9E9E,
      createdAt: _now,
      updatedAt: _now,
    );

Budget _budget() => Budget(
      id: 'b1',
      categoryId: 'c1',
      periodType: PeriodType.monthly,
      periodStart: DateTime(2026, 1, 1),
      periodEnd: DateTime(2026, 1, 31),
      limitCents: 10000000,
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: _now,
      updatedAt: _now,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  _FakeCategoryRepository? categoryRepo,
  _FakeBudgetRepository? budgetRepo,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        categoriesProvider.overrideWith((ref) async => [_category()]),
        transactionsProvider.overrideWith((ref) async => []),
        budgetRepositoryProvider
            .overrideWithValue(budgetRepo ?? _FakeBudgetRepository()),
        if (categoryRepo != null)
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => screen),
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
  group('BudgetEditScreen', () {
    testWidgets('clean back pops without dialog', (tester) async {
      await _pump(tester, BudgetEditScreen(budget: _budget()));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(BudgetEditScreen), findsNothing);
    });

    testWidgets('create mode untouched is clean', (tester) async {
      await _pump(tester, const BudgetEditScreen());
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(BudgetEditScreen), findsNothing);
    });

    testWidgets('edit then back: Keep stays, Discard pops', (tester) async {
      await _pump(tester, BudgetEditScreen(budget: _budget()));
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(BudgetEditScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(BudgetEditScreen), findsNothing);
    });

    testWidgets('empty limit shows inline error on Done', (tester) async {
      await _pump(tester, const BudgetEditScreen());
      final limit = find.byType(TextFormField);
      await tester.tap(limit);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Please enter limit'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('BudgetEditScreen double submit', () {
    testWidgets('Done twice while pending saves once and pops once',
        (tester) async {
      final repo = _FakeBudgetRepository()..gate = Completer<void>();
      await _pump(tester, BudgetEditScreen(budget: _budget()),
          budgetRepo: repo);
      await tester.tap(find.byType(TextFormField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.updates, 1);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(repo.updates, 1);
      expect(find.byType(BudgetEditScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('CategoryEditScreen', () {
    testWidgets('clean back pops without dialog', (tester) async {
      await _pump(tester, CategoryEditScreen(category: _category()));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(CategoryEditScreen), findsNothing);
    });

    testWidgets('edit then back: Keep stays, Discard pops', (tester) async {
      await _pump(tester, CategoryEditScreen(category: _category()));
      await tester.enterText(find.byType(TextFormField), 'Food2');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryEditScreen), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryEditScreen), findsNothing);
    });

    testWidgets('empty name shows inline error and Done does not save',
        (tester) async {
      final repo = _FakeCategoryRepository();
      await _pump(tester, const CategoryEditScreen(), categoryRepo: repo);
      await tester.tap(find.byType(TextFormField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Please enter category name'), findsOneWidget);
      expect(repo.creates, 0);
    });

    testWidgets('Done submits save with valid name', (tester) async {
      final repo = _FakeCategoryRepository();
      await _pump(tester, const CategoryEditScreen(), categoryRepo: repo);
      await tester.enterText(find.byType(TextFormField), 'Travel');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(find.byType(CategoryEditScreen), findsNothing);
    });

    testWidgets('Done twice while pending saves once and pops once',
        (tester) async {
      final repo = _FakeCategoryRepository()..gate = Completer<void>();
      await _pump(tester, const CategoryEditScreen(), categoryRepo: repo);
      await tester.enterText(find.byType(TextFormField), 'Travel');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.creates, 1);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(find.byType(CategoryEditScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
