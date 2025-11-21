// filepath: lib/src/ui/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';

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
                      iconName: 'help_outline',
                      colorValue: Colors.grey.toARGB32(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(category.colorValue),
                      child: Icon(
                        _getIconData(category.iconName),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      '${transaction.dateTime.day}/${transaction.dateTime.month}/${transaction.dateTime.year}',
                    ),
                    trailing: Text(
                      '${transaction.type == TransactionType.expense ? '-' : '+'}\$${(transaction.amountCents / 100).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: transaction.type == TransactionType.expense
                            ? Colors.red
                            : Colors.green,
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
        onPressed: () {
          Navigator.pushNamed(context, '/add-transaction');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map icon names to IconData
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'home':
        return Icons.home;
      case 'phone_android':
        return Icons.phone_android;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'sports_esports':
        return Icons.sports_esports;
      default:
        return Icons.help_outline;
    }
  }
}

