import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_money_management/src/features/home/presentation/screens/today_screen.dart';
import 'package:flutter_money_management/src/features/notifications/providers/notification_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';

const _accents = <Color>[
  Color(0xFF4F46E5),
  Color(0xFFFFEB3B), // pale yellow
  Color(0xFFFFFFFF), // white
  Color(0xFF000000), // black
  Color(0xFF00BFA5),
  Color(0xFFE91E63),
  Color(0xFFB71C1C),
];

Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  bool populated = true,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final workspace = Workspace(
    id: 'workspace',
    name: 'Household',
    type: 'personal',
    ownerId: 'user',
    role: 'owner',
    createdAt: now,
    updatedAt: now,
  );
  final transactions = populated
      ? [
          model.Transaction(
            id: 't',
            amountCents: 3000000,
            currency: 'VND',
            dateTime: now,
            type: model.TransactionType.expense,
            walletId: 'cash',
            createdAt: now,
            updatedAt: now,
          )
        ]
      : <model.Transaction>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWithValue(User(
        id: 'user',
        appMetadata: {},
        userMetadata: {'display_name': 'Review'},
        aud: 'authenticated',
        createdAt: now.toIso8601String(),
      )),
      activeWorkspaceProvider.overrideWithValue(workspace),
      workspaceListProvider.overrideWith((ref) async => [workspace]),
      canManageWorkspaceContentProvider.overrideWith((ref) => true),
      unreadNotificationCountProvider.overrideWith((ref) async => 0),
      myNotificationsProvider.overrideWith((ref) async => []),
      myWorkspaceInviteNotificationsProvider.overrideWith((ref) async => []),
      upcomingRecurringOccurrencesProvider.overrideWith((ref) async => []),
      transactionsProvider.overrideWith((ref) async => transactions),
      budgetsProvider.overrideWith((ref) async => []),
      budgetsWithConsumedProvider.overrideWith((ref) async => []),
      categoriesProvider.overrideWith((ref) async => []),
      walletsProvider.overrideWith((ref) async => []),
      walletBalancesProvider.overrideWith((ref) async => {}),
    ],
    child: MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

ThemeData _theme(Brightness b, [Color seed = const Color(0xFF4F46E5)]) =>
    ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: b)
          .copyWith(primary: seed),
    );

Color? _todayBackground(WidgetTester tester) => tester
    .widget<Scaffold>(find
        .descendant(
            of: find.byType(TodayScreen), matching: find.byType(Scaffold))
        .first)
    .backgroundColor;

void main() {
  testWidgets('light Today uses #F7F9FC background', (tester) async {
    await _pump(tester, theme: _theme(Brightness.light));
    expect(_todayBackground(tester), const Color(0xFFF7F9FC));
    expect(find.byKey(const ValueKey('today-hero-mint')), findsOneWidget);
  });

  testWidgets('light empty state keeps background', (tester) async {
    await _pump(tester, theme: _theme(Brightness.light), populated: false);
    expect(_todayBackground(tester), const Color(0xFFF7F9FC));
  });

  testWidgets('dark Today background and nav unchanged', (tester) async {
    final theme = _theme(Brightness.dark);
    await _pump(tester, theme: theme);
    expect(_todayBackground(tester), isNull);
    expect(find.byKey(const ValueKey('today-hero-mint')), findsNothing);
    expect(find.byKey(const ValueKey('nav-selected-pill')), findsNothing);
  });

  testWidgets('custom accent drives nav pill and FAB', (tester) async {
    const accent = Color(0xFFE91E63);
    await _pump(tester, theme: _theme(Brightness.light, accent));
    final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton));
    expect(fab.backgroundColor, accent);
    final pill = tester.widget<Container>(
        find.byKey(const ValueKey('nav-selected-pill')));
    final color = (pill.decoration as BoxDecoration).color!;
    expect(color.a, closeTo(0.12, 0.01));
    expect(color.r, closeTo(accent.r, 0.01));
    expect(color.g, closeTo(accent.g, 0.01));
  });

  test('hero gradient endpoints keep >=4.5 contrast with navy text', () {
    for (final accent in _accents) {
      for (final stop in AppSurfaceTokens.heroGradient(accent)) {
        expect(AppSurfaceTokens.contrast(AppSurfaceTokens.navy, stop),
            greaterThanOrEqualTo(4.5),
            reason: 'accent $accent stop $stop');
        // Mini-stat panel (navy @14% over the stop).
        final panel = Color.alphaBlend(
            AppSurfaceTokens.navy.withValues(alpha: 0.14), stop);
        expect(AppSurfaceTokens.contrast(AppSurfaceTokens.navy, panel),
            greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('nav colors reach contrast on white for every accent', () {
    for (final accent in _accents) {
      final c = AppSurfaceTokens.ensureContrast(accent, Colors.white);
      expect(AppSurfaceTokens.contrast(c, Colors.white), greaterThanOrEqualTo(4.5),
          reason: 'accent $accent');
    }
    expect(AppSurfaceTokens.contrast(AppSurfaceTokens.inactive, Colors.white),
        greaterThanOrEqualTo(4.5));
  });
}
