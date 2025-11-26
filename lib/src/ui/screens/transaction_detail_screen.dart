// path: lib/src/ui/screens/transaction_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);

    return FutureBuilder(
      future: Future.wait([
        transactionRepo.getTransactionById(transactionId),
        categoryRepo.getAllCategories(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = snapshot.data![0] as dynamic;
        final categories = snapshot.data![1] as List<dynamic>;
        String categoryName = l10n.noData;
        try {
          final category = categories.firstWhere(
            (c) => c.id == transaction.categoryId,
          );
          categoryName = category.name;
        } catch (_) {
          // Category not found
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transactions),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/add-transaction',
                    arguments: {'transactionId': transactionId},
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.confirmDelete),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.no),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.yes),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await transactionRepo.deleteTransaction(transactionId);
                    // Invalidate budgets to refresh budget data
                    ref.invalidate(budgetsProvider);
                    ref.invalidate(budgetsWithConsumedProvider);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.amount, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        CurrencyFormatter.formatVNDFromCents(transaction.amountCents),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(l10n.date, DateFormat('dd/MM/yyyy').format(transaction.dateTime)),
                      _DetailRow(l10n.category, categoryName),
                      if (transaction.note != null)
                        _DetailRow(l10n.note, transaction.note!),
                    ],
                  ),
                ),
              ),
              if (transaction.receiptPath != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      Image.file(File(transaction.receiptPath!)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

