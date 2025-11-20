// path: lib/src/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import 'transactions_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const TransactionsScreen(),
    const CategoriesScreen(),
    const BudgetsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: l10n.transactions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: l10n.categories,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: l10n.budgets,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.transactions,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              transactions.when(
                data: (transactionsList) {
                  if (transactionsList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(l10n.noTransactions),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactionsList.length > 5 ? 5 : transactionsList.length,
                    itemBuilder: (context, index) {
                      final transaction = transactionsList[index];
                      return ListTile(
                        title: Text('${transaction.amountCents / 100}'),
                        subtitle: Text(transaction.dateTime.toString()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/transaction-detail',
                            arguments: transaction.id,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

