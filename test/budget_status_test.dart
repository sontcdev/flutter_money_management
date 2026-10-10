import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:flutter_money_management/src/features/budgets/providers/budget_providers.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

Budget _budget({
  String id = 'budget-1',
  int limitCents = 10000,
  required int consumedCents,
}) {
  final now = DateTime(2026, 10, 1);
  return Budget(
    id: id,
    categoryId: 'cat-1',
    periodType: PeriodType.monthly,
    periodStart: now,
    periodEnd: DateTime(2026, 10, 31),
    limitCents: limitCents,
    consumedCents: consumedCents,
    allowOverdraft: false,
    overdraftCents: 0,
    createdAt: now,
    updatedAt: now,
  );
}

Category _category() {
  final now = DateTime(2026, 10, 1);
  return Category(
    id: 'cat-1',
    name: 'Food',
    iconName: 'restaurant',
    colorValue: 0xFF4CAF50,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BudgetStatus thresholds', () {
    test('79% used is on track', () {
      expect(_budget(consumedCents: 7900).status, BudgetStatus.onTrack);
    });

    test('80% used is near limit', () {
      expect(_budget(consumedCents: 8000).status, BudgetStatus.nearLimit);
    });

    test('100% used is still near limit', () {
      expect(_budget(consumedCents: 10000).status, BudgetStatus.nearLimit);
    });

    test('101% used is exceeded', () {
      expect(_budget(consumedCents: 10100).status, BudgetStatus.exceeded);
    });

    test('zero limit is on track', () {
      expect(
        _budget(limitCents: 0, consumedCents: 500).status,
        BudgetStatus.onTrack,
      );
    });
  });

  testWidgets('over-limit budget card shows the exceeded warning icon',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final budget = _budget(consumedCents: 12000);
    final category = _category();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          budgetsWithConsumedProvider.overrideWith((ref) async => [budget]),
          categoriesProvider.overrideWith((ref) async => [category]),
          categoryProvider('cat-1').overrideWith((ref) async => category),
          canManageWorkspaceContentProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('vi'), Locale('ja')],
          home: BudgetsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final warningIcon = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          widget.icon == Icons.warning_amber_rounded &&
          widget.semanticLabel == 'Exceeded',
    );
    expect(warningIcon, findsOneWidget);
    expect(find.text('120% used'), findsOneWidget);
    expect(find.byTooltip('Budget actions'), findsOneWidget);
  });
}
