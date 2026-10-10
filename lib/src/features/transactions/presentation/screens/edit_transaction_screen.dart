import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/models/transaction_attachment.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_form_fields.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_field.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_picker.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/ui/widgets/transaction_type_toggle.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/date_time_utils.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

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
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final initialSignature = useRef<String?>(null);
    useListenable(amountController);
    useListenable(noteController);
    final canManageTransactionAsync =
        ref.watch(transactionCanManageProvider(transactionId));
    final receiptImageUrlAsync =
        ref.watch(transactionReceiptImageUrlProvider(transactionId));
    final attachmentRepository =
        ref.watch(transactionAttachmentRepositoryProvider);

    String formSignature() => [
          amountController.text,
          noteController.text,
          selectedDate.value.toIso8601String(),
          selectedType.value.name,
          selectedCategoryId.value,
          selectedWallet.value?.id,
          selectedToWallet.value?.id,
          localReceiptPath.value,
          shouldRemoveReceipt.value,
        ].join('|');

    final amountValue = CurrencyFormatter.parseVND(amountController.text);
    final isAmountValid = amountValue != null && amountValue > 0;
    final isDirty = initialSignature.value != null &&
        formSignature() != initialSignature.value;

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
        selectedWallet.value = wallets
            .where((w) => w.id == transaction.walletId)
            .firstOrNull;
        selectedToWallet.value = wallets
            .where((w) => w.id == transaction.toWalletId)
            .firstOrNull;
        initialSignature.value = formSignature();
      });
      return null;
    }, [transactionId, attachmentRepository, repository]);

    Future<void> handleSubmit() async {
      if (isLoading.value) return;
      if (!(formKey.currentState?.validate() ?? false)) return;

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
        final amount = CurrencyFormatter.parseVND(amountController.text)!;
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
      final source = await showReceiptSourcePicker(context);
      if (source == null) return;
      AppLogger.info('Receipt capture started', name: 'MM.UI');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
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

    return TransactionDiscardGuard(
      isDirty: isDirty && !isLoading.value,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editTransaction),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
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

              // Amount Input - Priority 1 (large centered display, matches
              // design)
              Column(
                children: [
                  Text(
                    l10n.amount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: IntrinsicWidth(
                      child: TextFormField(
                        controller: amountController,
                        validator: (value) =>
                            validateTransactionAmount(value, l10n),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          VNDInputFormatter(),
                        ],
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                            ),
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                          suffixText:
                              CurrencyFormatter.getCurrencySymbol('VND'),
                          suffixStyle:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: amountColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                    title: selectedType.value == model.TransactionType.transfer
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
                    if (selectedType.value == model.TransactionType.expense) {
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
                        TransactionCategoryChips(
                          categories: filteredCategories,
                          selectedCategoryId: selectedCategoryId.value,
                          onSelected: (id) => selectedCategoryId.value = id,
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
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusCard),
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

              // Note Input - Priority 4
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusCard),
                          child: ReceiptNetworkImage(
                            imageUrl: imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => InlineLoadErrorState(
                        onRetry: () => ref.invalidate(
                          transactionReceiptImageUrlProvider(transactionId),
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
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }

                      return Row(
                        children: [
                          IconButton(
                            tooltip: l10n.attachReceipt,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            onPressed: pickReceipt,
                          ),
                          if (localReceiptPath.value != null ||
                              existingReceiptAttachment.value != null)
                            IconButton(
                              tooltip: l10n.removeReceipt,
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                localReceiptPath.value = null;
                                shouldRemoveReceipt.value =
                                    existingReceiptAttachment.value != null;
                                AppLogger.info(
                                  'Receipt removed from transaction edit',
                                  name: 'MM.UI',
                                );
                              },
                            ),
                        ],
                      );
                    },
                    loading: () =>
                        const SectionSkeleton(height: 48, lineCount: 1),
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
        bottomNavigationBar: TransactionSaveBar(
          text: l10n.save,
          onPressed: isAmountValid ? handleSubmit : null,
          isLoading: isLoading.value,
        ),
      ),
    );
  }
}
