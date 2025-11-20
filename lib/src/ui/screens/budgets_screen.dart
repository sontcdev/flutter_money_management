// path: lib/src/ui/screens/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgets = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgets)),
      body: budgets.when(
        data: (budgetsList) {
          if (budgetsList.isEmpty) {
            return Center(
              child: Text(l10n.noBudgets),
            );
          }

          return ListView.builder(
            itemCount: budgetsList.length,
            itemBuilder: (context, index) {
              final budget = budgetsList[index];
              return ListTile(
                title: Text(budget.categoryId),
                subtitle: Text('${budget.consumedCents / 100} / ${budget.limitCents / 100}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/budget-detail',
                    arguments: budget.id,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add budget
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

