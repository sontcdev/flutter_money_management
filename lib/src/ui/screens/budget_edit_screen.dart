import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/vnd_input_formatter.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class BudgetEditScreen extends HookConsumerWidget {
  final Budget? budget;

  const BudgetEditScreen({super.key, this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    final limitController = useTextEditingController(
      text: budget != null
        ? CurrencyFormatter.formatInputVND((budget!.limitCents / 100).round().toString())
        : '',
    );
    final selectedCategoryId = useState<int?>(budget?.categoryId);
    final selectedPeriodType = useState<PeriodType>(budget?.periodType ?? PeriodType.monthly);
    final allowOverdraft = useState(budget?.allowOverdraft ?? false);
    final isLoading = useState(false);
    
    // Custom period dates
    final customStartDate = useState<DateTime>(budget?.periodStart ?? DateTime.now());
    final customEndDate = useState<DateTime>(budget?.periodEnd ?? DateTime.now().add(const Duration(days: 30)));
    
    // Selected transactions to include in budget
    final selectedTransactionIds = useState<Set<int>>({});
    final showTransactionSelector = useState(false);

    // Get transactions for selected category within period
    List<Transaction> getCategoryTransactions() {
      if (selectedCategoryId.value == null) return [];
      
      final transactions = transactionsAsync.valueOrNull ?? [];
      final now = DateTime.now();
      late DateTime periodStart;
      late DateTime periodEnd;

      switch (selectedPeriodType.value) {
        case PeriodType.monthly:
          periodStart = DateTime(now.year, now.month, 1);
          periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case PeriodType.yearly:
          periodStart = DateTime(now.year, 1, 1);
          periodEnd = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case PeriodType.custom:
          periodStart = customStartDate.value;
          periodEnd = DateTime(
            customEndDate.value.year,
            customEndDate.value.month,
            customEndDate.value.day,
            23, 59, 59,
          );
          break;
      }

      // Budget is always for expense transactions
      const txnType = TransactionType.expense;

      return transactions.where((t) =>
        t.categoryId == selectedCategoryId.value &&
        t.type == txnType &&
        t.dateTime.isAfter(periodStart.subtract(const Duration(seconds: 1))) &&
        t.dateTime.isBefore(periodEnd.add(const Duration(seconds: 1)))
      ).toList();
    }

    // Calculate total from selected transactions
    int getSelectedTotal() {
      final transactions = getCategoryTransactions();
      return transactions
          .where((t) => selectedTransactionIds.value.contains(t.id))
          .fold<int>(0, (sum, t) => sum + t.amountCents);
    }

    Future<void> handleSave() async {
      if (limitController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập hạn mức')),
        );
        return;
      }

      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn danh mục')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final budgetRepo = ref.read(budgetRepositoryProvider);
        final limit = CurrencyFormatter.parseVND(limitController.text);
        if (limit == null) {
          throw FormatException('Định dạng số tiền không hợp lệ');
        }
        final limitCents = CurrencyFormatter.toCents(limit);

        final now = DateTime.now();
        late DateTime periodStart;
        late DateTime periodEnd;

        switch (selectedPeriodType.value) {
          case PeriodType.monthly:
            periodStart = DateTime(now.year, now.month, 1);
            periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            break;
          case PeriodType.yearly:
            periodStart = DateTime(now.year, 1, 1);
            periodEnd = DateTime(now.year, 12, 31, 23, 59, 59);
            break;
          case PeriodType.custom:
            periodStart = customStartDate.value;
            periodEnd = DateTime(
              customEndDate.value.year,
              customEndDate.value.month,
              customEndDate.value.day,
              23, 59, 59,
            );
            break;
        }

        final newBudget = Budget(
          id: budget?.id ?? 0,
          categoryId: selectedCategoryId.value!,
          periodType: selectedPeriodType.value,
          periodStart: periodStart,
          periodEnd: periodEnd,
          limitCents: limitCents,
          consumedCents: budget?.consumedCents ?? 0,
          allowOverdraft: allowOverdraft.value,
          overdraftCents: budget?.overdraftCents ?? 0,
          createdAt: budget?.createdAt ?? now,
          updatedAt: now,
        );

        if (budget == null) {
          await budgetRepo.createBudget(newBudget);
        } else {
          await budgetRepo.updateBudget(newBudget);
        }

        // Invalidate both budgets and transactions providers to refresh all screens
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
        ref.invalidate(transactionsProvider);

        if (context.mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.success)),
          );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(budget == null ? 'Thêm Ngân Sách' : 'Sửa Ngân Sách'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh mục',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context, 
                      '/category-edit',
                      arguments: {'initialType': CategoryType.expense},
                    );
                    if (result == true) {
                      // Force refresh categories immediately
                      ref.invalidate(categoriesProvider);
                      // Trigger a new fetch
                      await ref.read(categoriesProvider.future);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                // Filter categories by expense type only (budgets are for expenses)
                final filteredCategories = categories.where((c) => 
                  c.type == CategoryType.expense
                ).toList();
                
                if (filteredCategories.isEmpty) {
                  return Card(
                    color: Colors.grey[100],
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Chưa có danh mục chi tiêu. Nhấn "Thêm" để tạo mới.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: selectedCategoryId.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Chọn danh mục',
                  ),
                  items: filteredCategories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Text(category.iconName, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategoryId.value = value;
                    selectedTransactionIds.value = {}; // Reset selected transactions
                    showTransactionSelector.value = false;
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Lỗi: $err'),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Hạn mức (VNĐ)',
              controller: limitController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                VNDInputFormatter(),
              ],
              hint: '0',
              suffixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chu kỳ',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PeriodOptionButton(
                    label: 'Tháng',
                    icon: Icons.calendar_month,
                    isSelected: selectedPeriodType.value == PeriodType.monthly,
                    onTap: () {
                      selectedPeriodType.value = PeriodType.monthly;
                      selectedTransactionIds.value = {};
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PeriodOptionButton(
                    label: 'Năm',
                    icon: Icons.calendar_today,
                    isSelected: selectedPeriodType.value == PeriodType.yearly,
                    onTap: () {
                      selectedPeriodType.value = PeriodType.yearly;
                      selectedTransactionIds.value = {};
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PeriodOptionButton(
                    label: 'Tùy chỉnh',
                    icon: Icons.date_range,
                    isSelected: selectedPeriodType.value == PeriodType.custom,
                    onTap: () {
                      selectedPeriodType.value = PeriodType.custom;
                      selectedTransactionIds.value = {};
                    },
                  ),
                ),
              ],
            ),
            
            // Custom date range picker
            if (selectedPeriodType.value == PeriodType.custom) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Từ ngày',
                      date: customStartDate.value,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: customStartDate.value,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          customStartDate.value = picked;
                          selectedTransactionIds.value = {};
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Đến ngày',
                      date: customEndDate.value,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: customEndDate.value,
                          firstDate: customStartDate.value,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          customEndDate.value = picked;
                          selectedTransactionIds.value = {};
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            // Transaction selector for new budgets
            if (budget == null && selectedCategoryId.value != null) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final categoryTransactions = getCategoryTransactions();
                  
                  if (categoryTransactions.isEmpty) {
                    return Card(
                      color: Colors.grey[100],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Không có giao dịch chi tiêu nào trong chu kỳ này.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final selectedTotal = getSelectedTotal();
                  final allSelected = selectedTransactionIds.value.length == categoryTransactions.length;
                  
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            'Giao dịch trong chu kỳ (${categoryTransactions.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: selectedTransactionIds.value.isNotEmpty
                              ? Text(
                                  'Đã chọn: ${CurrencyFormatter.formatVNDFromCents(selectedTotal)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const Text('Chọn giao dịch để tính vào ngân sách'),
                          trailing: IconButton(
                            icon: Icon(
                              showTransactionSelector.value 
                                  ? Icons.expand_less 
                                  : Icons.expand_more,
                            ),
                            onPressed: () {
                              showTransactionSelector.value = !showTransactionSelector.value;
                            },
                          ),
                        ),
                        
                        if (showTransactionSelector.value) ...[
                          const Divider(height: 1),
                          // Select all / Deselect all
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                TextButton.icon(
                                  icon: Icon(
                                    allSelected 
                                        ? Icons.check_box 
                                        : Icons.check_box_outline_blank,
                                  ),
                                  label: Text(allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả'),
                                  onPressed: () {
                                    if (allSelected) {
                                      selectedTransactionIds.value = {};
                                    } else {
                                      selectedTransactionIds.value = 
                                          categoryTransactions.map((t) => t.id).toSet();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Transaction list
                          ...categoryTransactions.map((t) {
                            final isSelected = selectedTransactionIds.value.contains(t.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                final newSet = Set<int>.from(selectedTransactionIds.value);
                                if (value == true) {
                                  newSet.add(t.id);
                                } else {
                                  newSet.remove(t.id);
                                }
                                selectedTransactionIds.value = newSet;
                              },
                              title: Text(
                                t.note ?? 'Không có ghi chú',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${t.dateTime.day}/${t.dateTime.month}/${t.dateTime.year}',
                              ),
                              secondary: Text(
                                CurrencyFormatter.formatVNDFromCents(t.amountCents),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              dense: true,
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Cho phép chi vượt'),
              subtitle: const Text('Không chặn khi vượt hạn mức'),
              value: allowOverdraft.value,
              onChanged: (value) => allowOverdraft.value = value,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: l10n.save,
              onPressed: handleSave,
              isLoading: isLoading.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey[100],
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

