import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/models/transaction_attachment.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_field.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_picker.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/ui/widgets/transaction_type_toggle.dart';
import 'package:flutter_money_management/src/ui/widgets/unsaved_changes_guard.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/date_time_utils.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

/// Normalised values of the loaded transaction, used to detect real edits.
Color _categoryChipForeground(BuildContext context, Color categoryColor) {
  final theme = Theme.of(context);
  final tint = categoryColor.withValues(alpha: 0.2);
  return AppSurfaceTokens.ensureContrastOnAll(
    categoryColor,
    [
      Color.alphaBlend(tint, theme.colorScheme.surface),
      Color.alphaBlend(tint, theme.scaffoldBackgroundColor),
    ],
    toward: theme.colorScheme.onSurface,
  );
}

class _InitialValues {
  const _InitialValues({
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.toWalletId,
    required this.dateTime,
    required this.note,
    required this.hasReceipt,
  });

  final num? amount;
  final model.TransactionType type;
  final String? categoryId;
  final String? walletId;
  final String? toWalletId;
  final DateTime dateTime;
  final String note;
  final bool hasReceipt;
}

class EditTransactionScreen extends HookConsumerWidget {
  final String transactionId;

  const EditTransactionScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.watch(transactionRepositoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final amountController = useTextEditingController();
    final noteController = useTextEditingController();
    final selectedDate = useState(DateTime.now());
    final selectedType = useState(model.TransactionType.expense);
    final selectedCategoryId = useState<String?>(null);
    final selectedWallet = useState<Wallet?>(null);
    final selectedToWallet = useState<Wallet?>(null);
    final localReceiptPath = useState<String?>(null);
    final existingReceiptAttachment = useState<TransactionAttachment?>(null);
    final shouldRemoveReceipt = useState(false);
    final isLoading = useState(false);
    final allowOverdraft = useState(false);
    final initial = useState<_InitialValues?>(null);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final guardController = useMemoized(() => UnsavedChangesController());
    useListenable(amountController);
    useListenable(noteController);
    final canManageTransactionAsync =
        ref.watch(transactionCanManageProvider(transactionId));
    final receiptImageUrlAsync =
        ref.watch(transactionReceiptImageUrlProvider(transactionId));
    final attachmentRepository =
        ref.watch(transactionAttachmentRepositoryProvider);

    // Load existing transaction for editing
    useEffect(() {
      Future.microtask(() async {
        final results = await Future.wait<dynamic>([
          repository.getTransactionById(transactionId),
          attachmentRepository
              .getLatestReceiptAttachmentByTransactionId(transactionId),
        ]);
        final transaction = results[0] as model.Transaction;
        final attachment = results[1] as TransactionAttachment?;
        final amount = (transaction.amountCents / 100).round();
        amountController.text =
            CurrencyFormatter.formatInputVND(amount.toString());
        noteController.text = transaction.note ?? '';
        selectedDate.value = transaction.dateTime;
        selectedType.value = transaction.type;
        selectedCategoryId.value = transaction.categoryId;
        existingReceiptAttachment.value = attachment;

        // Resolve the wallet ids into full wallets for the picker fields.
        final wallets = await ref.read(walletsProvider.future);
        selectedWallet.value =
            wallets.where((w) => w.id == transaction.walletId).firstOrNull;
        selectedToWallet.value =
            wallets.where((w) => w.id == transaction.toWalletId).firstOrNull;
        initial.value = _InitialValues(
          amount: CurrencyFormatter.parseVND(amountController.text),
          type: transaction.type,
          categoryId: transaction.categoryId,
          walletId: selectedWallet.value?.id,
          toWalletId: selectedToWallet.value?.id,
          dateTime: transaction.dateTime,
          note: (transaction.note ?? '').trim(),
          hasReceipt: attachment != null,
        );
      });
      return null;
    }, [transactionId, attachmentRepository, repository]);

    Future<void> handleSubmit() async {
      if (isLoading.value) return;
      if (!(formKey.currentState?.validate() ?? true)) return;

      final isTransfer = selectedType.value == model.TransactionType.transfer;

      if (!isTransfer && selectedCategoryId.value == null) {
        showAppSnackBar(
          context,
          l10n.selectCategoryError,
          type: AppSnackBarType.error,
        );
        return;
      }

      if (selectedWallet.value == null) {
        showAppSnackBar(
          context,
          l10n.walletRequired,
          type: AppSnackBarType.error,
        );
        return;
      }

      if (isTransfer) {
        if (selectedToWallet.value == null) {
          showAppSnackBar(
            context,
            l10n.toWalletRequired,
            type: AppSnackBarType.error,
          );
          return;
        }
        if (selectedToWallet.value!.id == selectedWallet.value!.id) {
          showAppSnackBar(
            context,
            l10n.sameWalletError,
            type: AppSnackBarType.error,
          );
          return;
        }
      }

      isLoading.value = true;
      final overdraftAllowed = allowOverdraft.value;
      allowOverdraft.value = false;

      try {
        final receiptService = ref.read(transactionReceiptServiceProvider);
        final amount = CurrencyFormatter.parseVND(amountController.text);
        if (amount == null) {
          throw const FormatException('Invalid amount format');
        }
        final amountCents = CurrencyFormatter.toCents(amount);

        final transaction = model.Transaction(
          id: transactionId,
          amountCents: amountCents,
          currency: 'VND',
          dateTime: selectedDate.value,
          categoryId: isTransfer ? null : selectedCategoryId.value,
          type: selectedType.value,
          walletId: selectedWallet.value!.id,
          toWalletId: isTransfer ? selectedToWallet.value!.id : null,
          note: noteController.text.isEmpty ? null : noteController.text,
          receiptPath: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.updateTransaction(
          transaction,
          allowOverdraft: overdraftAllowed,
        );

        String? receiptWarning;
        final canManageTransaction = await ref.read(
          transactionCanManageProvider(transactionId).future,
        );
        if (canManageTransaction) {
          try {
            if (localReceiptPath.value != null) {
              await receiptService.attachReceipt(
                transactionId: transactionId,
                localFilePath: localReceiptPath.value!,
              );
            } else if (shouldRemoveReceipt.value) {
              await receiptService.removeReceipt(transactionId);
            }
          } catch (e, stackTrace) {
            AppLogger.error(
              'Receipt update failed after transaction update',
              name: 'MM.UI',
              error: e,
              stackTrace: stackTrace,
            );
            receiptWarning = l10n.transactionSavedReceiptUpdateFailed;
          }
        }

        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(walletBalancesProvider);
        ref.invalidate(transactionReceiptAttachmentProvider(transactionId));
        ref.invalidate(transactionReceiptImageUrlProvider(transactionId));

        if (context.mounted) {
          showAppSnackBar(
            context,
            receiptWarning ?? l10n.success,
            type: receiptWarning == null
                ? AppSnackBarType.success
                : AppSnackBarType.info,
          );
          guardController.markSaved();
          Navigator.of(context).pop(true);
        }
      } on BudgetExceededException catch (e) {
        if (context.mounted) {
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.budgetExceeded),
              content: Text(e.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.proceed),
                ),
              ],
            ),
          );

          if (shouldProceed == true) {
            allowOverdraft.value = true;
            isLoading.value = false;
            await handleSubmit();
          }
        }
      } catch (e, stackTrace) {
        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'transaction',
            action: 'update_transaction',
            screen: 'edit_transaction_screen',
            extraContext: {
              'transaction_id': transactionId,
              'category_id': selectedCategoryId.value,
              'wallet_id': selectedWallet.value?.id,
              'has_local_receipt': localReceiptPath.value != null,
              'should_remove_receipt': shouldRemoveReceipt.value,
            },
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> pickReceipt() async {
      AppLogger.info('Receipt capture started', name: 'MM.UI');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        localReceiptPath.value = image.path;
        shouldRemoveReceipt.value = false;
        AppLogger.info('Receipt attached to transaction edit', name: 'MM.UI');
      } else {
        AppLogger.debug('Receipt capture cancelled', name: 'MM.UI');
      }
    }

    // Transfers are neither income nor expense, so they use the theme accent.
    final Color amountColor;
    switch (selectedType.value) {
      case model.TransactionType.expense:
        amountColor = context.semanticColors.expense;
        break;
      case model.TransactionType.income:
        amountColor = context.semanticColors.income;
        break;
      case model.TransactionType.transfer:
        amountColor = Theme.of(context).colorScheme.primary;
        break;
    }

    final start = initial.value;
    final isDirty = start != null &&
        (CurrencyFormatter.parseVND(amountController.text) != start.amount ||
            selectedType.value != start.type ||
            selectedCategoryId.value != start.categoryId ||
            selectedWallet.value?.id != start.walletId ||
            selectedToWallet.value?.id != start.toWalletId ||
            !selectedDate.value.isAtSameMomentAs(start.dateTime) ||
            noteController.text.trim() != start.note ||
            localReceiptPath.value != null ||
            shouldRemoveReceipt.value);
    final detailsExpanded = start != null &&
        (start.note.isNotEmpty ||
            start.hasReceipt ||
            localReceiptPath.value != null);

    return UnsavedChangesGuard(
      isDirty: isDirty,
      controller: guardController,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editTransaction),
          centerTitle: true,
        ),
        body: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Toggle - pill-shaped segmented control, matching the
                // mockup's "Chi tiêu / Thu nhập" switch.
                TransactionTypeToggle(
                  value: selectedType.value,
                  expenseLabel: l10n.expense,
                  incomeLabel: l10n.income,
                  transferLabel: l10n.transfer,
                  onChanged: (type) {
                    selectedType.value = type;
                    selectedCategoryId.value = null;
                    if (type != model.TransactionType.transfer) {
                      selectedToWallet.value = null;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Amount Input - Priority 1 (large centered display, matches design)
                // Amount Input - Priority 1
                AppInput(
                  label: l10n.amount,
                  hint: '0',
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    VNDInputFormatter(),
                  ],
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        CurrencyFormatter.parseVND(value) == null) {
                      return l10n.amountRequiredError;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => handleSubmit(),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        CurrencyFormatter.getCurrencySymbol('VND'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: amountColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Wallet Selector - required for every transaction.
                WalletField(
                  label: selectedType.value == model.TransactionType.transfer
                      ? l10n.fromWallet
                      : l10n.selectWallet,
                  wallet: selectedWallet.value,
                  onTap: () async {
                    final picked = await showWalletPicker(
                      context,
                      title:
                          selectedType.value == model.TransactionType.transfer
                              ? l10n.fromWallet
                              : l10n.selectWallet,
                      selectedWalletId: selectedWallet.value?.id,
                      excludeWalletId: selectedToWallet.value?.id,
                    );
                    if (picked != null) {
                      selectedWallet.value = picked;
                    }
                  },
                ),
                if (selectedType.value == model.TransactionType.transfer) ...[
                  const SizedBox(height: AppSpacing.lg),
                  WalletField(
                    label: l10n.toWallet,
                    wallet: selectedToWallet.value,
                    onTap: () async {
                      final picked = await showWalletPicker(
                        context,
                        title: l10n.toWallet,
                        selectedWalletId: selectedToWallet.value?.id,
                        excludeWalletId: selectedWallet.value?.id,
                      );
                      if (picked != null) {
                        selectedToWallet.value = picked;
                      }
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Category Selector - Priority 2. Transfers carry no category.
                if (selectedType.value != model.TransactionType.transfer)
                  categoriesAsync.when(
                    data: (categories) {
                      final filteredCategories = categories.where((c) {
                        if (selectedType.value ==
                            model.TransactionType.expense) {
                          return c.type == CategoryType.expense;
                        } else {
                          return c.type == CategoryType.income;
                        }
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.category,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(l10n.add),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/category-edit',
                                    arguments: {
                                      'initialType': selectedType.value ==
                                              model.TransactionType.expense
                                          ? CategoryType.expense
                                          : CategoryType.income,
                                      'workspaceId':
                                          ref.read(activeWorkspaceIdProvider),
                                    },
                                  );
                                  if (result == true) {
                                    ref.invalidate(categoriesProvider);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (filteredCategories.isEmpty)
                            Text(l10n.noCategories)
                          else
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: filteredCategories.map((category) {
                                final isSelected =
                                    selectedCategoryId.value == category.id;
                                final categoryColor =
                                    getCategoryColor(category.colorValue);
                                final chipForeground = _categoryChipForeground(
                                    context, categoryColor);
                                return GestureDetector(
                                  onTap: () {
                                    selectedCategoryId.value = category.id;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          categoryColor.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color: categoryColor,
                                        width: isSelected ? 3 : 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusXl),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CategoryIconWidget(
                                          iconName: category.iconName,
                                          size: 18,
                                          color: chipForeground,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          category.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: chipForeground,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => InlineLoadErrorState(
                      onRetry: () => ref.invalidate(categoriesProvider),
                    ),
                  ),
                if (selectedType.value != model.TransactionType.transfer)
                  const SizedBox(height: AppSpacing.lg),

                // Date Picker - Priority 3
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.date,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.previousDay,
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            selectedDate.value = selectedDate.value
                                .subtract(const Duration(days: 1));
                          },
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate.value.isAfter(now)
                                    ? now
                                    : selectedDate.value,
                                firstDate: DateTime(2000),
                                lastDate: now,
                              );
                              if (picked != null) {
                                selectedDate.value =
                                    keepTimeOfDay(picked, selectedDate.value);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusCard),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    formatLocalizedDate(
                                        context, selectedDate.value),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.nextDay,
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            selectedDate.value =
                                selectedDate.value.add(const Duration(days: 1));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Note and Receipt - Optional Details Section
                ExpansionTile(
                  key: ValueKey('details-$detailsExpanded'),
                  title: Text(
                    '${l10n.note} & ${l10n.receipt}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  subtitle: Text(
                    l10n.optional,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  initiallyExpanded: detailsExpanded,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            label: l10n.note,
                            hint: l10n.note,
                            controller: noteController,
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Receipt Attachment - Priority 5
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.receipt,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (localReceiptPath.value != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusCard),
                                  child: Image.file(
                                    File(localReceiptPath.value!),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (!shouldRemoveReceipt.value &&
                                  existingReceiptAttachment.value != null)
                                receiptImageUrlAsync.when(
                                  data: (imageUrl) {
                                    if (imageUrl == null) {
                                      return Text(l10n.attachReceipt);
                                    }
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusCard),
                                      child: Image.network(
                                        imageUrl,
                                        headers: ref
                                            .read(supabaseClientProvider)
                                            .authHeaders,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                  loading: () => const Center(
                                      child: CircularProgressIndicator()),
                                  error: (error, _) => InlineLoadErrorState(
                                    onRetry: () => ref.invalidate(
                                      transactionReceiptImageUrlProvider(
                                          transactionId),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  shouldRemoveReceipt.value
                                      ? l10n.receiptWillBeRemovedOnSave
                                      : l10n.attachReceipt,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              canManageTransactionAsync.when(
                                data: (canManageTransaction) {
                                  if (!canManageTransaction) {
                                    return Text(
                                      l10n.onlyCreatorCanChangeReceipt,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    );
                                  }

                                  return Row(
                                    children: [
                                      IconButton(
                                        tooltip: l10n.attachReceipt,
                                        icon: const Icon(Icons.camera_alt),
                                        onPressed: pickReceipt,
                                      ),
                                      if (localReceiptPath.value != null ||
                                          existingReceiptAttachment.value !=
                                              null)
                                        IconButton(
                                          tooltip: l10n.removeReceipt,
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            localReceiptPath.value = null;
                                            shouldRemoveReceipt.value =
                                                existingReceiptAttachment
                                                        .value !=
                                                    null;
                                            AppLogger.info(
                                              'Receipt removed from transaction edit',
                                              name: 'MM.UI',
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                },
                                loading: () => const SectionSkeleton(
                                    height: 48, lineCount: 1),
                                error: (_, __) => InlineLoadErrorState(
                                  onRetry: () => ref.invalidate(
                                    transactionCanManageProvider(transactionId),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: l10n.save,
                    onPressed: handleSubmit,
                    isLoading: isLoading.value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
