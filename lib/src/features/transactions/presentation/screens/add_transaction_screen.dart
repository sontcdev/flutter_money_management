import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/transaction_type_toggle.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
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
    final categoriesAsync = selectedWorkspaceId.value == null
        ? const AsyncValue<List<Category>>.data([])
        : ref.watch(categoriesForWorkspaceProvider(selectedWorkspaceId.value!));
    final walletsAsync = selectedWorkspaceId.value == null
        ? const AsyncValue<List<Wallet>>.data([])
        : ref.watch(walletsForWorkspaceProvider(selectedWorkspaceId.value!));

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

    Future<void> handleSubmit() async {
      if (amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.amountRequiredError)),
        );
        return;
      }

      final isTransfer = selectedType.value == model.TransactionType.transfer;

      if (!isTransfer && selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.selectCategoryError)),
        );
        return;
      }

      if (selectedWallet.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.walletRequired)),
        );
        return;
      }

      if (isTransfer) {
        if (selectedToWallet.value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.walletRequired)),
          );
          return;
        }
        if (selectedToWallet.value!.id == selectedWallet.value!.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sameWalletError)),
          );
          return;
        }
      }

      isLoading.value = true;

      try {
        final repository = ref.read(transactionRepositoryProvider);
        final receiptService = ref.read(transactionReceiptServiceProvider);
        final amount = CurrencyFormatter.parseVND(amountController.text);
        if (amount == null) {
          throw const FormatException('Invalid amount format');
        }
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
          allowOverdraft: allowOverdraft.value,
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

        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(walletBalancesProvider);
        ref.invalidate(
            transactionReceiptAttachmentProvider(createdTransaction.id));
        ref.invalidate(
            transactionReceiptImageUrlProvider(createdTransaction.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(receiptWarning ?? l10n.success)),
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
            handleSubmit();
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

    Future<void> pickReceipt() async {
      AppLogger.info('Receipt capture started', name: 'MM.UI');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        localReceiptPath.value = image.path;
        AppLogger.info('Receipt attached to new transaction', name: 'MM.UI');
      } else {
        AppLogger.debug('Receipt capture cancelled', name: 'MM.UI');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addTransaction),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Toggle - pill-shaped segmented control on a surface2 track,
            // matching the mockup's "Chi tiêu / Thu nhập" switch.
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
                      'Workspace',
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
                                    ? 'Personal'
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
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Amount Input - Priority 1. Prefix/suffix tint follows the
            // selected transaction type (expense = red, income = green).
            AppInput(
              label: l10n.amount,
              hint: '0',
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                VNDInputFormatter(),
              ],
              prefixIcon: Icon(
                Icons.attach_money,
                color: _amountAccent(context, selectedType.value),
              ),
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

            // Wallet Selector - required; pre-filled with the default wallet.
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
                                  categoriesForWorkspaceProvider(workspaceId),
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
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: filteredCategories.map((category) {
                          final isSelected =
                              selectedCategoryId.value == category.id;
                          final categoryColor =
                              getCategoryColor(category.colorValue);
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
                                color: categoryColor.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: categoryColor,
                                  width: isSelected ? 3 : 1.5,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXl),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CategoryIconWidget(
                                    iconName: category.iconName,
                                    size: 18,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: categoryColor,
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
                error: (err, stack) => Text(l10n.errorWithMessage('$err')),
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
                          selectedDate.value =
                              DateTime.now().subtract(const Duration(days: 1));
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isSameDay(
                            selectedDate.value,
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
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate.value,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            selectedDate.value = picked;
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formatLocalizedDate(context, selectedDate.value),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                '${l10n.note} & ${l10n.receipt}',
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
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (localReceiptPath.value != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
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
                            icon: const Icon(Icons.camera_alt),
                            onPressed: pickReceipt,
                          ),
                          if (localReceiptPath.value != null)
                            IconButton(
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
            const SizedBox(height: AppSpacing.sectionGap),

            // Sticky Save Button - Prominent CTA
            AppButton.prominent(
              text: l10n.save,
              onPressed: handleSubmit,
              isLoading: isLoading.value,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Tint of the amount field: red for expense, green for income, and the
  /// theme primary for transfers, which are neither.
  Color _amountAccent(BuildContext context, model.TransactionType type) {
    switch (type) {
      case model.TransactionType.expense:
        return AppColors.expense;
      case model.TransactionType.income:
        return AppColors.income;
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
