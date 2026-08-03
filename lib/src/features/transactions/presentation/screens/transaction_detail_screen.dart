import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
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
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];

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

        final isTransfer = transaction.type == TransactionType.transfer;

        // Transfers are neither income nor expense: neutral colour, no sign.
        final Color amountColor;
        final String amountPrefix;
        final String typeLabel;
        switch (transaction.type) {
          case TransactionType.expense:
            amountColor = AppColors.expense;
            amountPrefix = '-';
            typeLabel = l10n.expense;
            break;
          case TransactionType.income:
            amountColor = AppColors.income;
            amountPrefix = '+';
            typeLabel = l10n.income;
            break;
          case TransactionType.transfer:
            amountColor = Theme.of(context).colorScheme.onSurface;
            amountPrefix = '';
            typeLabel = l10n.transfer;
            break;
        }

        final fromWallet =
            wallets.where((w) => w.id == transaction.walletId).firstOrNull;
        final toWallet =
            wallets.where((w) => w.id == transaction.toWalletId).firstOrNull;

        Future<void> handleEdit() async {
          final result = await Navigator.pushNamed(
            context,
            '/edit-transaction',
            arguments: transactionId,
          );
          if (result == true && context.mounted) {
            ref.invalidate(transactionsProvider);
            ref.invalidate(transactionReceiptAttachmentProvider(transactionId));
            ref.invalidate(transactionReceiptImageUrlProvider(transactionId));
            Navigator.pop(context, true);
          }
        }

        Future<void> handleDelete() async {
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
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final receiptService = ref.read(transactionReceiptServiceProvider);
            try {
              await receiptService.removeReceipt(transactionId);
            } catch (_) {
              // Allow owner/admin to continue deleting the transaction
              // even if receipt cleanup fails due to legacy storage rules.
            }
            await transactionRepo.deleteTransaction(transactionId);
            ref.invalidate(budgetsProvider);
            ref.invalidate(budgetsWithConsumedProvider);
            ref.invalidate(transactionsProvider);
            ref.invalidate(transactionReceiptAttachmentProvider(transactionId));
            ref.invalidate(transactionReceiptImageUrlProvider(transactionId));
            if (context.mounted) {
              Navigator.pop(context, true);
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transactions),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Amount
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      // Category Icon (transfers use a neutral swap glyph)
                      if (isTransfer)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: Icon(
                            Icons.swap_horiz,
                            size: 30,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      else if (category != null)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: getCategoryColor(category.colorValue)
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: Center(
                            child: CategoryIconWidget(
                              iconName: category.iconName,
                              size: 30,
                              color: getCategoryColor(category.colorValue),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),

                      // Amount
                      Text(
                        '$amountPrefix${CurrencyFormatter.formatVNDFromCents(transaction.amountCents, locale: l10n.localeName)}',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: amountColor,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Category name, or "from -> to" for transfers
                      Text(
                        isTransfer
                            ? '${fromWallet?.name ?? l10n.unknown} → '
                                '${toWallet?.name ?? l10n.unknown}'
                            : category?.name ?? l10n.unknown,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),

                // Details Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Info Card
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                            children: [
                              _DetailRow(
                                label: l10n.type,
                                value: typeLabel,
                                valueColor: amountColor,
                              ),
                              if (fromWallet != null) ...[
                                Divider(
                                    height: 1,
                                    color: Theme.of(context).dividerColor),
                                _DetailRow(
                                  label: isTransfer
                                      ? l10n.fromWallet
                                      : l10n.wallets,
                                  value: fromWallet.name,
                                ),
                              ],
                              if (toWallet != null) ...[
                                Divider(
                                    height: 1,
                                    color: Theme.of(context).dividerColor),
                                _DetailRow(
                                  label: l10n.toWallet,
                                  value: toWallet.name,
                                ),
                              ],
                              Divider(
                                  height: 1, color: Theme.of(context).dividerColor),
                              _DetailRow(
                                label: l10n.date,
                                value: formatLocalizedFullDate(
                                    context, transaction.dateTime),
                              ),
                              if (transaction.note != null &&
                                  transaction.note!.isNotEmpty) ...[
                                Divider(
                                    height: 1,
                                    color: Theme.of(context).dividerColor),
                                _DetailRow(
                                  label: l10n.note,
                                  value: transaction.note!,
                                  isMultiline: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),

                      // Delete / Edit action buttons
                      canManageTransactionAsync.maybeWhen(
                        data: (canManageTransaction) {
                          if (!canManageTransaction) {
                            return const SizedBox.shrink();
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: AppButton.outlined(
                                  text: l10n.delete,
                                  icon: Icons.delete_outline,
                                  onPressed: handleDelete,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppButton(
                                  text: l10n.edit,
                                  icon: Icons.edit_outlined,
                                  onPressed: handleEdit,
                                ),
                              ),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
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
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMultiline;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: valueColor,
    );

    if (isMultiline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
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
