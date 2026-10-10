@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_money_management/src/features/home/providers/home_tab_provider.dart';
import 'package:flutter_money_management/src/features/notifications/providers/notification_providers.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_date_cell.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';

final _fixed = DateTime(2020, 3, 10, 9);

Workspace _workspace() => Workspace(
      id: 'workspace',
      name: 'Household',
      type: 'personal',
      ownerId: 'user',
      role: 'owner',
      createdAt: _fixed,
      updatedAt: _fixed,
    );

Budget _budget() => Budget(
      id: 'budget',
      categoryId: 'food',
      periodType: PeriodType.custom,
      periodStart: DateTime(2020, 3),
      periodEnd: DateTime(2020, 3, 31),
      limitCents: 10000000,
      consumedCents: 3000000,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: _fixed,
      updatedAt: _fixed,
    );

Category _category() => Category(
      id: 'food',
      name: 'Food and dining',
      iconName: 'restaurant',
      colorValue: Colors.blue.toARGB32(),
      createdAt: _fixed,
      updatedAt: _fixed,
    );

model.Transaction _transaction() => model.Transaction(
      id: 'transaction',
      amountCents: 3000000,
      currency: 'VND',
      dateTime: _fixed,
      type: model.TransactionType.expense,
      categoryId: 'food',
      walletId: 'cash',
      note: 'Lunch with friends',
      createdAt: _fixed,
      updatedAt: _fixed,
    );

Wallet _wallet() => Wallet(
      id: 'cash',
      workspaceId: 'workspace',
      name: 'Household cash',
      iconName: 'wallet',
      colorValue: Colors.blue.toARGB32(),
      createdAt: _fixed,
      updatedAt: _fixed,
    );

Future<List<Override>> _overrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final workspace = _workspace();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    currentUserProvider.overrideWithValue(User(
      id: 'user',
      appMetadata: {},
      userMetadata: {'display_name': 'Review'},
      aud: 'authenticated',
      createdAt: _fixed.toIso8601String(),
    )),
    currentTabProvider.overrideWith((ref) => AppTab.plan),
    activeWorkspaceProvider.overrideWithValue(workspace),
    workspaceListProvider.overrideWith((ref) async => [workspace]),
    canManageWorkspaceContentProvider.overrideWith((ref) => true),
    unreadNotificationCountProvider.overrideWith((ref) async => 0),
    myNotificationsProvider.overrideWith((ref) async => []),
    myWorkspaceInviteNotificationsProvider.overrideWith((ref) async => []),
    upcomingRecurringOccurrencesProvider.overrideWith((ref) async => []),
    transactionsProvider.overrideWith((ref) async => [_transaction()]),
    budgetsProvider.overrideWith((ref) async => [_budget()]),
    budgetsWithConsumedProvider.overrideWith((ref) async => [_budget()]),
    categoriesProvider.overrideWith((ref) async => [_category()]),
    walletsProvider.overrideWith((ref) async => [_wallet()]),
    walletBalancesProvider.overrideWith((ref) async => {'cash': 10000000}),
  ];
}

Widget _app({
  required Brightness brightness,
  required Widget home,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final assetsDir = Platform.environment['UNIT_TEST_ASSETS']!;
    const fontKey = 'google_fonts/Sora-Bold.ttf';
    const codec = StandardMessageCodec();
    final manifestFile = File('$assetsDir/AssetManifest.bin');
    final manifest = Map<Object?, Object?>.from(
      codec.decodeMessage(ByteData.sublistView(
        manifestFile.readAsBytesSync(),
      )) as Map,
    );
    manifest[fontKey] = [
      {'asset': fontKey},
    ];
    final manifestBytes = codec.encodeMessage(manifest)!;
    final fontBytes =
        File('$assetsDir/fonts/MaterialIcons-Regular.otf').readAsBytesSync();
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final key = Uri.decodeFull(utf8.decode(message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        )));
        if (key == 'AssetManifest.bin') return manifestBytes;
        if (key == fontKey) return ByteData.sublistView(fontBytes);
        final file = File('$assetsDir/$key');
        if (!file.existsSync()) return null;
        return ByteData.sublistView(file.readAsBytesSync());
      },
    );
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('home screen $name', (tester) async {
      _setSize(tester, const Size(390, 844));
      await tester.pumpWidget(_app(
        brightness: brightness,
        overrides: await _overrides(),
        home: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_$name.png'),
      );
    });

    testWidgets('budget card $name', (tester) async {
      _setSize(tester, const Size(390, 844));
      await tester.pumpWidget(_app(
        brightness: brightness,
        overrides: await _overrides(),
        home: const BudgetsScreen(showBackButton: false),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_BudgetCard',
        ),
        matchesGoldenFile('budget_card_$name.png'),
      );
    });

    testWidgets('calendar date cell $name', (tester) async {
      _setSize(tester, const Size(200, 200));
      await tester.pumpWidget(_app(
        brightness: brightness,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 56,
              child: CalendarDateCell(
                date: DateTime(2026, 5, 14),
                displayedMonth: DateTime(2026, 5),
                badges: [
                  AmountBadge(amountCents: 150000, isIncome: true),
                  AmountBadge(amountCents: 25050, isIncome: false),
                ],
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CalendarDateCell),
        matchesGoldenFile('calendar_date_cell_$name.png'),
      );
    });
  }
}
