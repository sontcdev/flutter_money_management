import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/budget.dart';
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

    final limitController = useTextEditingController(
      text: budget != null
        ? CurrencyFormatter.formatInputVND((budget!.limitCents / 100).round().toString())
        : '',
    );
    final selectedCategoryId = useState<int?>(budget?.categoryId);
    final selectedPeriodType = useState<PeriodType>(
      budget?.periodType ?? PeriodType.monthly,
    );
    final allowOverdraft = useState(budget?.allowOverdraft ?? false);
    final isLoading = useState(false);

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
            periodStart = DateTime(now.year, now.month, 1);
            periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
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
            const Text(
              'Danh mục',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text('Chưa có danh mục');
                }

                return DropdownButtonFormField<int>(
                  value: selectedCategoryId.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Chọn danh mục',
                  ),
                  items: categories.map((category) {
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
                  onChanged: (value) => selectedCategoryId.value = value,
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
            DropdownButtonFormField<PeriodType>(
              value: selectedPeriodType.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: PeriodType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getPeriodTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedPeriodType.value = value;
                }
              },
            ),
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

  String _getPeriodTypeLabel(PeriodType type) {
    switch (type) {
      case PeriodType.monthly:
        return 'Hàng tháng';
      case PeriodType.yearly:
        return 'Hàng năm';
      case PeriodType.custom:
        return 'Tùy chỉnh';
    }
  }
}

