// path: lib/src/ui/screens/add_transaction_screen.dart

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
import '../../utils/currency_formatter.dart';
import '../../utils/vnd_input_formatter.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class AddTransactionScreen extends HookConsumerWidget {
  final int? transactionId;

  const AddTransactionScreen({super.key, this.transactionId});

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
    final showAllCategories = useState(false);

    // Load existing transaction if editing
    useEffect(() {
      if (transactionId != null) {
        Future.microtask(() async {
          final transaction = await repository.getTransactionById(transactionId!);
          // Format amount as VND (without decimals)
          final amount = (transaction.amountCents / 100).round();
          amountController.text = CurrencyFormatter.formatInputVND(amount.toString());
          noteController.text = transaction.note ?? '';
          selectedDate.value = transaction.dateTime;
          selectedType.value = transaction.type;
          selectedCategoryId.value = transaction.categoryId;
          receiptPath.value = transaction.receiptPath;
        });
      }
      return null;
    }, [transactionId]);

    Future<void> handleSubmit() async {
      // Validation
      if (amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: Amount is required')),
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
        // Parse VND formatted input (remove dots and parse)
        final amount = CurrencyFormatter.parseVND(amountController.text);
        if (amount == null) {
          throw FormatException('Invalid amount format');
        }
        final amountCents = CurrencyFormatter.toCents(amount);

        final transaction = model.Transaction(
          id: transactionId ?? 0,
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

        if (transactionId == null) {
          // Create new transaction
          await repository.createTransaction(
            transaction,
            allowOverdraft: allowOverdraft.value,
          );
        } else {
          // Update existing transaction
          await repository.updateTransaction(transaction);
        }

        // Invalidate providers to refresh data
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
                  child: const Text('Proceed Anyway'),
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
        title: Text(transactionId == null
            ? l10n.addTransaction
            : l10n.editTransaction),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Toggle
            SegmentedButton<model.TransactionType>(
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
                // Reset category when transaction type changes
                selectedCategoryId.value = null;
              },
            ),
            const SizedBox(height: 24),

            // Date Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.date,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedDate.value.day.toString().padLeft(2, '0')}/${selectedDate.value.month.toString().padLeft(2, '0')}/${selectedDate.value.year}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        selectedDate.value = selectedDate.value.add(const Duration(days: 1));
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note Input
            AppInput(
              label: l10n.note,
              hint: 'Note',
              controller: noteController,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Amount Input
            AppInput(
              label: l10n.amount,
              hint: '0',
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                VNDInputFormatter(),
              ],
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            const SizedBox(height: 16),

            // Category Selector
            categoriesAsync.when(
              data: (categories) {
                // Filter categories by transaction type
                final filteredCategories = categories.where((c) {
                  if (selectedType.value == model.TransactionType.expense) {
                    return c.type == CategoryType.expense;
                  } else {
                    return c.type == CategoryType.income;
                  }
                }).toList();

                if (filteredCategories.isEmpty) {
                  return Text(l10n.noCategories);
                }

                // Determine how many categories to show
                final int displayCount = showAllCategories.value 
                    ? filteredCategories.length 
                    : (filteredCategories.length > 15 ? 15 : filteredCategories.length);
                final categoriesToShow = filteredCategories.take(displayCount).toList();
                final hasMore = filteredCategories.length > 15;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.category,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoriesToShow.map((category) {
                        final isSelected = selectedCategoryId.value == category.id;
                        return GestureDetector(
                          onTap: () {
                            selectedCategoryId.value = category.id;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Color(category.colorValue).withOpacity(0.2)
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected 
                                    ? Color(category.colorValue)
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.iconName,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected 
                                        ? Color(category.colorValue)
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (hasMore && !showAllCategories.value) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            showAllCategories.value = true;
                          },
                          icon: const Icon(Icons.expand_more, size: 18),
                          label: Text('Show more (${filteredCategories.length - 15} more)'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                    if (hasMore && showAllCategories.value) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            showAllCategories.value = false;
                          },
                          icon: const Icon(Icons.expand_less, size: 18),
                          label: const Text('Show less'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),

            // Receipt Attachment
            Row(
              children: [
                Expanded(
                  child: Text(
                    receiptPath.value == null
                        ? l10n.attachReceipt
                        : 'Receipt attached',
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
            const SizedBox(height: 32),

            // Submit Button
            AppButton(
              text: l10n.save,
              onPressed: handleSubmit,
              isLoading: isLoading.value,
            ),
          ],
        ),
      ),
    );
  }
}

