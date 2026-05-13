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
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
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
    final localReceiptPath = useState<String?>(null);
    final isLoading = useState(false);
    final allowOverdraft = useState(false);
    final categoriesAsync = selectedWorkspaceId.value == null
        ? const AsyncValue<List<Category>>.data([])
        : ref.watch(categoriesForWorkspaceProvider(selectedWorkspaceId.value!));

    useEffect(() {
      if (selectedWorkspaceId.value == null && activeWorkspace != null) {
        selectedWorkspaceId.value = activeWorkspace.id;
      }
      return null;
    }, [activeWorkspace]);

    Future<void> handleSubmit() async {
      if (amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.amountRequiredError)),
        );
        return;
      }

      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.selectCategoryError)),
        );
        return;
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
          categoryId: selectedCategoryId.value!,
          type: selectedType.value,
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
              'category_id': selectedCategoryId.value!,
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
            // Type Toggle - Centered
            Center(
              child: SegmentedButton<model.TransactionType>(
                segments: [
                  ButtonSegment(
                    value: model.TransactionType.expense,
                    label: Text(l10n.expense),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: model.TransactionType.income,
                    label: Text(l10n.income),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {selectedType.value},
                onSelectionChanged: (Set<model.TransactionType> selection) {
                  selectedType.value = selection.first;
                  // Reset category when type changes
                  selectedCategoryId.value = null;
                },
              ),
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
                      value: selectedWorkspaceId.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
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
              prefixIcon: const Icon(Icons.attach_money),
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                child: Text(
                  CurrencyFormatter.getCurrencySymbol('VND'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category Selector - Priority 2
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
                                    : CategoryType.income
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
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formatLocalizedDate(context, selectedDate.value),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
