import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/reports_screen.dart';
import 'package:flutter_money_management/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'today_screen.dart';

/// Tab navigation enum for type-safe tab management
enum AppTab {
  today,
  activity,
  plan,
  insights,
  profile,
}

/// Main app shell with bottom navigation and FAB
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTab = useState(AppTab.today);

    final screens = {
      AppTab.today: const TodayScreen(),
      AppTab.activity: const TransactionsScreen(),
      AppTab.plan: const BudgetsScreen(showBackButton: false),
      AppTab.insights: const ReportsScreen(),
      AppTab.profile: const SettingsScreen(),
    };

    // Determine if FAB should be shown
    final showFAB = currentTab.value != AppTab.profile;

    return Scaffold(
      body: IndexedStack(
        index: currentTab.value.index,
        children: AppTab.values.map((tab) => screens[tab]!).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab.value.index,
        onTap: (index) {
          final newTab = AppTab.values[index];
          // Invalidate providers when switching tabs to ensure fresh data
          if (newTab != currentTab.value) {
            ref.invalidate(budgetsProvider);
            ref.invalidate(budgetsWithConsumedProvider);
            ref.invalidate(transactionsProvider);
          }
          currentTab.value = newTab;
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.today_outlined),
            activeIcon: const Icon(Icons.today),
            label: l10n.today,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: l10n.transactions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.budgets,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights_outlined),
            activeIcon: const Icon(Icons.insights),
            label: l10n.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.settings,
          ),
        ],
      ),
      floatingActionButton: showFAB
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/add-transaction',
                );
                if (result == true) {
                  // Refresh data after adding transaction
                  ref.invalidate(transactionsProvider);
                  ref.invalidate(budgetsProvider);
                  ref.invalidate(budgetsWithConsumedProvider);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
