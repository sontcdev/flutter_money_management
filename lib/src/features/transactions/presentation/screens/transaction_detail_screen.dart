import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final canManageTransactionAsync = ref.watch(
      transactionCanManageProvider(transactionId),
    );
    final receiptAttachmentAsync = ref.watch(
      transactionReceiptAttachmentProvider(transactionId),
    );
    final receiptImageUrlAsync = ref.watch(
      transactionReceiptImageUrlProvider(transactionId),
    );

    return FutureBuilder(
      future: Future.wait([
        transactionRepo.getTransactionById(transactionId),
        categoryRepo.getAllCategories(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.transactions),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = snapshot.data![0] as Transaction;
        final categories = snapshot.data![1] as List<Category>;

        Category? category;
        try {
          category = categories.firstWhere(
            (c) => c.id == transaction.categoryId,
          );
        } catch (_) {
          // Category not found
        }

        final isExpense = transaction.type == TransactionType.expense;
        final amountColor = isExpense ? AppColors.expense : AppColors.income;
        final amountPrefix = isExpense ? '-' : '+';

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transactions),
            actions: canManageTransactionAsync.maybeWhen(
              data: (canManageTransaction) {
                if (!canManageTransaction) {
                  return const <Widget>[];
                }

                return <Widget>[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/edit-transaction',
                        arguments: transactionId,
                      );
                      if (result == true && context.mounted) {
                        ref.invalidate(transactionsProvider);
                        ref.invalidate(transactionReceiptAttachmentProvider(
                            transactionId));
                        ref.invalidate(
                            transactionReceiptImageUrlProvider(transactionId));
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.confirmDelete),
                            content: Text(l10n.confirmDeleteTransaction),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final receiptService =
                              ref.read(transactionReceiptServiceProvider);
                          try {
                            await receiptService.removeReceipt(transactionId);
                          } catch (_) {
                            // Allow owner/admin to continue deleting the transaction
                            // even if receipt cleanup fails due to legacy storage rules.
                          }
                          await transactionRepo
                              .deleteTransaction(transactionId);
                          ref.invalidate(budgetsProvider);
                          ref.invalidate(budgetsWithConsumedProvider);
                          ref.invalidate(transactionsProvider);
                          ref.invalidate(transactionReceiptAttachmentProvider(
                              transactionId));
                          ref.invalidate(transactionReceiptImageUrlProvider(
                              transactionId));
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ];
              },
              orElse: () => const <Widget>[],
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Amount Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sectionGap),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        amountColor.withValues(alpha: 0.1),
                        amountColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Category Icon
                      if (category != null)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: getCategoryColor(category.colorValue)
                                .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CategoryIconWidget(
                              iconName: category.iconName,
                              size: 40,
                              color: getCategoryColor(category.colorValue),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),

                      // Amount
                      Text(
                        '$amountPrefix${CurrencyFormatter.formatVNDFromCents(transaction.amountCents, locale: l10n.localeName)}',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Category Name
                      Text(
                        category?.name ?? l10n.unknown,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),

                // Details Section
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.swap_vert,
                                label: l10n.type,
                                value: isExpense ? l10n.expense : l10n.income,
                                valueColor: amountColor,
                              ),
                              const Divider(height: AppSpacing.lg),
                              _DetailRow(
                                icon: Icons.calendar_today,
                                label: l10n.date,
                                value: formatLocalizedFullDate(
                                    context, transaction.dateTime),
                              ),
                              if (transaction.note != null &&
                                  transaction.note!.isNotEmpty) ...[
                                const Divider(height: AppSpacing.lg),
                                _DetailRow(
                                  icon: Icons.note,
                                  label: l10n.note,
                                  value: transaction.note!,
                                  isMultiline: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Receipt Section
                      receiptAttachmentAsync.when(
                        data: (attachment) {
                          if (attachment == null) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                l10n.receipt,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              receiptImageUrlAsync.when(
                                data: (imageUrl) {
                                  if (imageUrl == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                _FullScreenImage(
                                              imageUrl: imageUrl,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(
                                          height: 120,
                                          child: Center(
                                              child: Icon(
                                                  Icons.broken_image_outlined)),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (error, _) =>
                                    Text(l10n.errorWithMessage('$error')),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, _) =>
                            Text(l10n.errorWithMessage('$error')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMultiline;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
