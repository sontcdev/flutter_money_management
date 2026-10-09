import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

Future<bool?> showQuickInputReviewSheet(
  BuildContext context, {
  required List<VoiceParseResult> results,
  required List<Category> categories,
  required List<Wallet> wallets,
  required Future<bool> Function(VoiceParseResult) onSave,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => QuickInputReviewSheet(
      results: results,
      categories: categories,
      wallets: wallets,
      onSave: onSave,
    ),
  );
}

class QuickInputReviewSheet extends HookWidget {
  const QuickInputReviewSheet({
    super.key,
    required this.results,
    required this.categories,
    required this.wallets,
    required this.onSave,
  });

  final List<VoiceParseResult> results;
  final List<Category> categories;
  final List<Wallet> wallets;
  final Future<bool> Function(VoiceParseResult) onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = useState(List<VoiceParseResult>.of(results));
    final saving = useState(false);
    final failed = useState(false);

    bool isComplete(VoiceParseResult item) =>
        item.amountVnd != null &&
        item.amountVnd! > 0 &&
        categories.any((category) =>
            category.id == item.categoryId &&
            category.type.name == item.type?.name) &&
        wallets.any((wallet) => wallet.id == item.walletId);

    Future<void> saveAll() async {
      saving.value = true;
      failed.value = false;
      try {
        while (pending.value.isNotEmpty) {
          if (!await onSave(pending.value.first)) {
            if (context.mounted) failed.value = true;
            return;
          }
          if (!context.mounted) return;
          pending.value = pending.value.skip(1).toList();
        }
        if (context.mounted) Navigator.of(context).pop(true);
      } catch (_) {
        if (context.mounted) failed.value = true;
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    return PopScope(
      canPop: !saving.value,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.quickInputReview,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(l10n.quickInputReviewHint),
              for (var index = 0; index < pending.value.length; index++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(pending.value[index].note ??
                            pending.value[index].rawText),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            if (pending.value[index].amountVnd != null)
                              Text(CurrencyFormatter.formatVND(
                                  pending.value[index].amountVnd!)),
                            if (pending.value[index].date != null)
                              Text(formatLocalizedDate(
                                  context, pending.value[index].date!)),
                            if (pending.value[index].categoryName != null)
                              Text(pending.value[index].categoryName!),
                            if (pending.value[index].walletName != null)
                              Text(pending.value[index].walletName!),
                          ],
                        ),
                        if (pending.value[index].hasExtraAmounts)
                          Text(l10n.quickInputExtraAmounts,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        if (!isComplete(pending.value[index]))
                          Text(l10n.quickInputMissingFields,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            TextButton.icon(
                              onPressed: saving.value
                                  ? null
                                  : () async {
                                      final edited =
                                          await showDialog<VoiceParseResult>(
                                        context: context,
                                        builder: (context) =>
                                            _QuickInputEditDialog(
                                          item: pending.value[index],
                                          categories: categories,
                                          wallets: wallets,
                                        ),
                                      );
                                      if (edited != null && context.mounted) {
                                        final items = List<VoiceParseResult>.of(
                                            pending.value);
                                        items[index] = edited;
                                        pending.value = items;
                                      }
                                    },
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(l10n.edit),
                            ),
                            TextButton.icon(
                              onPressed: saving.value
                                  ? null
                                  : () {
                                      final items = List<VoiceParseResult>.of(
                                          pending.value);
                                      items.removeAt(index);
                                      pending.value = items;
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l10n.delete),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (failed.value)
                Text(l10n.quickInputSaveStopped,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: saving.value ||
                        pending.value.isEmpty ||
                        !pending.value.every(isComplete)
                    ? null
                    : saveAll,
                child: saving.value
                    ? const SizedBox(
                        width: AppSpacing.iconSize,
                        height: AppSpacing.iconSize,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.quickInputSaveAll),
              ),
              TextButton(
                onPressed: saving.value
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickInputEditDialog extends HookWidget {
  const _QuickInputEditDialog({
    required this.item,
    required this.categories,
    required this.wallets,
  });

  final VoiceParseResult item;
  final List<Category> categories;
  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final amount = useTextEditingController(
      text: item.amountVnd == null
          ? ''
          : CurrencyFormatter.formatInputVND(
              item.amountVnd!.round().toString()),
    );
    final note = useTextEditingController(text: item.note ?? item.rawText);
    final type = useState(item.type ?? TransactionType.expense);
    final categoryId = useState(item.categoryId);
    final walletId = useState(item.walletId);
    final date = useState(item.date ?? DateTime.now());
    final eligibleCategories = categories
        .where((category) => category.type.name == type.value.name)
        .toList();

    return AlertDialog(
      title: Text(l10n.edit),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [VNDInputFormatter()],
                decoration: InputDecoration(labelText: l10n.amount),
                validator: (value) =>
                    (CurrencyFormatter.parseVND(value ?? '') ?? 0) > 0
                        ? null
                        : l10n.amountRequiredError,
              ),
              DropdownButtonFormField<TransactionType>(
                initialValue: type.value,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                      value: TransactionType.expense,
                      child: Text(l10n.expense)),
                  DropdownMenuItem(
                      value: TransactionType.income, child: Text(l10n.income)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  type.value = value;
                  categoryId.value = null;
                },
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(type.value),
                initialValue: eligibleCategories
                        .any((category) => category.id == categoryId.value)
                    ? categoryId.value
                    : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.category),
                items: [
                  for (final category in eligibleCategories)
                    DropdownMenuItem(
                        value: category.id, child: Text(category.name))
                ],
                onChanged: (value) => categoryId.value = value,
                validator: (value) =>
                    value == null ? l10n.selectCategoryError : null,
              ),
              DropdownButtonFormField<String>(
                initialValue:
                    wallets.any((wallet) => wallet.id == walletId.value)
                        ? walletId.value
                        : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.walletName),
                items: [
                  for (final wallet in wallets)
                    DropdownMenuItem(value: wallet.id, child: Text(wallet.name))
                ],
                onChanged: (value) => walletId.value = value,
                validator: (value) =>
                    value == null ? l10n.walletRequired : null,
              ),
              TextFormField(
                controller: note,
                decoration: InputDecoration(labelText: l10n.note),
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(formatLocalizedDate(context, date.value)),
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: date.value,
                    firstDate: date.value.isBefore(DateTime(2000))
                        ? date.value
                        : DateTime(2000),
                    lastDate: date.value.isAfter(DateTime(2100))
                        ? date.value
                        : DateTime(2100),
                  );
                  if (selected != null && context.mounted) {
                    date.value = selected;
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final category = categories
                .firstWhere((category) => category.id == categoryId.value);
            final wallet =
                wallets.firstWhere((wallet) => wallet.id == walletId.value);
            Navigator.pop(
                context,
                VoiceParseResult(
                  rawText: item.rawText,
                  amountVnd: CurrencyFormatter.parseVND(amount.text),
                  date: date.value,
                  type: type.value,
                  categoryId: category.id,
                  categoryName: category.name,
                  walletId: wallet.id,
                  walletName: wallet.name,
                  note: note.text.trim(),
                ));
          },
          child: Text(l10n.voiceInputApply),
        ),
      ],
    );
  }
}
