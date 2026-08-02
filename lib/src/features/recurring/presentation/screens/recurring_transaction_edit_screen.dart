import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';

class RecurringTransactionEditScreen extends HookConsumerWidget {
  const RecurringTransactionEditScreen({
    super.key,
    this.recurringTransactionId,
  });

  final String? recurringTransactionId;

  bool get isEditing => recurringTransactionId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final recurringAsync = recurringTransactionId == null
        ? const AsyncValue<RecurringTransaction?>.data(null)
        : ref.watch(recurringTransactionProvider(recurringTransactionId!));

    return recurringAsync.when(
      data: (existing) => _RecurringTransactionEditForm(
        recurringTransactionId: recurringTransactionId,
        existing: existing,
        categoriesAsync: categoriesAsync,
        isEditing: isEditing,
        l10n: l10n,
      ),
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? l10n.edit : l10n.add),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? l10n.edit : l10n.add),
        ),
        body: Center(child: Text(l10n.errorWithMessage('$error'))),
      ),
    );
  }
}

class _RecurringTransactionEditForm extends HookConsumerWidget {
  const _RecurringTransactionEditForm({
    required this.recurringTransactionId,
    required this.existing,
    required this.categoriesAsync,
    required this.isEditing,
    required this.l10n,
  });

  final String? recurringTransactionId;
  final RecurringTransaction? existing;
  final AsyncValue<List<Category>> categoriesAsync;
  final bool isEditing;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController =
        useTextEditingController(text: existing?.title ?? '');
    final amountController = useTextEditingController(
      text: existing == null
          ? ''
          : CurrencyFormatter.formatInputVND(
              ((existing!.amountCents / 100).round()).toString(),
            ),
    );
    final noteController = useTextEditingController(text: existing?.note ?? '');
    final selectedType = useState(
      existing?.type ?? RecurringTransactionType.expense,
    );
    final selectedFrequency = useState(
      existing?.frequency ?? RecurringFrequency.monthly,
    );
    final selectedMode = useState(
      existing?.mode ?? RecurringMode.manualConfirm,
    );
    final selectedStartDate = useState(
      existing?.startDate ?? DateTime.now(),
    );
    final selectedEndDate = useState<DateTime?>(existing?.endDate);
    final selectedCategoryId = useState<String?>(existing?.categoryId);
    final intervalCountController = useTextEditingController(
      text: (existing?.intervalCount ?? 1).toString(),
    );
    final reminderDaysController = useTextEditingController(
      text: (existing?.reminderDaysBefore ?? 0).toString(),
    );
    final dayOfMonth =
        useState<int?>(existing?.dayOfMonth ?? DateTime.now().day);
    final dayOfWeek =
        useState<int?>(existing?.dayOfWeek ?? DateTime.now().weekday);
    final monthOfYear =
        useState<int?>(existing?.monthOfYear ?? DateTime.now().month);
    final isActive = useState(existing?.isActive ?? true);
    final isSaving = useState(false);

    Future<void> submit() async {
      if (titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.emptyContent)),
        );
        return;
      }
      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.selectCategory)),
        );
        return;
      }

      final amount = CurrencyFormatter.parseVND(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.amountRequiredError)),
        );
        return;
      }

      final intervalCount = int.tryParse(intervalCountController.text) ?? 1;
      final reminderDays = int.tryParse(reminderDaysController.text) ?? 0;

      isSaving.value = true;
      try {
        await ref
            .read(recurringTransactionServiceProvider)
            .saveRecurringTransaction(
              existingId: recurringTransactionId,
              title: titleController.text,
              categoryId: selectedCategoryId.value!,
              amountCents: CurrencyFormatter.toCents(amount),
              type: selectedType.value,
              frequency: selectedFrequency.value,
              mode: selectedMode.value,
              intervalCount: intervalCount,
              startDate: selectedStartDate.value,
              reminderDaysBefore: reminderDays,
              note: noteController.text,
              dayOfMonth:
                  selectedFrequency.value == RecurringFrequency.monthly ||
                          selectedFrequency.value == RecurringFrequency.yearly
                      ? dayOfMonth.value
                      : null,
              dayOfWeek: selectedFrequency.value == RecurringFrequency.weekly
                  ? dayOfWeek.value
                  : null,
              monthOfYear: selectedFrequency.value == RecurringFrequency.yearly
                  ? monthOfYear.value
                  : null,
              endDate: selectedEndDate.value,
              isActive: isActive.value,
            );
        ref.invalidate(recurringTransactionsProvider);
        ref.invalidate(upcomingRecurringOccurrencesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.success)),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e, stackTrace) {
        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'recurring',
            action: isEditing
                ? 'update_recurring_transaction'
                : 'create_recurring_transaction',
            screen: 'recurring_transaction_edit_screen',
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.recurringEditTitle : l10n.recurringAddTitle,
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final filteredCategories = categories.where((category) {
            return selectedType.value == RecurringTransactionType.expense
                ? category.type == CategoryType.expense
                : category.type == CategoryType.income;
          }).toList();

          if (selectedCategoryId.value == null &&
              filteredCategories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              selectedCategoryId.value = filteredCategories.first.id;
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          selectedMode.value == RecurringMode.manualConfirm
                              ? l10n.recurringModeManualConfirm
                              : l10n.recurringModeReminderOnly,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInput(
                  label: l10n.recurringTitle,
                  controller: titleController,
                ),
                const SizedBox(height: AppSpacing.lg),
                SegmentedButton<RecurringTransactionType>(
                  segments: [
                    ButtonSegment(
                      value: RecurringTransactionType.expense,
                      label: Text(l10n.expense),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: RecurringTransactionType.income,
                      label: Text(l10n.income),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {selectedType.value},
                  onSelectionChanged: (selection) {
                    selectedType.value = selection.first;
                    selectedCategoryId.value = null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInput(
                  label: l10n.amount,
                  hint: '0',
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    VNDInputFormatter(),
                  ],
                  suffixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                      vertical: AppSpacing.screenPadding,
                    ),
                    child: Text(CurrencyFormatter.getCurrencySymbol('VND')),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategoryId.value,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: filteredCategories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => selectedCategoryId.value = value,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<RecurringFrequency>(
                  initialValue: selectedFrequency.value,
                  decoration:
                      InputDecoration(labelText: l10n.recurringFrequency),
                  items: [
                    DropdownMenuItem(
                      value: RecurringFrequency.weekly,
                      child: Text(l10n.weekly),
                    ),
                    DropdownMenuItem(
                      value: RecurringFrequency.monthly,
                      child: Text(l10n.monthly),
                    ),
                    DropdownMenuItem(
                      value: RecurringFrequency.yearly,
                      child: Text(l10n.yearly),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedFrequency.value = value;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInput(
                  label: l10n.recurringInterval,
                  controller: intervalCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selectedFrequency.value == RecurringFrequency.monthly ||
                    selectedFrequency.value == RecurringFrequency.yearly)
                  DropdownButtonFormField<int>(
                    initialValue: dayOfMonth.value,
                    decoration:
                        InputDecoration(labelText: l10n.recurringDayOfMonth),
                    items: List.generate(
                      31,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) => dayOfMonth.value = value,
                  ),
                if (selectedFrequency.value == RecurringFrequency.weekly)
                  DropdownButtonFormField<int>(
                    initialValue: dayOfWeek.value,
                    decoration:
                        InputDecoration(labelText: l10n.recurringDayOfWeek),
                    items: List.generate(
                      7,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(_weekdayLabel(index + 1, l10n)),
                      ),
                    ),
                    onChanged: (value) => dayOfWeek.value = value,
                  ),
                if (selectedFrequency.value == RecurringFrequency.yearly) ...[
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<int>(
                    initialValue: monthOfYear.value,
                    decoration: InputDecoration(labelText: l10n.month),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) => monthOfYear.value = value,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.startDate),
                  subtitle: Text(_formatDate(selectedStartDate.value)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      selectedStartDate.value = picked;
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.recurringEndDate),
                  subtitle: Text(
                    selectedEndDate.value == null
                        ? l10n.recurringNoEndDate
                        : _formatDate(selectedEndDate.value!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedEndDate.value != null)
                        IconButton(
                          onPressed: () => selectedEndDate.value = null,
                          icon: const Icon(Icons.clear),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          selectedEndDate.value ?? selectedStartDate.value,
                      firstDate: selectedStartDate.value,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      selectedEndDate.value = picked;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<RecurringMode>(
                  initialValue: selectedMode.value,
                  decoration: InputDecoration(labelText: l10n.recurringMode),
                  items: [
                    DropdownMenuItem(
                      value: RecurringMode.manualConfirm,
                      child: Text(l10n.recurringModeManualConfirm),
                    ),
                    DropdownMenuItem(
                      value: RecurringMode.reminderOnly,
                      child: Text(l10n.recurringModeReminderOnly),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedMode.value = value;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInput(
                  label: l10n.recurringReminderDaysBefore,
                  controller: reminderDaysController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInput(
                  label: l10n.note,
                  controller: noteController,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.recurringActive),
                  value: isActive.value,
                  onChanged: (value) => isActive.value = value,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: l10n.save,
                  onPressed: isSaving.value ? null : submit,
                  isLoading: isSaving.value,
                  fullWidth: true,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.errorWithMessage('$error'))),
      ),
    );
  }

  String _weekdayLabel(int weekday, AppLocalizations l10n) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.monday;
      case DateTime.tuesday:
        return l10n.tuesday;
      case DateTime.wednesday:
        return l10n.wednesday;
      case DateTime.thursday:
        return l10n.thursday;
      case DateTime.friday:
        return l10n.friday;
      case DateTime.saturday:
        return l10n.saturday;
      default:
        return l10n.sunday;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
