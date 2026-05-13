import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/providers/recurring_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class RecurringTransactionsScreen extends ConsumerStatefulWidget {
  const RecurringTransactionsScreen({
    super.key,
    this.highlightedOccurrenceId,
  });

  final String? highlightedOccurrenceId;

  @override
  ConsumerState<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends ConsumerState<RecurringTransactionsScreen> {
  bool _didOpenHighlightedOccurrence = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recurringAsync = ref.watch(recurringTransactionsProvider);
    final occurrencesAsync = ref.watch(upcomingRecurringOccurrencesProvider);
    final notificationsPermissionAsync =
        ref.watch(recurringNotificationsPermissionProvider);

    _maybeOpenHighlightedOccurrence(
      context: context,
      occurrencesAsync: occurrencesAsync,
      recurringAsync: recurringAsync,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringTransactions),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.pushNamed(
            context,
            '/recurring-transaction-edit',
          );
          if (created == true) {
            ref.invalidate(recurringTransactionsProvider);
            ref.invalidate(upcomingRecurringOccurrencesProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recurringTransactionsProvider);
          ref.invalidate(upcomingRecurringOccurrencesProvider);
          await Future.wait([
            ref.read(recurringTransactionsProvider.future),
            ref.read(upcomingRecurringOccurrencesProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            notificationsPermissionAsync.when(
              data: (enabled) => enabled
                  ? const SizedBox.shrink()
                  : _NotificationsPermissionCard(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if ((notificationsPermissionAsync.valueOrNull ?? true) == false)
              const SizedBox(height: AppSpacing.sectionGap),
            Text(
              l10n.recurringUpcoming,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            occurrencesAsync.when(
              data: (occurrences) => recurringAsync.when(
                data: (templates) {
                  if (occurrences.isEmpty) {
                    return _SectionPlaceholder(text: l10n.recurringNoUpcoming);
                  }
                  final templateById = {
                    for (final template in templates) template.id: template,
                  };
                  return Column(
                    children: occurrences.map((occurrence) {
                      final template =
                          templateById[occurrence.recurringTransactionId];
                      if (template == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _OccurrenceCard(
                          occurrence: occurrence,
                          recurringTransaction: template,
                          highlighted:
                              widget.highlightedOccurrenceId == occurrence.id,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(l10n.errorWithMessage('$error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(l10n.errorWithMessage('$error')),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              l10n.recurringTemplates,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            recurringAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _SectionPlaceholder(text: l10n.recurringNoTemplates);
                }
                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _RecurringTemplateCard(item: item),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(l10n.errorWithMessage('$error')),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeOpenHighlightedOccurrence({
    required BuildContext context,
    required AsyncValue<List<RecurringOccurrence>> occurrencesAsync,
    required AsyncValue<List<RecurringTransaction>> recurringAsync,
  }) {
    if (_didOpenHighlightedOccurrence ||
        widget.highlightedOccurrenceId == null) {
      return;
    }

    final occurrences = occurrencesAsync.valueOrNull;
    final recurringTransactions = recurringAsync.valueOrNull;
    if (occurrences == null || recurringTransactions == null) {
      return;
    }

    RecurringOccurrence? occurrence;
    for (final item in occurrences) {
      if (item.id == widget.highlightedOccurrenceId) {
        occurrence = item;
        break;
      }
    }
    if (occurrence == null) {
      return;
    }

    RecurringTransaction? recurringTransaction;
    for (final item in recurringTransactions) {
      if (item.id == occurrence.recurringTransactionId) {
        recurringTransaction = item;
        break;
      }
    }
    if (recurringTransaction == null) {
      return;
    }

    _didOpenHighlightedOccurrence = true;
    final selectedOccurrence = occurrence;
    final selectedRecurringTransaction = recurringTransaction;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showOccurrenceDetailSheet(
        context: context,
        ref: ref,
        occurrence: selectedOccurrence,
        recurringTransaction: selectedRecurringTransaction,
      );
    });
  }
}

class _OccurrenceCard extends ConsumerWidget {
  const _OccurrenceCard({
    required this.occurrence,
    required this.recurringTransaction,
    this.highlighted = false,
  });

  final RecurringOccurrence occurrence;
  final RecurringTransaction recurringTransaction;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      color:
          highlighted ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOccurrenceDetailSheet(
          context: context,
          ref: ref,
          occurrence: occurrence,
          recurringTransaction: recurringTransaction,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recurringTransaction.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                formatLocalizedDateWithWeekday(
                    context, occurrence.scheduledFor),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatVNDFromCents(
                  recurringTransaction.amountCents,
                  locale: l10n.localeName,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(_typeLabel(recurringTransaction, l10n))),
                  Chip(
                    label: Text(_modeLabel(recurringTransaction.mode, l10n)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tapForDetails,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(
    RecurringTransaction recurringTransaction,
    AppLocalizations l10n,
  ) {
    return recurringTransaction.isExpense ? l10n.expense : l10n.income;
  }

  String _modeLabel(RecurringMode mode, AppLocalizations l10n) {
    switch (mode) {
      case RecurringMode.manualConfirm:
        return l10n.recurringModeManualConfirm;
      case RecurringMode.reminderOnly:
        return l10n.recurringModeReminderOnly;
    }
  }
}

Future<void> _showOccurrenceDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required RecurringOccurrence occurrence,
  required RecurringTransaction recurringTransaction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _OccurrenceDetailSheet(
      occurrence: occurrence,
      recurringTransaction: recurringTransaction,
    ),
  );
}

class _OccurrenceDetailSheet extends ConsumerWidget {
  const _OccurrenceDetailSheet({
    required this.occurrence,
    required this.recurringTransaction,
  });

  final RecurringOccurrence occurrence;
  final RecurringTransaction recurringTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isBusy = ref.watch(recurringActionsProvider).isLoading;

    Future<void> confirm([bool allowOverdraft = false]) async {
      try {
        await ref.read(recurringActionsProvider.notifier).confirmOccurrence(
              occurrence: occurrence,
              recurringTransaction: recurringTransaction,
              allowOverdraft: allowOverdraft,
            );
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.success)),
        );
      } on BudgetExceededException catch (e) {
        if (!context.mounted) {
          return;
        }
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.budgetExceeded),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.proceed),
              ),
            ],
          ),
        );
        if (shouldProceed == true && context.mounted) {
          await confirm(true);
        }
      } catch (e, stackTrace) {
        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'recurring',
            action: 'confirm_occurrence',
            screen: 'recurring_transactions_screen',
            extraContext: {'occurrence_id': occurrence.id},
          );
        }
      }
    }

    Future<void> skip() async {
      try {
        await ref
            .read(recurringActionsProvider.notifier)
            .skipOccurrence(occurrence.id);
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.success)),
        );
      } catch (e, stackTrace) {
        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'recurring',
            action: 'skip_occurrence',
            screen: 'recurring_transactions_screen',
            extraContext: {'occurrence_id': occurrence.id},
          );
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recurringTransaction.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(formatLocalizedFullDate(context, occurrence.scheduledFor)),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.formatVNDFromCents(
                recurringTransaction.amountCents,
                locale: l10n.localeName,
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if ((recurringTransaction.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                recurringTransaction.note!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(
                      _frequencyLabel(recurringTransaction.frequency, l10n)),
                ),
                Chip(
                  avatar: Icon(
                    recurringTransaction.isExpense
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 18,
                  ),
                  label: Text(
                    recurringTransaction.isExpense ? l10n.expense : l10n.income,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : skip,
                    icon: const Icon(Icons.skip_next),
                    label: Text(l10n.skip),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : confirm,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.markDone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(
    RecurringFrequency frequency,
    AppLocalizations l10n,
  ) {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return l10n.weekly;
      case RecurringFrequency.monthly:
        return l10n.monthly;
      case RecurringFrequency.yearly:
        return l10n.yearly;
    }
  }
}

class _NotificationsPermissionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isBusy = ref.watch(recurringActionsProvider).isLoading;

    Future<void> requestPermission() async {
      final granted = await ref
          .read(recurringActionsProvider.notifier)
          .requestNotificationPermission();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? l10n.recurringNotificationsEnabled
                : l10n.recurringNotificationsDenied,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recurringNotificationsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.recurringNotificationsDesc),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : requestPermission,
              child: Text(l10n.recurringEnableNotifications),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringTemplateCard extends ConsumerWidget {
  const _RecurringTemplateCard({required this.item});

  final RecurringTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> delete() async {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.delete),
              content: Text(l10n.confirmDelete),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed || !context.mounted) {
        return;
      }

      try {
        await ref
            .read(recurringActionsProvider.notifier)
            .deleteRecurringTransaction(item.id);
        if (context.mounted) {
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
            feature: 'recurring',
            action: 'delete_recurring_transaction',
            screen: 'recurring_transactions_screen',
            extraContext: {'recurring_transaction_id': item.id},
          );
        }
      }
    }

    return Card(
      child: ListTile(
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_frequencyLabel(item.frequency, l10n)} • ${formatLocalizedDate(context, item.nextOccurrenceAt)}',
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(item.isExpense ? l10n.expense : l10n.income),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    item.isActive
                        ? l10n.recurringActive
                        : l10n.recurringInactive,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              final changed = await Navigator.pushNamed(
                context,
                '/recurring-transaction-edit',
                arguments: item.id,
              );
              if (changed == true) {
                ref.invalidate(recurringTransactionsProvider);
                ref.invalidate(upcomingRecurringOccurrencesProvider);
              }
              return;
            }
            if (value == 'delete') {
              await delete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(l10n.edit),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(l10n.delete),
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(RecurringFrequency frequency, AppLocalizations l10n) {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return l10n.weekly;
      case RecurringFrequency.monthly:
        return l10n.monthly;
      case RecurringFrequency.yearly:
        return l10n.yearly;
    }
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text),
      ),
    );
  }
}
