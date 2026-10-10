import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_money_management/src/features/home/providers/home_tab_provider.dart';
import 'package:flutter_money_management/src/features/notifications/providers/notification_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';

void main() {
  for (final locale in ['en', 'vi', 'ja']) {
    for (final size in [const Size(844, 390), const Size(1366, 1024)]) {
      for (final populated in [false, true]) {
        testWidgets('Home tabs fit $locale $size populated=$populated',
            (tester) async {
          tester.view.physicalSize = size;
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
                    id: 'transaction',
                    amountCents: 3000000,
                    currency: 'VND',
                    dateTime: now,
                    type: model.TransactionType.expense,
                    categoryId: 'food',
                    walletId: 'cash',
                    note: 'Lunch with friends',
                    createdAt: now,
                    updatedAt: now,
                  )
                ]
              : <model.Transaction>[];
          final budgets = populated
              ? [
                  Budget(
                    id: 'budget',
                    categoryId: 'food',
                    periodType: PeriodType.monthly,
                    periodStart: DateTime(now.year, now.month),
                    periodEnd: DateTime(now.year, now.month + 1, 0),
                    limitCents: 10000000,
                    consumedCents: 3000000,
                    allowOverdraft: false,
                    overdraftCents: 0,
                    createdAt: now,
                    updatedAt: now,
                  )
                ]
              : <Budget>[];
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
              myWorkspaceInviteNotificationsProvider
                  .overrideWith((ref) async => []),
              upcomingRecurringOccurrencesProvider
                  .overrideWith((ref) async => []),
              transactionsProvider.overrideWith((ref) async => transactions),
              budgetsProvider.overrideWith((ref) async => budgets),
              budgetsWithConsumedProvider.overrideWith((ref) async => budgets),
              categoriesProvider.overrideWith((ref) async => [
                    Category(
                      id: 'food',
                      name: 'Food and dining',
                      iconName: 'restaurant',
                      colorValue: Colors.blue.toARGB32(),
                      createdAt: now,
                      updatedAt: now,
                    )
                  ]),
              walletsProvider.overrideWith((ref) async => [
                    Wallet(
                      id: 'cash',
                      workspaceId: 'workspace',
                      name: 'Household cash',
                      iconName: 'wallet',
                      colorValue: Colors.blue.toARGB32(),
                      createdAt: now,
                      updatedAt: now,
                    )
                  ]),
              walletBalancesProvider
                  .overrideWith((ref) async => {'cash': 10000000}),
            ],
            child: MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: const HomeScreen(),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final context = tester.element(find.byType(HomeScreen));
          final container = ProviderScope.containerOf(context);
          final l10n = AppLocalizations.of(context)!;
          for (final entry in {
            AppTab.activity: l10n.transactions,
            AppTab.plan: l10n.budgets,
            AppTab.insights: l10n.reports,
            AppTab.today: l10n.today,
          }.entries) {
            await tester.tap(find.text(entry.value).last);
            await tester.pumpAndSettle();
            expect(container.read(currentTabProvider), entry.key);
            expect(tester.takeException(), isNull);
            await tester.drag(
                find.byType(Scrollable).first, const Offset(0, -600));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(
              find.byType(FloatingActionButton).hitTestable(), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
