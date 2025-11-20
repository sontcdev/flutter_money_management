// path: lib/src/ui/screens/transaction_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/app_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int transactionId;

  const TransactionDetailScreen({Key? key, required this.transactionId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionRepo = ref.read(transactionRepositoryProvider);

    return FutureBuilder(
      future: transactionRepo.getTransactionById(transactionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = snapshot.data!;
        final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transactions),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.editTransaction,
                    arguments: transaction,
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
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
                    await transactionRepo.delete(transactionId);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.amount, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        formatter.format(transaction.amountCents / 100),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _DetailRow(l10n.date, DateFormat('MMM d, yyyy HH:mm').format(transaction.dateTime)),
                      _DetailRow(l10n.category, 'Category ${transaction.categoryId}'),
                      _DetailRow(l10n.account, 'Account ${transaction.accountId}'),
                      if (transaction.note != null)
                        _DetailRow(l10n.note, transaction.note!),
                    ],
                  ),
                ),
              ),
              if (transaction.receiptPath != null) ...[
                SizedBox(height: 16),
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
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

