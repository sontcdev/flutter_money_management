import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/models/uncategorized_category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction_attachment.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_form_fields.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/confirm_delete_dialog.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
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

        final category = categories
                .where((c) => c.id == transaction.categoryId)
                .firstOrNull ??
            uncategorizedCategory(
              transaction.categoryId ?? '',
              l10n.uncategorized,
            );

        final isTransfer = transaction.type == TransactionType.transfer;

        // Transfers are neither income nor expense: neutral colour, no sign.
        final Color amountColor;
        final String amountPrefix;
        final String typeLabel;
        switch (transaction.type) {
          case TransactionType.expense:
            amountColor = context.semanticColors.expense;
            amountPrefix = '-';
            typeLabel = l10n.expense;
            break;
          case TransactionType.income:
            amountColor = context.semanticColors.income;
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
                _TransactionAmountHeader(
                  isTransfer: isTransfer,
                  category: category,
                  amountCents: transaction.amountCents,
                  amountPrefix: amountPrefix,
                  amountColor: amountColor,
                  subtitle: isTransfer
                      ? '${fromWallet?.name ?? l10n.unknown} → '
                          '${toWallet?.name ?? l10n.unknown}'
                      : category.name,
                ),

                // Details Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Info Card
                      _TransactionInfoCard(
                        transaction: transaction,
                        isTransfer: isTransfer,
                        typeLabel: typeLabel,
                        amountColor: amountColor,
                        fromWallet: fromWallet,
                        toWallet: toWallet,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Delete / Edit action buttons
                      canManageTransactionAsync.maybeWhen(
                        data: (canManageTransaction) {
                          if (!canManageTransaction) {
                            return const SizedBox.shrink();
                          }

                          return _TransactionActions(
                            onDelete: () => _handleDelete(
                                context, ref, l10n, transactionRepo),
                            onEdit: () => _handleEdit(context, ref),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),

                      // Receipt Section
                      _ReceiptSection(
                        attachmentAsync: receiptAttachmentAsync,
                        imageUrlAsync: receiptImageUrlAsync,
                        onRetryAttachment: () => ref.invalidate(
                          transactionReceiptAttachmentProvider(transactionId),
                        ),
                        onRetryImage: () => ref.invalidate(
                          transactionReceiptImageUrlProvider(transactionId),
                        ),
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

  Future<void> _handleEdit(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-transaction',
      arguments: transactionId,
    );
    if (result == true && context.mounted) {
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletBalancesProvider);
      ref.invalidate(transactionReceiptAttachmentProvider(transactionId));
      ref.invalidate(transactionReceiptImageUrlProvider(transactionId));
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    TransactionRepository transactionRepo,
  ) async {
    final confirm = await ConfirmDeleteDialog.show(
      context,
      consequence: l10n.deleteCannotBeUndone,
    );

    if (confirm) {
      final receiptService = ref.read(transactionReceiptServiceProvider);
      try {
        await receiptService.removeReceipt(transactionId);
      } catch (_) {
        // Allow owner/admin to continue deleting the transaction
        // even if receipt cleanup fails due to legacy storage rules.
      }
      try {
        await transactionRepo.deleteTransaction(transactionId);
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            mapSupabaseException(e).toString(),
            type: AppSnackBarType.error,
          );
        }
        return;
      }
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              softWrap: true,
              textAlign: TextAlign.end,
            ),
          ),
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
          child: ReceiptNetworkImage(imageUrl: imageUrl),
        ),
      ),
    );
  }
}

class _TransactionActions extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TransactionActions({required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: AppButton.outlined(
            text: l10n.delete,
            icon: Icons.delete_outline,
            onPressed: onDelete,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            text: l10n.edit,
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
        ),
      ],
    );
  }
}

class _TransactionAmountHeader extends StatelessWidget {
  final bool isTransfer;
  final Category category;
  final int amountCents;
  final String amountPrefix;
  final Color amountColor;
  final String subtitle;

  const _TransactionAmountHeader({
    required this.isTransfer,
    required this.category,
    required this.amountCents,
    required this.amountPrefix,
    required this.amountColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedAmount = CurrencyFormatter.formatVNDFromCents(
      amountCents,
      locale: l10n.localeName,
    );
    return Padding(
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
          else
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
            '$amountPrefix$formattedAmount',
            style:
                Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Category name, or "from -> to" for transfers
          Text(
            subtitle,
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
    );
  }
}

class _TransactionInfoCard extends StatelessWidget {
  final Transaction transaction;
  final bool isTransfer;
  final String typeLabel;
  final Color amountColor;
  final Wallet? fromWallet;
  final Wallet? toWallet;

  const _TransactionInfoCard({
    required this.transaction,
    required this.isTransfer,
    required this.typeLabel,
    required this.amountColor,
    required this.fromWallet,
    required this.toWallet,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fromWallet = this.fromWallet;
    final toWallet = this.toWallet;
    return AppCard(
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
              label:
                  isTransfer ? l10n.fromWallet : l10n.wallets,
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
              height: 1,
              color: Theme.of(context).dividerColor),
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
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  final AsyncValue<TransactionAttachment?> attachmentAsync;
  final AsyncValue<String?> imageUrlAsync;
  final VoidCallback onRetryAttachment;
  final VoidCallback onRetryImage;

  const _ReceiptSection({
    required this.attachmentAsync,
    required this.imageUrlAsync,
    required this.onRetryAttachment,
    required this.onRetryImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return attachmentAsync.when(
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
            imageUrlAsync.when(
              data: (imageUrl) {
                if (imageUrl == null) {
                  return const SizedBox.shrink();
                }

                return AppCard(
                  clipBehavior: Clip.antiAlias,
                  padding: EdgeInsets.zero,
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
                  child: ReceiptNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => InlineLoadErrorState(
                onRetry: onRetryImage,
              ),
            ),
          ],
        );
      },
      loading: () => const SectionSkeleton(height: 120),
      error: (error, _) => InlineLoadErrorState(
        onRetry: onRetryAttachment,
      ),
    );
  }
}
