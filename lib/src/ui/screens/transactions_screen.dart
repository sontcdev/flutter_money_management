// path: lib/src/ui/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../widgets/transaction_item.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactions)),
      body: transactions.when(
        data: (transactionsList) {
          if (transactionsList.isEmpty) {
            return Center(
              child: Text(l10n.noTransactions),
            );
          }

          final grouped = _groupByDate(transactionsList);

          return categories.when(
            data: (categoriesList) {
              return accounts.when(
                data: (accountsList) {
                  return ListView.builder(
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          ...entry.value.map((transaction) {
                            final category = categoriesList.firstWhere(
                              (c) => c.id == transaction.categoryId,
                              orElse: () => categoriesList.isNotEmpty ? categoriesList.first : throw StateError('No categories'),
                            );
                            final account = accountsList.firstWhere(
                              (a) => a.id == transaction.accountId,
                              orElse: () => accountsList.isNotEmpty ? accountsList.first : throw StateError('No accounts'),
                            );
                            return TransactionItem(
                              transaction: transaction,
                              categoryName: category.name,
                              accountName: account.name,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/transaction-detail',
                                  arguments: transaction.id,
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<MapEntry<String, List<Transaction>>> _groupByDate(
      List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    for (final transaction in transactions) {
      final dateKey = '${transaction.dateTime.year}-${transaction.dateTime.month}-${transaction.dateTime.day}';
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }
    return grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }
}

