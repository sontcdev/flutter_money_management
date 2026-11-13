import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budget_detail_screen.dart';
import 'package:flutter_money_management/src/features/budgets/repositories/budget_repository.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBudgetRepository implements BudgetRepository {
  _FakeBudgetRepository(this._handler);

  final Future<Budget> Function(int call) _handler;
  int calls = 0;

  @override
  Future<Budget> getBudgetById(String id, {String? workspaceIdOverride}) {
    calls++;
    return _handler(calls);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Budget _budget() => Budget(
      id: 'b1',
      categoryId: 'c1',
      periodType: PeriodType.monthly,
      periodStart: DateTime(2026, 1, 1),
      periodEnd: DateTime(2026, 1, 31),
      limitCents: 100000,
      consumedCents: 25000,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _app(_FakeBudgetRepository repo) => ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(repo),
        categoryProvider.overrideWith((ref, id) async => null),
      ],
      // ignore: prefer_const_constructors
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BudgetDetailScreen(budgetId: 'b1'),
      ),
    );

void main() {
  testWidgets('not found shows localized message and Back, no spinner',
      (tester) async {
    final repo = _FakeBudgetRepository(
        (_) async => throw Exception('Budget not found: b1'));
    await tester.pumpWidget(_app(repo));
    await tester.pump();
    await tester.pump();

    expect(find.text('Budget not found'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('b1'), findsNothing);
  });

  testWidgets('generic error hides raw text and Retry recovers',
      (tester) async {
    final repo = _FakeBudgetRepository((call) async {
      if (call == 1) {
        throw const SocketException('Failed host lookup: abc.supabase.co');
      }
      return _budget();
    });
    await tester.pumpWidget(_app(repo));
    await tester.pump();
    await tester.pump();

    expect(find.text('Unable to load data'), findsOneWidget);
    expect(find.textContaining('supabase'), findsNothing);
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(repo.calls, 2);
    expect(find.text('Unable to load data'), findsNothing);
    expect(find.text('Remaining'), findsOneWidget);
  });

  testWidgets('immediate success shows detail', (tester) async {
    final repo = _FakeBudgetRepository((_) async => _budget());
    await tester.pumpWidget(_app(repo));
    await tester.pump();
    await tester.pump();

    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Unable to load data'), findsNothing);
  });

  testWidgets('rebuild does not refetch', (tester) async {
    final repo = _FakeBudgetRepository((_) async => _budget());
    await tester.pumpWidget(_app(repo));
    await tester.pump();
    await tester.pump();
    expect(repo.calls, 1);

    await tester.pumpWidget(_app(repo));
    await tester.pump();
    await tester.pump();
    expect(repo.calls, 1);
  });
}
