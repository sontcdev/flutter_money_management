// path: lib/src/ui/screens/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgets = ref.watch(budgetsProvider);
    final categories = ref.watch(categoriesProvider);
    final format = NumberFormat.currency(symbol: '₫', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgets)),
      body: budgets.when(
        data: (budgetsList) {
          if (budgetsList.isEmpty) {
            return Center(
              child: Text(l10n.noBudgets),
            );
          }

          return categories.when(
            data: (categoriesList) {
              return ListView.builder(
                itemCount: budgetsList.length,
                itemBuilder: (context, index) {
                  final budget = budgetsList[index];
                  // Tìm category để lấy tên
                  final category = categoriesList.firstWhere(
                    (c) => c.id == budget.categoryId,
                    orElse: () => categoriesList.first, // Fallback nếu không tìm thấy
                  );
                  
                  // Sử dụng tên hũ nếu có, nếu không thì dùng tên category
                  final displayName = budget.name?.isNotEmpty == true 
                      ? budget.name! 
                      : (category.id == budget.categoryId ? category.name : budget.categoryId);
                  
                  return ListTile(
                    title: Text(displayName),
                    subtitle: Text(
                      '${format.format(budget.consumedCents / 100)} / ${format.format(budget.limitCents / 100)}',
                    ),
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
            error: (error, stack) => Center(child: Text('Error loading categories: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-budget'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

