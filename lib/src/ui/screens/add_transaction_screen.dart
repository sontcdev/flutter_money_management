// path: lib/src/ui/screens/add_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart' as model;
import '../../services/budget_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class AddTransactionScreen extends HookConsumerWidget {
  final int? transactionId;

  const AddTransactionScreen({Key? key, this.transactionId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.watch(transactionRepositoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final amountController = useTextEditingController();
    final noteController = useTextEditingController();
    final selectedDate = useState(DateTime.now());
    final selectedType = useState(model.TransactionType.expense);
    final selectedCategoryId = useState<int?>(null);
    final selectedAccountId = useState<int?>(null);
    final receiptPath = useState<String?>(null);
    final isLoading = useState(false);
    final allowOverdraft = useState(false);

    // Load existing transaction if editing
    useEffect(() {
      if (transactionId != null) {
        Future.microtask(() async {
          final transaction = await repository.getTransactionById(transactionId!);
          amountController.text = (transaction.amountCents / 100).toString();
          noteController.text = transaction.note ?? '';
          selectedDate.value = transaction.dateTime;
          selectedType.value = transaction.type;
          selectedCategoryId.value = transaction.categoryId;
          selectedAccountId.value = transaction.accountId;
          receiptPath.value = transaction.receiptPath;
        });
      }
      return null;
    }, [transactionId]);

    Future<void> handleSubmit() async {
      // Validation
      if (amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error + ': Amount is required')),
        );
        return;
      }

      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error + ': ${l10n.selectCategory}')),
        );
        return;
      }

      if (selectedAccountId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error + ': ${l10n.selectAccount}')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final amountCents = (double.parse(amountController.text) * 100).round();

        final transaction = model.Transaction(
          id: transactionId ?? 0,
          amountCents: amountCents,
          currency: 'USD',
          dateTime: selectedDate.value,
          categoryId: selectedCategoryId.value!,
          accountId: selectedAccountId.value!,
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
              },
            ),
            const SizedBox(height: 24),

            // Amount Input
            AppInput(
              label: l10n.amount,
              hint: '0.00',
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 16),

            // Category Selector
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Text(l10n.noCategories);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.category,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId.value,
                      decoration: const InputDecoration(
                        hintText: 'Select category',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(category.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedCategoryId.value = value;
                      },
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),

            // Account Selector
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return Text(l10n.noAccounts);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.account,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedAccountId.value,
                      decoration: const InputDecoration(
                        hintText: 'Select account',
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedAccountId.value = value;
                      },
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),

            // Date Picker
            AppInput(
              label: l10n.date,
              controller: TextEditingController(
                text: '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}',
              ),
              readOnly: true,
              suffixIcon: const Icon(Icons.calendar_today),
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
            ),
            const SizedBox(height: 16),

            // Note Input
            AppInput(
              label: l10n.note,
              hint: 'Add a note (optional)',
              controller: noteController,
              maxLines: 3,
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

