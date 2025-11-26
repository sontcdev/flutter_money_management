// path: lib/src/ui/screens/home_screen.dart

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
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/vnd_input_formatter.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/transaction_item.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'report_calendar_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = useState(0);
    
    final screens = [
      const _AddTransactionTab(),
      const CategoriesScreen(),
      const BudgetsScreen(),
      const ReportCalendarScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex.value,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) {
          // Invalidate providers when switching tabs to ensure fresh data
          if (index != currentIndex.value) {
            ref.invalidate(budgetsProvider);
            ref.invalidate(budgetsWithConsumedProvider);
            ref.invalidate(transactionsProvider);
          }
          currentIndex.value = index;
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: const Icon(Icons.add_circle),
            label: l10n.add,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category_outlined),
            activeIcon: const Icon(Icons.category),
            label: l10n.categories,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.budgets,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            activeIcon: const Icon(Icons.calendar_month),
            label: l10n.calendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: l10n.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

class _AddTransactionTab extends HookConsumerWidget {
  const _AddTransactionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    
    // Add transaction form state
    final amountController = useTextEditingController();
    final noteController = useTextEditingController();
    final selectedDate = useState(DateTime.now());
    final selectedType = useState(model.TransactionType.expense);
    final selectedCategoryId = useState<int?>(null);
    final receiptPath = useState<String?>(null);
    final isLoading = useState(false);
    final allowOverdraft = useState(false);

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
        final repository = ref.read(transactionRepositoryProvider);
        final amount = CurrencyFormatter.parseVND(amountController.text);
        if (amount == null) {
          throw FormatException('Invalid amount format');
        }
        final amountCents = CurrencyFormatter.toCents(amount);

        final transaction = model.Transaction(
          id: 0,
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

        await repository.createTransaction(
          transaction,
          allowOverdraft: allowOverdraft.value,
        );

        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
        ref.invalidate(transactionsProvider);

        // Reset form
        amountController.clear();
        noteController.clear();
        selectedDate.value = DateTime.now();
        selectedCategoryId.value = null;
        receiptPath.value = null;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.success)),
          );
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
        title: Text(l10n.addTransaction),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                },
              ),
            ),
            const SizedBox(height: 24),

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
              prefixIcon: const Icon(Icons.attach_money),
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

            // Category Selector with Add button
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
                
                // Reset category selection if current selection is not in filtered list
                if (selectedCategoryId.value != null && 
                    !filteredCategories.any((c) => c.id == selectedCategoryId.value)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    selectedCategoryId.value = null;
                  });
                }
                
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
                            final result = await Navigator.pushNamed(context, '/category-edit');
                            if (result == true) {
                              ref.invalidate(categoriesProvider);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (filteredCategories.isEmpty)
                      Text(selectedType.value == model.TransactionType.expense 
                          ? l10n.noCategories 
                          : l10n.noCategories)
                    else
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId.value,
                        decoration: InputDecoration(
                          hintText: l10n.selectCategory,
                        ),
                        items: filteredCategories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              children: [
                                Text(category.iconName, style: const TextStyle(fontSize: 18)),
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

            // Date Picker with prev/next buttons
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
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
            const SizedBox(height: 16),

            // Note Input
            AppInput(
              label: l10n.note,
              hint: l10n.note,
              controller: noteController,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Receipt Attachment
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
            const SizedBox(height: 24),

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

