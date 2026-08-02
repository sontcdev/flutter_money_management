import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_item.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_segmented_filter.dart';
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
    final canManageContent = ref.watch(canManageWorkspaceContentProvider);
    final selectedTab = useState(0); // 0: All, 1: Expense, 2: Income

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        actions: [
          if (canManageContent)
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
          AppSegmentedFilter<int>(
            options: [
              FilterOption(value: 0, label: l10n.all),
              FilterOption(
                value: 1,
                label: l10n.expense,
                color: AppColors.expense,
              ),
              FilterOption(
                value: 2,
                label: l10n.income,
                color: AppColors.income,
              ),
            ],
            selectedValue: selectedTab.value,
            onChanged: (value) => selectedTab.value = value,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
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
                            actionLabel:
                                canManageContent ? l10n.addCategory : null,
                            onAction: canManageContent
                                ? () async {
                                    final result = await Navigator.pushNamed(
                                        context, '/category-edit');
                                    if (result == true) {
                                      ref.invalidate(categoriesProvider);
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => syncCurrentWorkspaceData(ref),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      0,
                      AppSpacing.screenPadding,
                      AppSpacing.screenPadding,
                    ),
                    children: [
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0;
                                i < filteredCategories.length;
                                i++) ...[
                              CategoryItem(
                                category: filteredCategories[i],
                                onEdit: canManageContent
                                    ? () async {
                                        final result =
                                            await Navigator.pushNamed(
                                          context,
                                          '/category-edit',
                                          arguments: filteredCategories[i],
                                        );
                                        if (result == true) {
                                          ref.invalidate(categoriesProvider);
                                        }
                                      }
                                    : null,
                                onDelete: canManageContent
                                    ? () => _deleteCategory(
                                          context: context,
                                          ref: ref,
                                          l10n: l10n,
                                          category: filteredCategories[i],
                                        )
                                    : null,
                              ),
                              if (i != filteredCategories.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: AppSpacing.md,
                                  endIndent: AppSpacing.md,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.6),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
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

  Future<void> _deleteCategory({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required Category category,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
        await ref.read(categoryRepositoryProvider).deleteCategory(
              category.id,
            );
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
  }
}
