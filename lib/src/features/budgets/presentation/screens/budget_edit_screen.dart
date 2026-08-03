import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

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
          ? CurrencyFormatter.formatInputVND(
              (budget!.limitCents / 100).round().toString())
          : '',
    );
    final selectedCategoryId = useState<String?>(budget?.categoryId);
    final selectedPeriodType =
        useState<PeriodType>(budget?.periodType ?? PeriodType.monthly);
    final allowOverdraft = useState(budget?.allowOverdraft ?? false);
    final isLoading = useState(false);

    // Custom period dates
    final customStartDate =
        useState<DateTime>(budget?.periodStart ?? DateTime.now());
    final customEndDate = useState<DateTime>(
        budget?.periodEnd ?? DateTime.now().add(const Duration(days: 30)));

    // Selected transactions to include in budget
    final selectedTransactionIds = useState<Set<String>>({});
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
            23,
            59,
            59,
          );
          break;
      }

      // Budget is always for expense transactions
      const txnType = TransactionType.expense;

      return transactions
          .where((t) =>
              t.categoryId == selectedCategoryId.value &&
              t.type == txnType &&
              t.dateTime
                  .isAfter(periodStart.subtract(const Duration(seconds: 1))) &&
              t.dateTime.isBefore(periodEnd.add(const Duration(seconds: 1))))
          .toList();
    }

    // Calculate total from selected transactions
    int getSelectedTotal() {
      final transactions = getCategoryTransactions();
      return transactions
          .where((t) => selectedTransactionIds.value.contains(t.id))
          .fold<int>(0, (sum, t) => sum + t.amountCents);
    }

    Future<void> handleDelete() async {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.notification),
              content: Text(l10n.confirmDeleteBudget(
                categoriesAsync.valueOrNull
                        ?.where((c) => c.id == budget!.categoryId)
                        .firstOrNull
                        ?.name ??
                    l10n.unknown,
              )),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;

      isLoading.value = true;
      try {
        final budgetRepo = ref.read(budgetRepositoryProvider);
        await budgetRepo.deleteBudget(budget!.id);
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithConsumedProvider);
        if (context.mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.budgetDeleted)),
          );
        }
      } catch (e, stackTrace) {
        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'budget',
            action: 'delete_budget',
            screen: 'budget_edit_screen',
            extraContext: {'budget_id': budget!.id},
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleSave() async {
      if (limitController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.limitRequiredError)),
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
        final budgetRepo = ref.read(budgetRepositoryProvider);
        final limit = CurrencyFormatter.parseVND(limitController.text);
        if (limit == null) {
          throw FormatException(l10n.error);
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
              23,
              59,
              59,
            );
            break;
        }

        final newBudget = Budget(
          id: budget?.id ?? '',
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
      } catch (e, stackTrace) {
        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'budget',
            action: budget == null ? 'create_budget' : 'update_budget',
            screen: 'budget_edit_screen',
            extraContext: {
              if (budget != null) 'budget_id': budget!.id,
              'category_id': selectedCategoryId.value!,
              'period_type': selectedPeriodType.value.toString(),
              'allow_overdraft': allowOverdraft.value,
            },
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(budget == null ? l10n.addBudget : l10n.editBudget),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Unfocus to hide keyboard before popping
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.category,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
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
                      ref.invalidate(categoriesForWorkspaceProvider);
                      // Trigger a new fetch
                      await ref.read(categoriesProvider.future);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.add),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              data: (categories) {
                final expenseCategories = categories
                    .where((c) => c.type == CategoryType.expense)
                    .toList();
                return DropdownButtonFormField<String>(
                  key: ValueKey(selectedCategoryId.value),
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  initialValue: selectedCategoryId.value,
                  items: expenseCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        children: [
                          CategoryIconWidget(
                              iconName: category.iconName, size: 20),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategoryId.value = value;
                    selectedTransactionIds.value =
                        {}; // Reset selected transactions
                    showTransactionSelector.value = false;
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text(l10n.errorWithMessage('$err')),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppInput(
              label: '${l10n.limit} (${l10n.currency})',
              controller: limitController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                VNDInputFormatter(),
              ],
              hint: '0',
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                child: Text(
                  CurrencyFormatter.getCurrencySymbol('VND'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.period,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _PeriodOptionButton(
                    label: l10n.monthly,
                    icon: Icons.calendar_month,
                    isSelected: selectedPeriodType.value == PeriodType.monthly,
                    onTap: () {
                      selectedPeriodType.value = PeriodType.monthly;
                      selectedTransactionIds.value = {};
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PeriodOptionButton(
                    label: l10n.yearly,
                    icon: Icons.calendar_today,
                    isSelected: selectedPeriodType.value == PeriodType.yearly,
                    onTap: () {
                      selectedPeriodType.value = PeriodType.yearly;
                      selectedTransactionIds.value = {};
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PeriodOptionButton(
                    label: l10n.custom,
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
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: l10n.fromDate,
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DatePickerField(
                      label: l10n.toDate,
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
              const SizedBox(height: AppSpacing.lg),
              Builder(
                builder: (context) {
                  final categoryTransactions = getCategoryTransactions();

                  if (categoryTransactions.isEmpty) {
                    final onSurfaceFaint = Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6);
                    return Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: onSurfaceFaint),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                l10n.noExpenseTransactionInPeriod,
                                style: TextStyle(color: onSurfaceFaint),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final selectedTotal = getSelectedTotal();
                  final allSelected = selectedTransactionIds.value.length ==
                      categoryTransactions.length;

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            '${l10n.transactionsInPeriod} (${categoryTransactions.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: selectedTransactionIds.value.isNotEmpty
                              ? Text(
                                  '${l10n.selected}: ${CurrencyFormatter.formatVNDFromCents(selectedTotal, locale: l10n.localeName)}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Text(l10n.selectTransactionsForBudget),
                          trailing: IconButton(
                            icon: Icon(
                              showTransactionSelector.value
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onPressed: () {
                              showTransactionSelector.value =
                                  !showTransactionSelector.value;
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
                                  label: Text(allSelected
                                      ? l10n.deselectAll
                                      : l10n.selectAll),
                                  onPressed: () {
                                    if (allSelected) {
                                      selectedTransactionIds.value = {};
                                    } else {
                                      selectedTransactionIds.value =
                                          categoryTransactions
                                              .map((t) => t.id)
                                              .toSet();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Transaction list
                          ...categoryTransactions.map((t) {
                            final isSelected =
                                selectedTransactionIds.value.contains(t.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                final newSet = Set<String>.from(
                                    selectedTransactionIds.value);
                                if (value == true) {
                                  newSet.add(t.id);
                                } else {
                                  newSet.remove(t.id);
                                }
                                selectedTransactionIds.value = newSet;
                              },
                              title: Text(
                                t.note ?? l10n.noNote,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                formatLocalizedDate(context, t.dateTime),
                              ),
                              secondary: Text(
                                CurrencyFormatter.formatVNDFromCents(
                                  t.amountCents,
                                  locale: l10n.localeName,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.expense,
                                ),
                              ),
                              dense: true,
                            );
                          }),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              title: Text(l10n.allowOverdraft),
              subtitle: Text(l10n.allowOverdraftDesc),
              value: allowOverdraft.value,
              onChanged: (value) => allowOverdraft.value = value,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              text: l10n.save,
              onPressed: handleSave,
              isLoading: isLoading.value,
            ),
            if (budget != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading.value ? null : handleDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.delete_outline, size: AppSpacing.iconSizeSm),
                  label: Text(l10n.deleteBudget),
                ),
              ),
            ],
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
    final theme = Theme.of(context);
    final unselectedForeground =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : unselectedForeground,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : unselectedForeground,
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatLocalizedDate(context, date),
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
