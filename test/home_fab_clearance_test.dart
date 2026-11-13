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
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets('Home empty state clears FAB $locale $size', (tester) async {
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
        final transactions = <model.Transaction>[];
        final budgets = <Budget>[];
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
        final cta = find.widgetWithIcon(OutlinedButton, Icons.add);
        expect(cta, findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        final l10n = AppLocalizations.of(tester.element(cta))!;
        expect(
            find.descendant(of: cta, matching: find.text(l10n.addTransaction)),
            findsOneWidget);
        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -3000));
        await tester.pumpAndSettle();
        final content = tester.getRect(find
            .descendant(of: scrollable, matching: find.byType(Column))
            .first);
        final fab = tester.getRect(find.byType(FloatingActionButton));
        expect(content.bottom, lessThanOrEqualTo(fab.top));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
