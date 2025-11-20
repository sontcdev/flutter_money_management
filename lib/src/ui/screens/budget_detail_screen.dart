// path: lib/src/ui/screens/budget_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/budget_progress.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final String budgetId;

  const BudgetDetailScreen({
    super.key,
    required this.budgetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(budgetRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetDetail)),
      body: FutureBuilder(
        future: repo.getBudgetById(budgetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Budget not found'));
          }

          final budget = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BudgetProgress(budget: budget),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: l10n.category,
                  value: budget.categoryId,
                ),
                _DetailRow(
                  label: l10n.period,
                  value: budget.periodType.name,
                ),
                _DetailRow(
                  label: 'Start',
                  value: budget.periodStart.toString(),
                ),
                _DetailRow(
                  label: 'End',
                  value: budget.periodEnd.toString(),
                ),
                _DetailRow(
                  label: l10n.limit,
                  value: '${budget.limitCents / 100}',
                ),
                _DetailRow(
                  label: l10n.consumed,
                  value: '${budget.consumedCents / 100}',
                ),
                _DetailRow(
                  label: l10n.remaining,
                  value: '${(budget.limitCents - budget.consumedCents) / 100}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

