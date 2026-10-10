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
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/voice_input_sheet.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/quick_input_review_sheet.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_form_fields.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/transaction_type_toggle.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/date_time_utils.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_field.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_picker.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';

class AddTransactionScreen extends HookConsumerWidget {
  final model.TransactionType? initialType;

  const AddTransactionScreen({
    super.key,
    this.initialType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspacesAsync = ref.watch(workspaceListProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);

    final form = _useAddTransactionForm(
      context,
      ref,
      l10n,
      initialType,
      activeWorkspace,
    );
    final selectedType = form.selectedType;
    final isLoading = form.isLoading;

    return TransactionDiscardGuard(
      isDirty: form.isDirty && !isLoading.value,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addTransaction),
          actions: [
            IconButton(
              icon: const Icon(Icons.bolt_outlined),
              tooltip: l10n.quickInputTooltip,
              onPressed: isLoading.value ? null : form.handleVoiceInput,
            ),
          ],
        ),
        bottomNavigationBar: TransactionSaveBar(
          text: l10n.save,
          onPressed: form.isAmountValid ? form.handleSubmit : null,
          isLoading: isLoading.value,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: form.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Toggle - pill-shaped segmented control on a surface2
                // track, matching the mockup's "Chi tiêu / Thu nhập" switch.
                TransactionTypeToggle(
                  value: selectedType.value,
                  expenseLabel: l10n.expense,
                  incomeLabel: l10n.income,
                  transferLabel: l10n.transfer,
                  onChanged: form.changeType,
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                _WorkspaceSection(
                  workspacesAsync: workspacesAsync,
                  selectedWorkspaceId: form.selectedWorkspaceId.value,
                  onChanged: isLoading.value ? null : form.changeWorkspace,
                  onRetry: () => ref.invalidate(workspaceListProvider),
                ),

                // Amount Input - Priority 1. Prefix/suffix tint follows the
                // selected transaction type (expense = red, income = green).
                _AmountField(
                  controller: form.amountController,
                  type: selectedType.value,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Wallet Selector - required; pre-filled with the default
                // wallet.
                _WalletSection(
                  type: selectedType.value,
                  wallet: form.selectedWallet.value,
                  toWallet: form.selectedToWallet.value,
                  workspaceId: form.selectedWorkspaceId.value,
                  onWalletPicked: (picked) =>
                      form.selectedWallet.value = picked,
                  onToWalletPicked: (picked) =>
                      form.selectedToWallet.value = picked,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category Selector - Priority 2. Transfers carry no category.
                if (selectedType.value != model.TransactionType.transfer)
                  _CategorySection(
                    categoriesAsync: form.categoriesAsync,
                    type: selectedType.value,
                    selectedCategoryId: form.selectedCategoryId.value,
                    onSelected: (id) => form.selectedCategoryId.value = id,
                    onAdd: form.addCategory,
                    onRetry: () => ref.invalidate(
                      categoriesForWorkspaceProvider(
                        form.selectedWorkspaceId.value!,
                      ),
                    ),
                  ),
                if (selectedType.value != model.TransactionType.transfer)
                  const SizedBox(height: AppSpacing.lg),

                // Date Picker - Priority 3 with Quick Select
                _DateSection(
                  selectedDate: form.selectedDate.value,
                  onChanged: (date) => form.selectedDate.value = date,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Note and Receipt - Optional Details Section
                _NoteAndReceiptSection(
                  noteController: form.noteController,
                  receiptPath: form.localReceiptPath.value,
                  onPickReceipt: form.pickReceipt,
                  onRemoveReceipt: form.removeReceipt,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_AddTransactionForm _useAddTransactionForm(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  model.TransactionType? initialType,
  Workspace? activeWorkspace,
) {
  // Form state
  final amountController = useTextEditingController();
  final noteController = useTextEditingController();
  final selectedDate = useState(DateTime.now());
  final selectedType = useState(initialType ?? model.TransactionType.expense);
  final selectedWorkspaceId = useState<String?>(activeWorkspace?.id);
  final selectedCategoryId = useState<String?>(null);
  final selectedWallet = useState<Wallet?>(null);
  final selectedToWallet = useState<Wallet?>(null);
  final localReceiptPath = useState<String?>(null);
  final isLoading = useState(false);
  final allowOverdraft = useState(false);
  final formKey = useMemoized(GlobalKey<FormState>.new);
  useListenable(amountController);
  useListenable(noteController);
  final categoriesAsync = selectedWorkspaceId.value == null
      ? const AsyncValue<List<Category>>.data([])
      : ref.watch(categoriesForWorkspaceProvider(selectedWorkspaceId.value!));
  final walletsAsync = selectedWorkspaceId.value == null
      ? const AsyncValue<List<Wallet>>.data([])
      : ref.watch(walletsForWorkspaceProvider(selectedWorkspaceId.value!));

  if (selectedWorkspaceId.value != null &&
      selectedWorkspaceId.value == ref.watch(activeWorkspaceIdProvider)) {
    ref.watch(categoryClassifierProvider);
  }

  final form = _AddTransactionForm(
    context: context,
    ref: ref,
    l10n: l10n,
    amountController: amountController,
    noteController: noteController,
    selectedDate: selectedDate,
    selectedType: selectedType,
    selectedWorkspaceId: selectedWorkspaceId,
    selectedCategoryId: selectedCategoryId,
    selectedWallet: selectedWallet,
    selectedToWallet: selectedToWallet,
    localReceiptPath: localReceiptPath,
    isLoading: isLoading,
    allowOverdraft: allowOverdraft,
    formKey: formKey,
    categoriesAsync: categoriesAsync,
    walletsAsync: walletsAsync,
  );

  useEffect(() {
    if (selectedWorkspaceId.value == null && activeWorkspace != null) {
      selectedWorkspaceId.value = activeWorkspace.id;
    }
    return null;
  }, [activeWorkspace]);

  // Pre-select the default wallet so the extra required field costs no taps.
  final wallets = walletsAsync.valueOrNull;
  useEffect(() {
    if (wallets == null || wallets.isEmpty) {
      return null;
    }
    final current = selectedWallet.value;
    if (current == null || !wallets.any((w) => w.id == current.id)) {
      selectedWallet.value = wallets.firstWhere(
        (w) => w.isDefault,
        orElse: () => wallets.first,
      );
      selectedToWallet.value = null;
    }
    return null;
  }, [wallets]);

  final categories = categoriesAsync.valueOrNull;
  useEffect(() {
    final workspaceId = selectedWorkspaceId.value;
    if (categories == null ||
        workspaceId == null ||
        selectedCategoryId.value != null ||
        selectedType.value == model.TransactionType.transfer) {
      return null;
    }
    final lastUsedId = ref.read(sharedPreferencesProvider).getString(
          lastUsedCategoryPreferenceKey(
            workspaceId,
            selectedType.value.name,
          ),
        );
    final expectedType = selectedType.value == model.TransactionType.expense
        ? CategoryType.expense
        : CategoryType.income;
    if (categories
        .any((c) => c.id == lastUsedId && c.type == expectedType)) {
      selectedCategoryId.value = lastUsedId;
    }
    return null;
  }, [categories, selectedType.value, selectedWorkspaceId.value]);
  return form;
}

class _AddTransactionForm {
  final BuildContext context;
  final WidgetRef ref;
  final AppLocalizations l10n;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final ValueNotifier<DateTime> selectedDate;
  final ValueNotifier<model.TransactionType> selectedType;
  final ValueNotifier<String?> selectedWorkspaceId;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueNotifier<Wallet?> selectedWallet;
  final ValueNotifier<Wallet?> selectedToWallet;
  final ValueNotifier<String?> localReceiptPath;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<bool> allowOverdraft;
  final GlobalKey<FormState> formKey;
  final AsyncValue<List<Category>> categoriesAsync;
  final AsyncValue<List<Wallet>> walletsAsync;

  _AddTransactionForm({
    required this.context,
    required this.ref,
    required this.l10n,
    required this.amountController,
    required this.noteController,
    required this.selectedDate,
    required this.selectedType,
    required this.selectedWorkspaceId,
    required this.selectedCategoryId,
    required this.selectedWallet,
    required this.selectedToWallet,
    required this.localReceiptPath,
    required this.isLoading,
    required this.allowOverdraft,
    required this.formKey,
    required this.categoriesAsync,
    required this.walletsAsync,
  });

  bool get isAmountValid {
    final amountValue = CurrencyFormatter.parseVND(amountController.text);
    return amountValue != null && amountValue > 0;
  }

  bool get isDirty =>
      amountController.text.isNotEmpty ||
      noteController.text.isNotEmpty ||
      localReceiptPath.value != null;

  Future<bool?> confirmBudgetExceeded(BudgetExceededException error) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.budgetExceeded),
        content: Text(error.message),
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
  }

  Future<void> rememberLastUsedCategory(
    model.Transaction transaction,
  ) async {
    final workspaceId = selectedWorkspaceId.value;
    final categoryId = transaction.categoryId;
    if (workspaceId == null || categoryId == null) return;
    await ref.read(sharedPreferencesProvider).setString(
          lastUsedCategoryPreferenceKey(workspaceId, transaction.type.name),
          categoryId,
        );
  }

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
      final repository = ref.read(transactionRepositoryProvider);
      final receiptService = ref.read(transactionReceiptServiceProvider);
      final amount = CurrencyFormatter.parseVND(amountController.text)!;
      final amountCents = CurrencyFormatter.toCents(amount);

      final transaction = model.Transaction(
        id: '',
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

      final createdTransaction = await repository.createTransaction(
        transaction,
        allowOverdraft: overdraftAllowed,
        workspaceIdOverride: selectedWorkspaceId.value,
      );

      String? receiptWarning;
      if (localReceiptPath.value != null) {
        try {
          await receiptService.attachReceipt(
            transactionId: createdTransaction.id,
            localFilePath: localReceiptPath.value!,
            workspaceIdOverride: selectedWorkspaceId.value,
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'Receipt upload failed after transaction creation',
            name: 'MM.UI',
            error: e,
            stackTrace: stackTrace,
          );
          receiptWarning = l10n.transactionSavedReceiptUploadFailed;
        }
      }

      await rememberLastUsedCategory(createdTransaction);

      ref.invalidate(budgetsProvider);
      ref.invalidate(budgetsWithConsumedProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletBalancesProvider);
      ref.invalidate(
          transactionReceiptAttachmentProvider(createdTransaction.id));
      ref.invalidate(
          transactionReceiptImageUrlProvider(createdTransaction.id));

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
        final shouldProceed = await confirmBudgetExceeded(e);

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
          action: 'create_transaction',
          screen: 'add_transaction_screen',
          extraContext: {
            'workspace_id': selectedWorkspaceId.value,
            'category_id': selectedCategoryId.value,
            'wallet_id': selectedWallet.value?.id,
            'transaction_type': selectedType.value.toString(),
            'has_receipt': localReceiptPath.value != null,
          },
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveQuickInput(
    VoiceParseResult result,
    String workspaceId,
  ) async {
    final now = DateTime.now();
    final transaction = model.Transaction(
      id: '',
      amountCents: CurrencyFormatter.toCents(result.amountVnd!),
      currency: 'VND',
      dateTime: result.date ?? now,
      categoryId: result.categoryId,
      type: result.type!,
      walletId: result.walletId!,
      note: result.note,
      createdAt: now,
      updatedAt: now,
    );
    final repository = ref.read(transactionRepositoryProvider);
    try {
      try {
        await repository.createTransaction(
          transaction,
          workspaceIdOverride: workspaceId,
        );
      } on BudgetExceededException catch (error) {
        if (!context.mounted || await confirmBudgetExceeded(error) != true) {
          return false;
        }
        await repository.createTransaction(
          transaction,
          workspaceIdOverride: workspaceId,
          allowOverdraft: true,
        );
      }
      invalidateCoreDataProviders(ref);
      ref.invalidate(walletBalancesProvider);
      return true;
    } catch (error, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: error,
          stackTrace: stackTrace,
          feature: 'transaction',
          action: 'create_transaction',
          screen: 'add_transaction_screen',
          extraContext: {
            'workspace_id': workspaceId,
            'category_id': result.categoryId,
            'wallet_id': result.walletId,
            'transaction_type': result.type.toString(),
            'has_receipt': false,
          },
        );
      }
      return false;
    }
  }

  Future<void> handleVoiceInput() async {
    final workspaceId = selectedWorkspaceId.value;
    final categories = categoriesAsync.valueOrNull ?? const <Category>[];
    final availableWallets = (walletsAsync.valueOrNull ?? const <Wallet>[])
        .where((wallet) => !wallet.isArchived && wallet.deletedAt == null)
        .toList();
    final history = workspaceId == ref.read(activeWorkspaceIdProvider)
        ? ref.read(categoryClassifierProvider)
        : null;
    final classifier =
        history?.isLoading == false ? history?.valueOrNull : null;
    final results = await showQuickInputSheet(
      context,
      categories: categories,
      wallets: availableWallets,
      classifier: classifier,
    );
    if (results == null || results.isEmpty || !context.mounted) return;

    model.TransactionType? resolvedType(VoiceParseResult result) {
      final category = categories
          .where((category) => category.id == result.categoryId)
          .firstOrNull;
      return result.type ??
          (category == null
              ? null
              : category.type == CategoryType.income
                  ? model.TransactionType.income
                  : model.TransactionType.expense);
    }

    if (results.length > 1 && workspaceId != null) {
      final reviewItems = results.map((result) {
        final wallet = availableWallets
                .where((wallet) => wallet.id == result.walletId)
                .firstOrNull ??
            selectedWallet.value;
        return VoiceParseResult(
          rawText: result.rawText,
          amountVnd: result.amountVnd,
          date: result.date ?? selectedDate.value,
          type: resolvedType(result) ??
              (selectedType.value == model.TransactionType.income
                  ? model.TransactionType.income
                  : model.TransactionType.expense),
          categoryId: result.categoryId,
          categoryName: result.categoryName,
          walletId: wallet?.id,
          walletName: wallet?.name,
          note: result.note,
          categoryConfidence: result.categoryConfidence,
        );
      }).toList();
      final saved = await showQuickInputReviewSheet(
        context,
        results: reviewItems,
        categories: categories,
        wallets: availableWallets,
        onSave: (result) => saveQuickInput(result, workspaceId),
      );
      if (saved == true && context.mounted) {
        showAppSnackBar(context, l10n.success, type: AppSnackBarType.success);
        Navigator.of(context).pop(true);
      }
      return;
    }

    final result = results.first;
    final type = resolvedType(result);
    if (type != null && type != selectedType.value) {
      selectedType.value = type;
      selectedCategoryId.value = null;
      if (type != model.TransactionType.transfer) {
        selectedToWallet.value = null;
      }
    }
    if (result.date != null) {
      selectedDate.value = result.date!;
    }
    if (result.amountVnd != null) {
      amountController.text =
          CurrencyFormatter.formatInputVND(result.amountVnd!.round().toString());
    }
    if (result.categoryId != null) {
      selectedCategoryId.value = result.categoryId;
    }
    final wallet = availableWallets
        .where((wallet) => wallet.id == result.walletId)
        .firstOrNull;
    if (wallet != null) selectedWallet.value = wallet;
    if (result.note != null) {
      noteController.text = result.note!;
    }
  }

  Future<void> pickReceipt() async {
    AppLogger.info('Receipt capture started', name: 'MM.UI');
    final ImagePicker picker = ImagePicker();
    final source = await showReceiptSourcePicker(context);
    if (source == null) return;
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      localReceiptPath.value = image.path;
      AppLogger.info('Receipt attached to new transaction', name: 'MM.UI');
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

  void changeWorkspace(String? value) {
    selectedWorkspaceId.value = value;
    selectedCategoryId.value = null;
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
        'workspaceId': selectedWorkspaceId.value,
      },
    );
    if (result == true) {
      ref.invalidate(categoriesProvider);
      final workspaceId = selectedWorkspaceId.value;
      if (workspaceId != null) {
        ref.invalidate(
          categoriesForWorkspaceProvider(
          workspaceId,
        ),
        );
      }
    }
  }

  void removeReceipt() {
    localReceiptPath.value = null;
    AppLogger.info(
      'Receipt removed from new transaction',
      name: 'MM.UI',
    );
  }
}

class _WorkspaceSection extends StatelessWidget {
  final AsyncValue<List<Workspace>> workspacesAsync;
  final String? selectedWorkspaceId;
  final ValueChanged<String?>? onChanged;
  final VoidCallback onRetry;

  const _WorkspaceSection({
    required this.workspacesAsync,
    required this.selectedWorkspaceId,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return workspacesAsync.when(
      data: (workspaces) {
        if (workspaces.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workspace,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: selectedWorkspaceId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
              items: workspaces
                  .map(
                    (workspace) => DropdownMenuItem<String>(
                      value: workspace.id,
                      child: Text(
                        workspace.type == 'personal'
                            ? l10n.personal
                            : workspace.name,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sectionGap),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(
          bottom: AppSpacing.sectionGap,
        ),
        child: InlineLoadErrorState(
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final model.TransactionType type;

  const _AmountField({
    required this.controller,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppInput(
      label: l10n.amount,
      hint: '0',
      controller: controller,
      autofocus: true,
      validator: (value) => validateTransactionAmount(value, l10n),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        VNDInputFormatter(),
      ],
      suffixIcon: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        child: Text(
          CurrencyFormatter.getCurrencySymbol('VND'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _amountAccent(context, type),
              ),
        ),
      ),
    );
  }

  /// Tint of the amount field: red for expense, green for income, and the
  /// theme primary for transfers, which are neither.
  Color _amountAccent(BuildContext context, model.TransactionType type) {
    switch (type) {
      case model.TransactionType.expense:
        return context.semanticColors.expense;
      case model.TransactionType.income:
        return context.semanticColors.income;
      case model.TransactionType.transfer:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _WalletSection extends StatelessWidget {
  final model.TransactionType type;
  final Wallet? wallet;
  final Wallet? toWallet;
  final String? workspaceId;
  final ValueChanged<Wallet> onWalletPicked;
  final ValueChanged<Wallet> onToWalletPicked;

  const _WalletSection({
    required this.type,
    required this.wallet,
    required this.toWallet,
    required this.workspaceId,
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
              workspaceId: workspaceId,
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
                workspaceId: workspaceId,
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
        // Filter categories by selected transaction type
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
        // Quick date selection buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  onChanged(DateTime.now());
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: _isSameDay(selectedDate, DateTime.now())
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : null,
                ),
                child: Text(l10n.today),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  onChanged(
                    DateTime.now().subtract(const Duration(days: 1)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: _isSameDay(
                    selectedDate,
                    DateTime.now().subtract(const Duration(days: 1)),
                  )
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : null,
                ),
                child: Text(l10n.yesterday),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
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
                child: const Icon(Icons.calendar_today, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Selected date display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event,
                  size: AppSpacing.iconSizeSm,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatLocalizedDate(context, selectedDate),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class _NoteAndReceiptSection extends StatelessWidget {
  final TextEditingController noteController;
  final String? receiptPath;
  final VoidCallback onPickReceipt;
  final VoidCallback onRemoveReceipt;

  const _NoteAndReceiptSection({
    required this.noteController,
    required this.receiptPath,
    required this.onPickReceipt,
    required this.onRemoveReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      title: Text(
        l10n.noteAndReceipt,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      subtitle: Text(
        l10n.optional,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              // Note Input
              AppInput(
                label: l10n.note,
                hint: l10n.note,
                controller: noteController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Receipt Attachment
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receiptPath == null
                              ? l10n.attachReceipt
                              : l10n.viewReceipt,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (receiptPath != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusCard),
                            child: Image.file(
                              File(receiptPath!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.attachReceipt,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    onPressed: onPickReceipt,
                  ),
                  if (receiptPath != null)
                    IconButton(
                      tooltip: l10n.removeReceipt,
                      icon: const Icon(Icons.clear),
                      onPressed: onRemoveReceipt,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
