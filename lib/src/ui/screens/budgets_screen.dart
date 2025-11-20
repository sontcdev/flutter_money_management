// path: lib/src/ui/screens/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/ui/widgets/budget_progress.dart';
import 'package:flutter_money_management/src/app_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BudgetsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgets),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to add budget screen
            },
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(l10n.noBudgets),
                  Text(l10n.createFirst),
                ],
              ),
            );
          }

          return categoriesAsync.when(
            data: (categories) {
              final categoryMap = {for (final c in categories) c.id: c};

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  final category = categoryMap[budget.categoryId];

                  return BudgetProgress(
                    budget: budget,
                    categoryName: category?.name ?? 'Unknown',
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.budgetDetail,
                        arguments: budget.id,
                      );
                    },
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

