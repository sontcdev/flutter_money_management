// path: lib/src/ui/screens/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../widgets/receipt_viewer.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(transactionRepositoryProvider);
    final format = NumberFormat.currency(symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-transaction',
                arguments: transactionId,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: repo.getTransactionById(transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Transaction not found'));
          }

          final transaction = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          format.format(transaction.amountCents / 100),
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transaction.type == TransactionType.expense
                              ? l10n.expense
                              : l10n.income,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: l10n.date,
                  value: DateFormat('yyyy-MM-dd HH:mm').format(transaction.dateTime),
                ),
                _DetailRow(
                  label: l10n.category,
                  value: transaction.categoryId,
                ),
                _DetailRow(
                  label: l10n.account,
                  value: transaction.accountId,
                ),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  _DetailRow(
                    label: l10n.note,
                    value: transaction.note!,
                  ),
                if (transaction.receiptPath != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.receipt,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ReceiptViewer(receiptPath: transaction.receiptPath),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Share functionality
                        },
                        icon: const Icon(Icons.share),
                        label: Text(l10n.share),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Export functionality
                        },
                        icon: const Icon(Icons.download),
                        label: Text(l10n.export),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

