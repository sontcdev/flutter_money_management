import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/providers/budget_providers.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/report_calendar_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/summary_bar.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/transaction_management_screen.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/workspace_management_screen.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

SocketException _networkError() =>
    const SocketException('Failed host lookup: x.supabase.co');

Widget _app(List<Override> overrides, Widget home) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
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

void _expectSafeError() {
  expect(find.textContaining('supabase.co'), findsNothing);
  expect(find.textContaining('Exception'), findsNothing);
  expect(find.text('Retry'), findsOneWidget);
}

void main() {
  testWidgets('report calendar monthly summary error retries', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final month = DateTime(2025, 11, 1);
    var calls = 0;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app([
      sharedPreferencesProvider.overrideWithValue(prefs),
      localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
      themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
      themeColorProvider.overrideWith((ref) => ThemeColorNotifier(prefs)),
      monthStartDayProvider.overrideWith((ref) => MonthStartDayNotifier(prefs)),
      selectedMonthProvider.overrideWith((ref) => month),
      calendarDataProvider(month).overrideWith((ref) => {}),
      monthlySummaryProvider(month).overrideWith((ref) async {
        calls++;
        if (calls == 1) throw _networkError();
        return {'income': 0, 'expense': 0, 'net': 0};
      }),
      transactionGroupsProvider(month).overrideWith((ref) => []),
    ], const ReportCalendarScreen()));
    await tester.pumpAndSettle();

    expect(calls, 1);
    _expectSafeError();
    expect(find.byType(SummaryBar), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(SummaryBar), findsOneWidget);
  });

  final now = DateTime(2025, 11, 1);
  final tx = Transaction(
    id: 't1',
    amountCents: 1000,
    currency: 'VND',
    dateTime: now,
    categoryId: 'c1',
    type: TransactionType.expense,
    createdAt: now,
    updatedAt: now,
  );
  final category = Category(
    id: 'c1',
    name: 'Groceries',
    iconName: 'inventory_2',
    colorValue: 0xFF2196F3,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('transaction management transactions error retries',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_app([
      transactionsProvider.overrideWith((ref) async {
        calls++;
        if (calls == 1) throw _networkError();
        return [tx];
      }),
      categoriesProvider.overrideWith((ref) async => [category]),
      budgetsProvider.overrideWith((ref) async => []),
    ], const TransactionManagementScreen()));
    await tester.pumpAndSettle();

    expect(calls, 1);
    _expectSafeError();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('transaction management categories error retries',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_app([
      transactionsProvider.overrideWith((ref) async => [tx]),
      categoriesProvider.overrideWith((ref) async {
        calls++;
        if (calls == 1) throw _networkError();
        return [category];
      }),
      budgetsProvider.overrideWith((ref) async => []),
    ], const TransactionManagementScreen()));
    await tester.pumpAndSettle();

    expect(calls, 1);
    _expectSafeError();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('workspace management members error retries', (tester) async {
    final workspace = Workspace(
      id: 'w1',
      name: 'Team',
      type: 'shared',
      ownerId: 'owner-1',
      role: 'member',
      createdAt: now,
      updatedAt: now,
    );
    var calls = 0;
    await tester.pumpWidget(_app([
      activeWorkspaceProvider.overrideWithValue(workspace),
      workspacePendingInvitesProvider.overrideWith((ref) async => []),
      workspaceMembersProvider.overrideWith((ref) async {
        calls++;
        if (calls == 1) throw _networkError();
        return [
          WorkspaceMemberSummary(
            memberId: 'm1',
            userId: 'owner-1',
            displayName: 'Alice Tester',
            email: null,
            avatarUrl: null,
            role: 'owner',
            membershipStatus: 'active',
            joinedAt: now,
          ),
        ];
      }),
    ], const WorkspaceManagementScreen()));
    await tester.pumpAndSettle();

    expect(calls, 1);
    _expectSafeError();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.textContaining('Alice Tester'), findsWidgets);
  });
}
