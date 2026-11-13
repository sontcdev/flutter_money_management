import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_next_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_schedule_calculator.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/ui/widgets/unsaved_changes_guard.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';

class _FormSnapshot {
  const _FormSnapshot({
    required this.title,
    required this.amount,
    required this.note,
    required this.type,
    required this.frequency,
    required this.mode,
    required this.startDate,
    required this.endDate,
    required this.categoryId,
    required this.interval,
    required this.reminderDays,
    required this.dayOfMonth,
    required this.dayOfWeek,
    required this.monthOfYear,
    required this.isActive,
  });

  final String title;
  final num? amount;
  final String note;
  final RecurringTransactionType type;
  final RecurringFrequency frequency;
  final RecurringMode mode;
  final DateTime startDate;
  final DateTime? endDate;
  final String? categoryId;
  final int interval;
  final int reminderDays;
  final int? dayOfMonth;
  final int? dayOfWeek;
  final int? monthOfYear;
  final bool isActive;

  bool sameAs(_FormSnapshot other, String? initialCategoryId) {
    return title == other.title &&
        amount == other.amount &&
        note == other.note &&
        type == other.type &&
        frequency == other.frequency &&
        mode == other.mode &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        categoryId == initialCategoryId &&
        interval == other.interval &&
        reminderDays == other.reminderDays &&
        dayOfMonth == other.dayOfMonth &&
        dayOfWeek == other.dayOfWeek &&
        monthOfYear == other.monthOfYear &&
        isActive == other.isActive;
  }
}

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
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final guardController = useMemoized(() => UnsavedChangesController());
    useEffect(() => guardController.dispose, [guardController]);
    final amountFocus = useFocusNode();
    final intervalFocus = useFocusNode();
    final reminderFocus = useFocusNode();
    final noteFocus = useFocusNode();

    // Snapshot of the initial values, used for the dirty check.
    final initial = useMemoized(
      () => _FormSnapshot(
        title: titleController.text.trim(),
        amount: CurrencyFormatter.parseVND(amountController.text),
        note: noteController.text.trim(),
        type: selectedType.value,
        frequency: selectedFrequency.value,
        mode: selectedMode.value,
        startDate: RecurringScheduleCalculator.normalizeDate(
          selectedStartDate.value,
        ),
        endDate: selectedEndDate.value == null
            ? null
            : RecurringScheduleCalculator.normalizeDate(selectedEndDate.value!),
        categoryId: selectedCategoryId.value,
        interval: int.tryParse(intervalCountController.text) ?? 1,
        reminderDays: int.tryParse(reminderDaysController.text) ?? 0,
        dayOfMonth: dayOfMonth.value,
        dayOfWeek: dayOfWeek.value,
        monthOfYear: monthOfYear.value,
        isActive: isActive.value,
      ),
    );
    // Auto-selected default category of a new item is not a user edit.
    final initialCategory = useRef<String?>(initial.categoryId);

    useListenable(
      Listenable.merge([
        titleController,
        amountController,
        noteController,
        intervalCountController,
        reminderDaysController,
      ]),
    );

    final current = _FormSnapshot(
      title: titleController.text.trim(),
      amount: CurrencyFormatter.parseVND(amountController.text),
      note: noteController.text.trim(),
      type: selectedType.value,
      frequency: selectedFrequency.value,
      mode: selectedMode.value,
      startDate: RecurringScheduleCalculator.normalizeDate(
        selectedStartDate.value,
      ),
      endDate: selectedEndDate.value == null
          ? null
          : RecurringScheduleCalculator.normalizeDate(selectedEndDate.value!),
      categoryId: selectedCategoryId.value,
      interval: int.tryParse(intervalCountController.text) ?? 1,
      reminderDays: int.tryParse(reminderDaysController.text) ?? 0,
      dayOfMonth: dayOfMonth.value,
      dayOfWeek: dayOfWeek.value,
      monthOfYear: monthOfYear.value,
      isActive: isActive.value,
    );
    final isDirty = !current.sameAs(initial, initialCategory.value);

    final nextOccurrence = nextRecurringOccurrence(
      startDate: selectedStartDate.value,
      frequency: selectedFrequency.value,
      intervalCount: int.tryParse(intervalCountController.text) ?? 1,
      today: DateTime.now(),
      dayOfMonth: selectedFrequency.value == RecurringFrequency.monthly ||
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
    );

    Future<void> submit() async {
      if (formKey.currentState?.validate() != true) {
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

      final amount = CurrencyFormatter.parseVND(amountController.text)!;

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
          showAppSnackBar(context, l10n.success, type: AppSnackBarType.success);
          guardController.markSaved();
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

    return UnsavedChangesGuard(
      isDirty: isDirty,
      controller: guardController,
      child: Scaffold(
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
                if (existing == null && initialCategory.value == null) {
                  initialCategory.value = filteredCategories.first.id;
                }
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Form(
                key: formKey,
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
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? l10n.emptyContent
                          : null,
                      onFieldSubmitted: (_) => amountFocus.requestFocus(),
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
                      focusNode: amountFocus,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final parsed = CurrencyFormatter.parseVND(value ?? '');
                        return parsed == null || parsed <= 0
                            ? l10n.amountRequiredError
                            : null;
                      },
                      onFieldSubmitted: (_) => intervalFocus.requestFocus(),
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
                      focusNode: intervalFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => reminderFocus.requestFocus(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (selectedFrequency.value == RecurringFrequency.monthly ||
                        selectedFrequency.value == RecurringFrequency.yearly)
                      DropdownButtonFormField<int>(
                        initialValue: dayOfMonth.value,
                        decoration: InputDecoration(
                            labelText: l10n.recurringDayOfMonth),
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
                    if (selectedFrequency.value ==
                        RecurringFrequency.yearly) ...[
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
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        nextOccurrence == null
                            ? l10n.recurringNoUpcoming
                            : l10n.recurringNextOccurrence(
                                _formatDate(nextOccurrence),
                              ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<RecurringMode>(
                      initialValue: selectedMode.value,
                      decoration:
                          InputDecoration(labelText: l10n.recurringMode),
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
                      focusNode: reminderFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => noteFocus.requestFocus(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: l10n.note,
                      controller: noteController,
                      focusNode: noteFocus,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!isSaving.value) submit();
                      },
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
