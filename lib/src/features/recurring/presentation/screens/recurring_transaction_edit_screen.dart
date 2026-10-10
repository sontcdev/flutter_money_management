import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_schedule_calculator.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
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
        body: LoadErrorState(
          title: l10n.dataLoadFailed,
          message: l10n.dataLoadFailedHint,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(
            recurringTransactionProvider(recurringTransactionId!),
          ),
        ),
      ),
    );
  }
}

class _RecurringFormState {
  const _RecurringFormState({
    required this.titleController,
    required this.amountController,
    required this.noteController,
    required this.intervalCountController,
    required this.reminderDaysController,
    required this.selectedType,
    required this.selectedFrequency,
    required this.selectedMode,
    required this.selectedStartDate,
    required this.selectedEndDate,
    required this.selectedCategoryId,
    required this.dayOfMonth,
    required this.dayOfWeek,
    required this.monthOfYear,
    required this.isActive,
    required this.isSaving,
  });

  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final TextEditingController intervalCountController;
  final TextEditingController reminderDaysController;
  final ValueNotifier<RecurringTransactionType> selectedType;
  final ValueNotifier<RecurringFrequency> selectedFrequency;
  final ValueNotifier<RecurringMode> selectedMode;
  final ValueNotifier<DateTime> selectedStartDate;
  final ValueNotifier<DateTime?> selectedEndDate;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueNotifier<int?> dayOfMonth;
  final ValueNotifier<int?> dayOfWeek;
  final ValueNotifier<int?> monthOfYear;
  final ValueNotifier<bool> isActive;
  final ValueNotifier<bool> isSaving;
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
    final intervalText = useValueListenable(intervalCountController).text;
    final previewDates = previewRecurringOccurrences(
      startDate: selectedStartDate.value,
      endDate: selectedEndDate.value,
      frequency: selectedFrequency.value,
      intervalCount: int.tryParse(intervalText) ?? 1,
      dayOfMonth: dayOfMonth.value,
      dayOfWeek: dayOfWeek.value,
      monthOfYear: monthOfYear.value,
    );
    final form = _RecurringFormState(
      titleController: titleController,
      amountController: amountController,
      noteController: noteController,
      intervalCountController: intervalCountController,
      reminderDaysController: reminderDaysController,
      selectedType: selectedType,
      selectedFrequency: selectedFrequency,
      selectedMode: selectedMode,
      selectedStartDate: selectedStartDate,
      selectedEndDate: selectedEndDate,
      selectedCategoryId: selectedCategoryId,
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      monthOfYear: monthOfYear,
      isActive: isActive,
      isSaving: isSaving,
    );

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
                _RecurringModeBanner(
                  mode: selectedMode.value,
                  l10n: l10n,
                ),
                const SizedBox(height: AppSpacing.lg),
                _RecurringBasicFields(
                  form: form,
                  filteredCategories: filteredCategories,
                  l10n: l10n,
                ),
                const SizedBox(height: AppSpacing.lg),
                _RecurringScheduleFields(form: form, l10n: l10n),
                const SizedBox(height: AppSpacing.lg),
                _RecurringDateFields(form: form, l10n: l10n),
                if (previewDates.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _RecurringOccurrencePreview(
                    dates: previewDates,
                    l10n: l10n,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _RecurringReminderFields(
                  form: form,
                  l10n: l10n,
                  onSave: () => _submit(context, ref, form),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LoadErrorState(
          title: l10n.dataLoadFailed,
          message: l10n.dataLoadFailedHint,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    _RecurringFormState form,
  ) async {
    final titleController = form.titleController;
    final selectedCategoryId = form.selectedCategoryId;
    final selectedFrequency = form.selectedFrequency;
    final isSaving = form.isSaving;
    if (titleController.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        l10n.emptyContent,
        type: AppSnackBarType.error,
      );
      return;
    }
    if (selectedCategoryId.value == null) {
      showAppSnackBar(
        context,
        l10n.selectCategory,
        type: AppSnackBarType.error,
      );
      return;
    }

    final amount = CurrencyFormatter.parseVND(form.amountController.text);
    if (amount == null || amount <= 0) {
      showAppSnackBar(
        context,
        l10n.amountRequiredError,
        type: AppSnackBarType.error,
      );
      return;
    }

    final intervalCount = int.tryParse(form.intervalCountController.text) ?? 1;
    final reminderDays = int.tryParse(form.reminderDaysController.text) ?? 0;

    isSaving.value = true;
    try {
      await ref
          .read(recurringTransactionServiceProvider)
          .saveRecurringTransaction(
            existingId: recurringTransactionId,
            title: titleController.text,
            categoryId: selectedCategoryId.value!,
            amountCents: CurrencyFormatter.toCents(amount),
            type: form.selectedType.value,
            frequency: selectedFrequency.value,
            mode: form.selectedMode.value,
            intervalCount: intervalCount,
            startDate: form.selectedStartDate.value,
            reminderDaysBefore: reminderDays,
            note: form.noteController.text,
            dayOfMonth: selectedFrequency.value == RecurringFrequency.monthly ||
                    selectedFrequency.value == RecurringFrequency.yearly
                ? form.dayOfMonth.value
                : null,
            dayOfWeek: selectedFrequency.value == RecurringFrequency.weekly
                ? form.dayOfWeek.value
                : null,
            monthOfYear: selectedFrequency.value == RecurringFrequency.yearly
                ? form.monthOfYear.value
                : null,
            endDate: form.selectedEndDate.value,
            isActive: form.isActive.value,
          );
      ref.invalidate(recurringTransactionsProvider);
      ref.invalidate(upcomingRecurringOccurrencesProvider);
      if (context.mounted) {
        showAppSnackBar(context, l10n.success, type: AppSnackBarType.success);
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
}

class _RecurringModeBanner extends StatelessWidget {
  const _RecurringModeBanner({required this.mode, required this.l10n});

  final RecurringMode mode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
              mode == RecurringMode.manualConfirm
                  ? l10n.recurringModeManualConfirm
                  : l10n.recurringModeReminderOnly,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringBasicFields extends StatelessWidget {
  const _RecurringBasicFields({
    required this.form,
    required this.filteredCategories,
    required this.l10n,
  });

  final _RecurringFormState form;
  final List<Category> filteredCategories;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final selectedType = form.selectedType;
    final selectedCategoryId = form.selectedCategoryId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          label: l10n.recurringTitle,
          controller: form.titleController,
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
          controller: form.amountController,
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
      ],
    );
  }
}

class _RecurringScheduleFields extends StatelessWidget {
  const _RecurringScheduleFields({required this.form, required this.l10n});

  final _RecurringFormState form;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final selectedFrequency = form.selectedFrequency;
    final dayOfMonth = form.dayOfMonth;
    final dayOfWeek = form.dayOfWeek;
    final monthOfYear = form.monthOfYear;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<RecurringFrequency>(
          initialValue: selectedFrequency.value,
          decoration: InputDecoration(labelText: l10n.recurringFrequency),
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
          controller: form.intervalCountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (selectedFrequency.value == RecurringFrequency.monthly ||
            selectedFrequency.value == RecurringFrequency.yearly)
          DropdownButtonFormField<int>(
            initialValue: dayOfMonth.value,
            decoration: InputDecoration(labelText: l10n.recurringDayOfMonth),
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
            decoration: InputDecoration(labelText: l10n.recurringDayOfWeek),
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
      ],
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
}

class _RecurringDateFields extends StatelessWidget {
  const _RecurringDateFields({required this.form, required this.l10n});

  final _RecurringFormState form;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final selectedStartDate = form.selectedStartDate;
    final selectedEndDate = form.selectedEndDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  tooltip: l10n.clear,
                  onPressed: () => selectedEndDate.value = null,
                  icon: const Icon(Icons.clear),
                ),
              const Icon(Icons.calendar_today),
            ],
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedEndDate.value ?? selectedStartDate.value,
              firstDate: selectedStartDate.value,
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              selectedEndDate.value = picked;
            }
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RecurringOccurrencePreview extends StatelessWidget {
  const _RecurringOccurrencePreview({required this.dates, required this.l10n});

  final List<DateTime> dates;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.recurringNextOccurrences,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final date in dates)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: AppSpacing.iconSizeXs,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(formatLocalizedDateWithWeekday(context, date)),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecurringReminderFields extends StatelessWidget {
  const _RecurringReminderFields({
    required this.form,
    required this.l10n,
    required this.onSave,
  });

  final _RecurringFormState form;
  final AppLocalizations l10n;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final selectedMode = form.selectedMode;
    final isActive = form.isActive;
    final isSaving = form.isSaving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          controller: form.reminderDaysController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: l10n.note,
          controller: form.noteController,
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
          onPressed: isSaving.value ? null : onSave,
          isLoading: isSaving.value,
          fullWidth: true,
        ),
      ],
    );
  }
}

List<DateTime> previewRecurringOccurrences({
  required DateTime startDate,
  required RecurringFrequency frequency,
  required int intervalCount,
  DateTime? endDate,
  int? dayOfMonth,
  int? dayOfWeek,
  int? monthOfYear,
  int count = 3,
}) {
  final interval = intervalCount < 1 ? 1 : intervalCount;
  final usesDayOfMonth = frequency != RecurringFrequency.weekly;
  final resolvedDayOfMonth = usesDayOfMonth ? dayOfMonth : null;
  final resolvedDayOfWeek =
      frequency == RecurringFrequency.weekly ? dayOfWeek : null;
  final resolvedMonthOfYear =
      frequency == RecurringFrequency.yearly ? monthOfYear : null;
  final lastDate = endDate == null
      ? null
      : RecurringScheduleCalculator.normalizeDate(endDate);
  final dates = <DateTime>[];
  var current = RecurringScheduleCalculator.calculateFirstOccurrence(
    startDate: startDate,
    frequency: frequency,
    intervalCount: interval,
    dayOfMonth: resolvedDayOfMonth,
    dayOfWeek: resolvedDayOfWeek,
    monthOfYear: resolvedMonthOfYear,
  );
  while (dates.length < count &&
      (lastDate == null || !current.isAfter(lastDate))) {
    dates.add(current);
    current = RecurringScheduleCalculator.addInterval(
      current: current,
      frequency: frequency,
      intervalCount: interval,
      dayOfMonth: resolvedDayOfMonth,
      monthOfYear: resolvedMonthOfYear,
    );
  }
  return dates;
}
