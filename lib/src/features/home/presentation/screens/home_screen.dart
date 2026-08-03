import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:flutter_money_management/src/features/home/providers/home_tab_provider.dart';
import 'package:flutter_money_management/src/features/reports/presentation/screens/reports_screen.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'today_screen.dart';

/// Main app shell: 4 bottom-nav tabs with a brand-colored FAB embedded in
/// the middle slot, matching the Claude Design `.navbar`/`.fab` component.
/// Profile/Settings is reached via the avatar icon on [TodayScreen]'s
/// AppBar instead of occupying a nav slot.
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTab = ref.watch(currentTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = {
      AppTab.today: const TodayScreen(),
      AppTab.activity: const TransactionsScreen(),
      AppTab.plan: const BudgetsScreen(showBackButton: false),
      AppTab.insights: const ReportsScreen(),
    };

    void selectTab(AppTab newTab) {
      if (newTab != currentTab) {
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
        ref.invalidate(transactionsProvider);
      }
      ref.read(currentTabProvider.notifier).state = newTab;
    }

    Future<void> openAddTransaction() async {
      final result = await Navigator.pushNamed(context, '/add-transaction');
      if (result == true) {
        ref.invalidate(transactionsProvider);
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
      }
    }

    return Scaffold(
      body: IndexedStack(
        index: currentTab.index,
        children: AppTab.values.map((tab) => screens[tab]!).toList(),
      ),
      bottomNavigationBar: _AppNavBar(
        currentTab: currentTab,
        onTabSelected: selectTab,
        onFabPressed: openAddTransaction,
        isDark: isDark,
        items: [
          _NavItemData(Icons.home_outlined, Icons.home_rounded, l10n.today,
              AppTab.today),
          _NavItemData(Icons.receipt_long_outlined,
              Icons.receipt_long_rounded, l10n.transactions, AppTab.activity),
          _NavItemData(
              Icons.account_balance_wallet_outlined,
              Icons.account_balance_wallet_rounded,
              l10n.budgets,
              AppTab.plan),
          _NavItemData(Icons.insights_outlined, Icons.insights_rounded,
              l10n.reports, AppTab.insights),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final AppTab tab;

  const _NavItemData(this.icon, this.activeIcon, this.label, this.tab);
}

/// Bottom nav bar with 2 nav items, a raised circular FAB, then 2 more
/// nav items — mirrors the mockup's `.navbar` layout exactly.
class _AppNavBar extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onFabPressed;
  final bool isDark;
  final List<_NavItemData> items;

  const _AppNavBar({
    required this.currentTab,
    required this.onTabSelected,
    required this.onFabPressed,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final firstHalf = items.sublist(0, 2);
    final secondHalf = items.sublist(2, 4);
    final primary =
        Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  for (final item in firstHalf)
                    Expanded(child: _buildNavItem(context, item)),
                  const SizedBox(width: 64),
                  for (final item in secondHalf)
                    Expanded(child: _buildNavItem(context, item)),
                ],
              ),
              Positioned(
                top: -20,
                child: GestureDetector(
                  onTap: onFabPressed,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItemData item) {
    final isSelected = item.tab == currentTab;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : (isDark ? AppColors.textLightFaint : AppColors.textFaint);

    return InkWell(
      onTap: () => onTabSelected(item.tab),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? item.activeIcon : item.icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
