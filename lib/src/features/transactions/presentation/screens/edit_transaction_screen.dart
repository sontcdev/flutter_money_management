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
import 'package:flutter_money_management/src/features/transactions/models/transaction_attachment.dart';
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
    final localReceiptPath = useState<String?>(null);
    final existingReceiptAttachment = useState<TransactionAttachment?>(null);
    final shouldRemoveReceipt = useState(false);
    final isLoading = useState(false);
    final allowOverdraft = useState(false);
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
      });
      return null;
    }, [transactionId, attachmentRepository, repository]);

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
          categoryId: selectedCategoryId.value!,
          type: selectedType.value,
          note: noteController.text.isEmpty ? null : noteController.text,
          receiptPath: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.updateTransaction(
          transaction,
          allowOverdraft: allowOverdraft.value,
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
        ref.invalidate(transactionReceiptAttachmentProvider(transactionId));
        ref.invalidate(transactionReceiptImageUrlProvider(transactionId));

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
            action: 'update_transaction',
            screen: 'edit_transaction_screen',
            extraContext: {
              'transaction_id': transactionId,
              'category_id': selectedCategoryId.value!,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editTransaction),
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
                  selectedCategoryId.value = null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

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
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        selectedDate.value = selectedDate.value
                            .subtract(const Duration(days: 1));
                      },
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                formatLocalizedDate(
                                    context, selectedDate.value),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text(l10n.errorWithMessage('$error')),
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
                          icon: const Icon(Icons.camera_alt),
                          onPressed: pickReceipt,
                        ),
                        if (localReceiptPath.value != null ||
                            existingReceiptAttachment.value != null)
                          IconButton(
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
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
    );
  }
}
