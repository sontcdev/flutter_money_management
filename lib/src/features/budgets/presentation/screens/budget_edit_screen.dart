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
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/confirm_delete_dialog.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

// Get transactions for selected category within period
List<Transaction> _getCategoryTransactions({
  required String? categoryId,
  required List<Transaction> transactions,
  required PeriodType periodType,
  required DateTime customStartDate,
  required DateTime customEndDate,
}) {
  if (categoryId == null) return [];

  final now = DateTime.now();
  late DateTime periodStart;
  late DateTime periodEnd;

  switch (periodType) {
    case PeriodType.monthly:
      periodStart = DateTime(now.year, now.month, 1);
      periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
    case PeriodType.yearly:
      periodStart = DateTime(now.year, 1, 1);
      periodEnd = DateTime(now.year, 12, 31, 23, 59, 59);
      break;
    case PeriodType.custom:
      periodStart = customStartDate;
      periodEnd = DateTime(
        customEndDate.year,
        customEndDate.month,
        customEndDate.day,
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
          t.categoryId == categoryId &&
          t.type == txnType &&
          t.dateTime
              .isAfter(periodStart.subtract(const Duration(seconds: 1))) &&
          t.dateTime.isBefore(periodEnd.add(const Duration(seconds: 1))))
      .toList();
}

class BudgetEditScreen extends HookConsumerWidget {
  final Budget? budget;

  const BudgetEditScreen({super.key, this.budget});

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref, {
    required AppLocalizations l10n,
    required AsyncValue<List<Category>> categoriesAsync,
    required ValueNotifier<bool> isLoading,
  }) async {
    final categoryName =
        categoriesAsync.valueOrNull
            ?.where((c) => c.id == budget!.categoryId)
            .firstOrNull
            ?.name ??
        l10n.unknown;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemName: categoryName,
      message: l10n.confirmDeleteBudget(categoryName),
      consequence: l10n.deleteCannotBeUndone,
    );

    if (!confirmed) return;

    isLoading.value = true;
    try {
      final budgetRepo = ref.read(budgetRepositoryProvider);
      await budgetRepo.deleteBudget(budget!.id);
      ref.invalidate(budgetsProvider);
      ref.invalidate(budgetsWithConsumedProvider);
      if (context.mounted) {
        Navigator.of(context).pop(true);
        showAppSnackBar(
          context,
          l10n.budgetDeleted,
          type: AppSnackBarType.success,
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

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref, {
    required AppLocalizations l10n,
    required TextEditingController limitController,
    required ValueNotifier<String?> selectedCategoryId,
    required ValueNotifier<PeriodType> selectedPeriodType,
    required ValueNotifier<bool> allowOverdraft,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<DateTime> customStartDate,
    required ValueNotifier<DateTime> customEndDate,
  }) async {
    if (limitController.text.isEmpty) {
      showAppSnackBar(
        context,
        l10n.limitRequiredError,
        type: AppSnackBarType.error,
      );
      return;
    }

    if (selectedCategoryId.value == null) {
      showAppSnackBar(
        context,
        l10n.selectCategoryError,
        type: AppSnackBarType.error,
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
        showAppSnackBar(context, l10n.success, type: AppSnackBarType.success);
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

    Future<void> handleDelete() => _handleDelete(
          context,
          ref,
          l10n: l10n,
          categoriesAsync: categoriesAsync,
          isLoading: isLoading,
        );

    Future<void> handleSave() => _handleSave(
          context,
          ref,
          l10n: l10n,
          limitController: limitController,
          selectedCategoryId: selectedCategoryId,
          selectedPeriodType: selectedPeriodType,
          allowOverdraft: allowOverdraft,
          isLoading: isLoading,
          customStartDate: customStartDate,
          customEndDate: customEndDate,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(budget == null ? l10n.addBudget : l10n.editBudget),
        leading: IconButton(
          tooltip: l10n.back,
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
            const _CategoryHeader(),
            const SizedBox(height: AppSpacing.sm),
            _CategoryDropdown(
              categoriesAsync: categoriesAsync,
              selectedCategoryId: selectedCategoryId,
              selectedTransactionIds: selectedTransactionIds,
              showTransactionSelector: showTransactionSelector,
            ),
            const SizedBox(height: AppSpacing.lg),
            _LimitInput(controller: limitController),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.period,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PeriodSelector(
              selectedPeriodType: selectedPeriodType,
              selectedTransactionIds: selectedTransactionIds,
            ),

            // Custom date range picker
            if (selectedPeriodType.value == PeriodType.custom) ...[
              const SizedBox(height: AppSpacing.lg),
              _CustomDateRange(
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                selectedTransactionIds: selectedTransactionIds,
              ),
            ],

            // Transaction selector for new budgets
            if (budget == null && selectedCategoryId.value != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _TransactionSelector(
                categoryTransactions: _getCategoryTransactions(
                  categoryId: selectedCategoryId.value,
                  transactions: transactionsAsync.valueOrNull ?? [],
                  periodType: selectedPeriodType.value,
                  customStartDate: customStartDate.value,
                  customEndDate: customEndDate.value,
                ),
                selectedTransactionIds: selectedTransactionIds,
                showTransactionSelector: showTransactionSelector,
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
                  icon: const Icon(Icons.delete_outline,
                      size: AppSpacing.iconSizeSm),
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

class _CategoryHeader extends ConsumerWidget {
  const _CategoryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
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
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _CategoryDropdown extends ConsumerWidget {
  final AsyncValue<List<Category>> categoriesAsync;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueNotifier<Set<String>> selectedTransactionIds;
  final ValueNotifier<bool> showTransactionSelector;

  const _CategoryDropdown({
    required this.categoriesAsync,
    required this.selectedCategoryId,
    required this.selectedTransactionIds,
    required this.showTransactionSelector,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return categoriesAsync.when(
      data: (categories) {
        final expenseCategories = categories
            .where((c) => c.type == CategoryType.expense)
            .toList();
        return DropdownButtonFormField<String>(
          key: ValueKey(selectedCategoryId.value),
          decoration: InputDecoration(
            labelText: l10n.category,
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusCard),
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
                      iconName: category.iconName,
                      size: AppSpacing.iconSizeSm),
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
      error: (err, stack) => InlineLoadErrorState(
        onRetry: () => ref.invalidate(categoriesProvider),
      ),
    );
  }
}

class _LimitInput extends StatelessWidget {
  final TextEditingController controller;

  const _LimitInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppInput(
      label: '${l10n.limit} (${l10n.currency})',
      controller: controller,
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final ValueNotifier<PeriodType> selectedPeriodType;
  final ValueNotifier<Set<String>> selectedTransactionIds;

  const _PeriodSelector({
    required this.selectedPeriodType,
    required this.selectedTransactionIds,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
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
    );
  }
}

class _CustomDateRange extends StatelessWidget {
  final ValueNotifier<DateTime> customStartDate;
  final ValueNotifier<DateTime> customEndDate;
  final ValueNotifier<Set<String>> selectedTransactionIds;

  const _CustomDateRange({
    required this.customStartDate,
    required this.customEndDate,
    required this.selectedTransactionIds,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
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
    );
  }
}

class _TransactionSelector extends StatelessWidget {
  final List<Transaction> categoryTransactions;
  final ValueNotifier<Set<String>> selectedTransactionIds;
  final ValueNotifier<bool> showTransactionSelector;

  const _TransactionSelector({
    required this.categoryTransactions,
    required this.selectedTransactionIds,
    required this.showTransactionSelector,
  });

  // Calculate total from selected transactions
  int _getSelectedTotal() {
    return categoryTransactions
        .where((t) => selectedTransactionIds.value.contains(t.id))
        .fold<int>(0, (sum, t) => sum + t.amountCents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (categoryTransactions.isEmpty) {
      final onSurfaceFaint = Theme.of(context)
          .colorScheme
          .onSurface
          .withValues(alpha: 0.6);
      return AppCard(
        color:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: onSurfaceFaint),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.noExpenseTransactionInPeriod,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: onSurfaceFaint),
              ),
            ),
          ],
        ),
      );
    }

    final selectedTotal = _getSelectedTotal();
    final allSelected = selectedTransactionIds.value.length ==
        categoryTransactions.length;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              '${l10n.transactionsInPeriod} (${categoryTransactions.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: selectedTransactionIds.value.isNotEmpty
                ? Text(
                    '${l10n.selected}: ${CurrencyFormatter.formatVNDFromCents(selectedTotal, locale: l10n.localeName)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                          fontWeight: FontWeight.w600,
                        ),
                  )
                : Text(l10n.selectTransactionsForBudget),
            trailing: IconButton(
              tooltip: showTransactionSelector.value
                  ? l10n.collapse
                  : l10n.expand,
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.semanticColors.expense,
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
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : unselectedForeground,
              size: AppSpacing.iconSizeXs,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : unselectedForeground,
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: AppSpacing.iconSizeXs,
                    color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatLocalizedDate(context, date),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
