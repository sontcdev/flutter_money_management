// filepath: lib/src/ui/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../utils/currency_formatter.dart';
import '../../theme/app_colors.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactions),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTransactions,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return categoriesAsync.when(
            data: (categories) {
              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final category = categories.firstWhere(
                    (c) => c.id == transaction.categoryId,
                    orElse: () => Category(
                      id: 0,
                      name: 'Unknown',
                      iconName: '📦',
                      colorValue: Colors.grey.toARGB32(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );

                  final isExpense = transaction.type == TransactionType.expense;
                  final amountColor = isExpense ? AppColors.expense : AppColors.income;
                  final amountPrefix = isExpense ? '-' : '+';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(category.colorValue).withOpacity(0.1),
                      child: Text(
                        category.iconName,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(transaction.dateTime),
                    ),
                    trailing: Text(
                      '$amountPrefix${CurrencyFormatter.formatVNDFromCents(transaction.amountCents)}',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading categories: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading transactions: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-transaction');
          if (result == true) {
            ref.invalidate(transactionsProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

