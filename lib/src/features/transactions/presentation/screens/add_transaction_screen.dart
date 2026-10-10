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
    final amountValue = CurrencyFormatter.parseVND(amountController.text);
    final isAmountValid = amountValue != null && amountValue > 0;
    final isDirty = amountController.text.isNotEmpty ||
        noteController.text.isNotEmpty ||
        localReceiptPath.value != null;
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

    return TransactionDiscardGuard(
      isDirty: isDirty && !isLoading.value,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addTransaction),
          actions: [
            IconButton(
              icon: const Icon(Icons.bolt_outlined),
              tooltip: l10n.quickInputTooltip,
              onPressed: isLoading.value ? null : handleVoiceInput,
            ),
          ],
        ),
        bottomNavigationBar: TransactionSaveBar(
          text: l10n.save,
          onPressed: isAmountValid ? handleSubmit : null,
          isLoading: isLoading.value,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: formKey,
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
                  onChanged: (type) {
                    selectedType.value = type;
                    selectedCategoryId.value = null;
                    if (type != model.TransactionType.transfer) {
                      selectedToWallet.value = null;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                workspacesAsync.when(
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
                          initialValue: selectedWorkspaceId.value,
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
                          onChanged: isLoading.value
                              ? null
                              : (value) {
                                  selectedWorkspaceId.value = value;
                                  selectedCategoryId.value = null;
                                },
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
                      onRetry: () => ref.invalidate(workspaceListProvider),
                    ),
                  ),
                ),

                // Amount Input - Priority 1. Prefix/suffix tint follows the
                // selected transaction type (expense = red, income = green).
                AppInput(
                  label: l10n.amount,
                  hint: '0',
                  controller: amountController,
                  autofocus: true,
                  validator: (value) => validateTransactionAmount(value, l10n),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                            color: _amountAccent(context, selectedType.value),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Wallet Selector - required; pre-filled with the default
                // wallet.
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
                      workspaceId: selectedWorkspaceId.value,
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
                        workspaceId: selectedWorkspaceId.value,
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
                    // Filter categories by selected transaction type
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
                      onRetry: () => ref.invalidate(
                        categoriesForWorkspaceProvider(
                          selectedWorkspaceId.value!,
                        ),
                      ),
                    ),
                  ),
                if (selectedType.value != model.TransactionType.transfer)
                  const SizedBox(height: AppSpacing.lg),

                // Date Picker - Priority 3 with Quick Select
                Column(
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
                              selectedDate.value = DateTime.now();
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  _isSameDay(selectedDate.value, DateTime.now())
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
                              selectedDate.value = DateTime.now()
                                  .subtract(const Duration(days: 1));
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _isSameDay(
                                selectedDate.value,
                                DateTime.now()
                                    .subtract(const Duration(days: 1)),
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusCard),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event,
                              size: AppSpacing.iconSizeSm,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formatLocalizedDate(context, selectedDate.value),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Note and Receipt - Optional Details Section
                ExpansionTile(
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                                      localReceiptPath.value == null
                                          ? l10n.attachReceipt
                                          : l10n.viewReceipt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    if (localReceiptPath.value != null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusCard),
                                        child: Image.file(
                                          File(localReceiptPath.value!),
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
                                onPressed: pickReceipt,
                              ),
                              if (localReceiptPath.value != null)
                                IconButton(
                                  tooltip: l10n.removeReceipt,
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    localReceiptPath.value = null;
                                    AppLogger.info(
                                      'Receipt removed from new transaction',
                                      name: 'MM.UI',
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
