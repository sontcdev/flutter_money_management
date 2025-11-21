// path: lib/src/ui/screens/budget_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/budget.dart';
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

          final categories = ref.watch(categoriesProvider);
          
          return categories.when(
            data: (categoriesList) {
              final category = categoriesList.firstWhere(
                (c) => c.id == budget.categoryId,
                orElse: () => categoriesList.isNotEmpty ? categoriesList.first : throw Exception('Category not found'),
              );
              
              final budgetName = budget.name ?? 'Hũ chi tiêu';
              final categoryName = category.name;
              
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
                      value: categoryName,
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
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmDialog(
                          context,
                          ref,
                          budget,
                          budgetName,
                          categoryName,
                        ),
                        icon: const Icon(Icons.delete),
                        label: Text(l10n.delete),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading category: $error')),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
    String budgetName,
    String categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hũ chi tiêu'),
        content: Text(
          'Hũ "$budgetName" đang được gắn với danh mục "$categoryName".\n\n'
          'Nếu xóa, tất cả giao dịch sẽ không được tính lại trong hũ này.\n\n'
          'Bạn có chắc chắn muốn xóa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(budgetRepositoryProvider);
        await repo.deleteBudget(budget.id);
        if (context.mounted) {
          ref.invalidate(budgetsProvider);
          Navigator.of(context).pop(); // Quay lại màn hình danh sách
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa hũ chi tiêu thành công')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

