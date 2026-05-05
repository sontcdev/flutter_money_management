// path: lib/src/ui/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budgets_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// Main app shell with bottom navigation and FAB
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = useState(0);
    
    final screens = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const BudgetsScreen(showBackButton: false),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    // Determine if FAB should be shown
    final showFAB = currentIndex.value != 4; // Hide on Settings

    return Scaffold(
      body: IndexedStack(
        index: currentIndex.value,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) {
          // Invalidate providers when switching tabs to ensure fresh data
          if (index != currentIndex.value) {
            ref.invalidate(budgetsProvider);
            ref.invalidate(budgetsWithConsumedProvider);
            ref.invalidate(transactionsProvider);
          }
          currentIndex.value = index;
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard ?? 'Dashboard',
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
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: l10n.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
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
