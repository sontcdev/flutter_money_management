// path: lib/src/ui/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/transaction_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Balance Summary
            accountsAsync.when(
              data: (accounts) {
                final totalBalance = accounts.fold<int>(
                  0,
                  (sum, account) => sum + account.balanceCents,
                );
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.balance,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(totalBalance),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),

            // Income/Expense Summary
            transactionsAsync.when(
              data: (transactions) {
                final now = DateTime.now();
                final monthStart = DateTime(now.year, now.month, 1);
                final monthEnd = DateTime(now.year, now.month + 1, 0);

                final monthTransactions = transactions.where((t) =>
                    t.dateTime.isAfter(monthStart) &&
                    t.dateTime.isBefore(monthEnd)).toList();

                final totalIncome = monthTransactions
                    .where((t) => t.type.name == 'income')
                    .fold<int>(0, (sum, t) => sum + t.amountCents);

                final totalExpense = monthTransactions
                    .where((t) => t.type.name == 'expense')
                    .fold<int>(0, (sum, t) => sum + t.amountCents);

                return Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        child: Column(
                          children: [
                            Icon(Icons.arrow_downward, color: AppColors.income),
                            const SizedBox(height: 8),
                            Text(l10n.income),
                            Text(
                              _formatCurrency(totalIncome),
                              style: const TextStyle(
                                color: AppColors.income,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppCard(
                        child: Column(
                          children: [
                            Icon(Icons.arrow_upward, color: AppColors.expense),
                            const SizedBox(height: 8),
                            Text(l10n.expense),
                            Text(
                              _formatCurrency(totalExpense),
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(
                  icon: Icons.account_balance_wallet,
                  label: l10n.accounts,
                  onTap: () => Navigator.pushNamed(context, '/accounts'),
                ),
                _QuickActionButton(
                  icon: Icons.category,
                  label: l10n.categories,
                  onTap: () => Navigator.pushNamed(context, '/categories'),
                ),
                _QuickActionButton(
                  icon: Icons.pie_chart,
                  label: l10n.budgets,
                  onTap: () => Navigator.pushNamed(context, '/budgets'),
                ),
                _QuickActionButton(
                  icon: Icons.bar_chart,
                  label: l10n.reports,
                  onTap: () => Navigator.pushNamed(context, '/reports'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.transactions,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/transactions'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(l10n.noTransactions),
                    ),
                  );
                }

                final recentTransactions = transactions.take(5).toList();

                return categoriesAsync.when(
                  data: (categories) {
                    final categoryMap = {
                      for (var cat in categories) cat.id: cat
                    };

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final transaction = recentTransactions[index];
                        final category = categoryMap[transaction.categoryId];

                        return TransactionItem(
                          transaction: transaction,
                          categoryName: category?.name ?? 'Unknown',
                          categoryColor: category != null
                              ? Color(category.colorValue)
                              : null,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/transaction-detail',
                            arguments: transaction.id,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTransaction),
      ),
    );
  }

  String _formatCurrency(int amountCents) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amountCents / 100);
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

