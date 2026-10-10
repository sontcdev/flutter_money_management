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
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final form = _useEditTransactionForm(
      context,
      ref,
      l10n,
      transactionId,
    );
    final selectedType = form.selectedType;
    final isLoading = form.isLoading;

    return TransactionDiscardGuard(
      isDirty: form.isDirty && !isLoading.value,
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
                onChanged: form.changeType,
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // Amount Input - Priority 1 (large centered display, matches
              // design)
              _EditAmountField(
                formKey: form.formKey,
                controller: form.amountController,
                type: selectedType.value,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Wallet Selector - required for every transaction.
              _WalletSection(
                type: selectedType.value,
                wallet: form.selectedWallet.value,
                toWallet: form.selectedToWallet.value,
                onWalletPicked: (picked) =>
                    form.selectedWallet.value = picked,
                onToWalletPicked: (picked) =>
                    form.selectedToWallet.value = picked,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Category Selector - Priority 2. Transfers carry no category.
              if (selectedType.value != model.TransactionType.transfer)
                _CategorySection(
                  categoriesAsync: categoriesAsync,
                  type: selectedType.value,
                  selectedCategoryId: form.selectedCategoryId.value,
                  onSelected: (id) => form.selectedCategoryId.value = id,
                  onAdd: form.addCategory,
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
              if (selectedType.value != model.TransactionType.transfer)
                const SizedBox(height: AppSpacing.lg),

              // Date Picker - Priority 3
              _DateSection(
                selectedDate: form.selectedDate.value,
                onChanged: (date) => form.selectedDate.value = date,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Note Input - Priority 4
              AppInput(
                label: l10n.note,
                hint: l10n.note,
                controller: form.noteController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Receipt Attachment - Priority 5
              _ReceiptSection(
                localReceiptPath: form.localReceiptPath.value,
                existingReceiptAttachment:
                    form.existingReceiptAttachment.value,
                shouldRemoveReceipt: form.shouldRemoveReceipt.value,
                receiptImageUrlAsync: form.receiptImageUrlAsync,
                canManageTransactionAsync: form.canManageTransactionAsync,
                onPickReceipt: form.pickReceipt,
                onRemoveReceipt: form.removeReceipt,
                onRetryImage: () => ref.invalidate(
                  transactionReceiptImageUrlProvider(transactionId),
                ),
                onRetryCanManage: () => ref.invalidate(
                  transactionCanManageProvider(transactionId),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: TransactionSaveBar(
          text: l10n.save,
          onPressed: form.isAmountValid ? form.handleSubmit : null,
          isLoading: isLoading.value,
        ),
      ),
    );
  }
}

_EditTransactionForm _useEditTransactionForm(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  String transactionId,
) {
  final repository = ref.watch(transactionRepositoryProvider);

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

  final form = _EditTransactionForm(
    context: context,
    ref: ref,
    l10n: l10n,
    transactionId: transactionId,
    repository: repository,
    amountController: amountController,
    noteController: noteController,
    selectedDate: selectedDate,
    selectedType: selectedType,
    selectedCategoryId: selectedCategoryId,
    selectedWallet: selectedWallet,
    selectedToWallet: selectedToWallet,
    localReceiptPath: localReceiptPath,
    existingReceiptAttachment: existingReceiptAttachment,
    shouldRemoveReceipt: shouldRemoveReceipt,
    isLoading: isLoading,
    allowOverdraft: allowOverdraft,
    formKey: formKey,
    initialSignature: initialSignature,
    canManageTransactionAsync: canManageTransactionAsync,
    receiptImageUrlAsync: receiptImageUrlAsync,
  );

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
      initialSignature.value = form.formSignature();
    });
    return null;
  }, [transactionId, attachmentRepository, repository]);
  return form;
}

class _EditTransactionForm {
  final BuildContext context;
  final WidgetRef ref;
  final AppLocalizations l10n;
  final String transactionId;
  final TransactionRepository repository;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final ValueNotifier<DateTime> selectedDate;
  final ValueNotifier<model.TransactionType> selectedType;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueNotifier<Wallet?> selectedWallet;
  final ValueNotifier<Wallet?> selectedToWallet;
  final ValueNotifier<String?> localReceiptPath;
  final ValueNotifier<TransactionAttachment?> existingReceiptAttachment;
  final ValueNotifier<bool> shouldRemoveReceipt;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<bool> allowOverdraft;
  final GlobalKey<FormState> formKey;
  final ObjectRef<String?> initialSignature;
  final AsyncValue<bool> canManageTransactionAsync;
  final AsyncValue<String?> receiptImageUrlAsync;

  _EditTransactionForm({
    required this.context,
    required this.ref,
    required this.l10n,
    required this.transactionId,
    required this.repository,
    required this.amountController,
    required this.noteController,
    required this.selectedDate,
    required this.selectedType,
    required this.selectedCategoryId,
    required this.selectedWallet,
    required this.selectedToWallet,
    required this.localReceiptPath,
    required this.existingReceiptAttachment,
    required this.shouldRemoveReceipt,
    required this.isLoading,
    required this.allowOverdraft,
    required this.formKey,
    required this.initialSignature,
    required this.canManageTransactionAsync,
    required this.receiptImageUrlAsync,
  });

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

  bool get isAmountValid {
      final amountValue = CurrencyFormatter.parseVND(amountController.text);
    return amountValue != null && amountValue > 0;
  }

  bool get isDirty =>
      initialSignature.value != null &&
      formSignature() != initialSignature.value;

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

  void changeType(model.TransactionType type) {
    selectedType.value = type;
    selectedCategoryId.value = null;
    if (type != model.TransactionType.transfer) {
      selectedToWallet.value = null;
    }
  }

  Future<void> addCategory() async {
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
  }

  void removeReceipt() {
    localReceiptPath.value = null;
    shouldRemoveReceipt.value =
        existingReceiptAttachment.value != null;
    AppLogger.info(
      'Receipt removed from transaction edit',
      name: 'MM.UI',
    );
  }
}

class _EditAmountField extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final model.TransactionType type;

  const _EditAmountField({
    required this.formKey,
    required this.controller,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Transfers are neither income nor expense, so they use the theme accent.
    final Color amountColor;
    switch (type) {
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

    return Column(
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
              controller: controller,
              validator: (value) => validateTransactionAmount(value, l10n),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                VNDInputFormatter(),
              ],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
                suffixText: CurrencyFormatter.getCurrencySymbol('VND'),
                suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletSection extends StatelessWidget {
  final model.TransactionType type;
  final Wallet? wallet;
  final Wallet? toWallet;
  final ValueChanged<Wallet> onWalletPicked;
  final ValueChanged<Wallet> onToWalletPicked;

  const _WalletSection({
    required this.type,
    required this.wallet,
    required this.toWallet,
    required this.onWalletPicked,
    required this.onToWalletPicked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WalletField(
          label: type == model.TransactionType.transfer
              ? l10n.fromWallet
              : l10n.selectWallet,
          wallet: wallet,
          onTap: () async {
            final picked = await showWalletPicker(
              context,
              title: type == model.TransactionType.transfer
                  ? l10n.fromWallet
                  : l10n.selectWallet,
              selectedWalletId: wallet?.id,
              excludeWalletId: toWallet?.id,
            );
            if (picked != null) {
              onWalletPicked(picked);
            }
          },
        ),
        if (type == model.TransactionType.transfer) ...[
          const SizedBox(height: AppSpacing.lg),
          WalletField(
            label: l10n.toWallet,
            wallet: toWallet,
            onTap: () async {
              final picked = await showWalletPicker(
                context,
                title: l10n.toWallet,
                selectedWalletId: toWallet?.id,
                excludeWalletId: wallet?.id,
              );
              if (picked != null) {
                onToWalletPicked(picked);
              }
            },
          ),
        ],
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AsyncValue<List<Category>> categoriesAsync;
  final model.TransactionType type;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;
  final VoidCallback onRetry;

  const _CategorySection({
    required this.categoriesAsync,
    required this.type,
    required this.selectedCategoryId,
    required this.onSelected,
    required this.onAdd,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return categoriesAsync.when(
      data: (categories) {
        final filteredCategories = categories.where((c) {
          if (type == model.TransactionType.expense) {
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
                  onPressed: onAdd,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (filteredCategories.isEmpty)
              Text(l10n.noCategories)
            else
              TransactionCategoryChips(
                categories: filteredCategories,
                selectedCategoryId: selectedCategoryId,
                onSelected: onSelected,
              ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => InlineLoadErrorState(
        onRetry: onRetry,
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _DateSection({
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
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
                onChanged(selectedDate.subtract(const Duration(days: 1)));
              },
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        selectedDate.isAfter(now) ? now : selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: now,
                  );
                  if (picked != null) {
                    onChanged(keepTimeOfDay(picked, selectedDate));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        formatLocalizedDate(context, selectedDate),
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
                onChanged(selectedDate.add(const Duration(days: 1)));
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  final String? localReceiptPath;
  final TransactionAttachment? existingReceiptAttachment;
  final bool shouldRemoveReceipt;
  final AsyncValue<String?> receiptImageUrlAsync;
  final AsyncValue<bool> canManageTransactionAsync;
  final VoidCallback onPickReceipt;
  final VoidCallback onRemoveReceipt;
  final VoidCallback onRetryImage;
  final VoidCallback onRetryCanManage;

  const _ReceiptSection({
    required this.localReceiptPath,
    required this.existingReceiptAttachment,
    required this.shouldRemoveReceipt,
    required this.receiptImageUrlAsync,
    required this.canManageTransactionAsync,
    required this.onPickReceipt,
    required this.onRemoveReceipt,
    required this.onRetryImage,
    required this.onRetryCanManage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.receipt,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (localReceiptPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            child: Image.file(
              File(localReceiptPath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else if (!shouldRemoveReceipt && existingReceiptAttachment != null)
          receiptImageUrlAsync.when(
            data: (imageUrl) {
              if (imageUrl == null) {
                return Text(l10n.attachReceipt);
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                child: ReceiptNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => InlineLoadErrorState(
              onRetry: onRetryImage,
            ),
          )
        else
          Text(
            shouldRemoveReceipt
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
                  onPressed: onPickReceipt,
                ),
                if (localReceiptPath != null ||
                    existingReceiptAttachment != null)
                  IconButton(
                    tooltip: l10n.removeReceipt,
                    icon: const Icon(Icons.clear),
                    onPressed: onRemoveReceipt,
                  ),
              ],
            );
          },
          loading: () => const SectionSkeleton(height: 48, lineCount: 1),
          error: (_, __) => InlineLoadErrorState(
            onRetry: onRetryCanManage,
          ),
        ),
      ],
    );
  }
}
