import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_item.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';

class CategoriesScreen extends HookConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedTab = useState(0); // 0: All, 1: Expense, 2: Income

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, '/category-edit');
              if (result == true) {
                ref.invalidate(categoriesProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: l10n.all,
                    isSelected: selectedTab.value == 0,
                    onTap: () => selectedTab.value = 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: l10n.expense,
                    isSelected: selectedTab.value == 1,
                    onTap: () => selectedTab.value = 1,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: l10n.income,
                    isSelected: selectedTab.value == 2,
                    onTap: () => selectedTab.value = 2,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                // Filter categories based on selected tab
                List<Category> filteredCategories;
                if (selectedTab.value == 1) {
                  filteredCategories = categories
                      .where((c) => c.type == CategoryType.expense)
                      .toList();
                } else if (selectedTab.value == 2) {
                  filteredCategories = categories
                      .where((c) => c.type == CategoryType.income)
                      .toList();
                } else {
                  filteredCategories = categories;
                }

                if (filteredCategories.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => syncCurrentWorkspaceData(ref),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: EmptyState(
                            icon: Icons.category,
                            title: l10n.noCategories,
                            message: l10n.createFirst,
                            actionLabel: l10n.addCategory,
                            onAction: () async {
                              final result = await Navigator.pushNamed(
                                  context, '/category-edit');
                              if (result == true) {
                                ref.invalidate(categoriesProvider);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => syncCurrentWorkspaceData(ref),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return CategoryItem(
                        category: category,
                        onEdit: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/category-edit',
                            arguments: category,
                          );
                          if (result == true) {
                            ref.invalidate(categoriesProvider);
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.confirmDelete),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(l10n.no),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(l10n.yes),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await ref
                                  .read(categoryRepositoryProvider)
                                  .deleteCategory(category.id);
                              ref.invalidate(categoriesProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.success)),
                                );
                              }
                            } on CategoryInUseException {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.categoryInUse)),
                                );
                              }
                            } catch (e, stackTrace) {
                              if (context.mounted) {
                                await ErrorReportHelper.handleApiError(
                                  context: context,
                                  ref: ref,
                                  error: e,
                                  stackTrace: stackTrace,
                                  feature: 'category',
                                  action: 'delete_category',
                                  screen: 'categories_screen',
                                  extraContext: {
                                    'category_id': category.id,
                                  },
                                );
                              }
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => const ShimmerListItem(),
              ),
              error: (error, stack) =>
                  Center(child: Text(l10n.errorWithMessage('$error'))),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
