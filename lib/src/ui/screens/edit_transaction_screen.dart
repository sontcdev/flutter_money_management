// path: lib/src/ui/screens/edit_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart' as model;
import '../../models/category.dart';
import '../../services/budget_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/vnd_input_formatter.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/category_icon_widget.dart';

class EditTransactionScreen extends HookConsumerWidget {
  final int transactionId;

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
    final selectedCategoryId = useState<int?>(null);
    final receiptPath = useState<String?>(null);
    final isLoading = useState(false);
    final allowOverdraft = useState(false);

    // Load existing transaction for editing
    useEffect(() {
      Future.microtask(() async {
        final transaction = await repository.getTransactionById(transactionId);
        final amount = (transaction.amountCents / 100).round();
        amountController.text = CurrencyFormatter.formatInputVND(amount.toString());
        noteController.text = transaction.note ?? '';
        selectedDate.value = transaction.dateTime;
        selectedType.value = transaction.type;
        selectedCategoryId.value = transaction.categoryId;
        receiptPath.value = transaction.receiptPath;
      });
      return null;
    }, [transactionId]);

    Future<void> handleSubmit() async {
      if (amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${l10n.amount}')),
        );
        return;
      }

      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${l10n.selectCategory}')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final amount = CurrencyFormatter.parseVND(amountController.text);
        if (amount == null) {
          throw FormatException('Invalid amount format');
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
          receiptPath: receiptPath.value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.updateTransaction(transaction);

        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
        ref.invalidate(transactionsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.success)),
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
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> pickReceipt() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        receiptPath.value = image.path;
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                child: Text(
                  '₫',
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
                              arguments: {'initialType': selectedType.value == model.TransactionType.expense ? CategoryType.expense : CategoryType.income},
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
                          final isSelected = selectedCategoryId.value == category.id;
                          final categoryColor = getCategoryColor(category.colorValue);
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
                                color: categoryColor.withOpacity(0.2),
                                border: Border.all(
                                  color: categoryColor,
                                  width: isSelected ? 3 : 1.5,
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
              error: (err, stack) => Text('Error: $err'),
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
                        selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
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
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${selectedDate.value.day.toString().padLeft(2, '0')}/${selectedDate.value.month.toString().padLeft(2, '0')}/${selectedDate.value.year}',
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
                        selectedDate.value = selectedDate.value.add(const Duration(days: 1));
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    receiptPath.value == null
                        ? l10n.attachReceipt
                        : l10n.viewReceipt,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: pickReceipt,
                ),
                if (receiptPath.value != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => receiptPath.value = null,
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
