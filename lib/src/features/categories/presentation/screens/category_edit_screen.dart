import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart'
    as budget_model;
import 'package:flutter_money_management/src/features/categories/providers/custom_icons_provider.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';
import 'package:flutter/services.dart';

class CategoryEditScreen extends HookConsumerWidget {
  final Category? category;
  final CategoryType? initialType;
  final String? workspaceId;

  const CategoryEditScreen({
    super.key,
    this.category,
    this.initialType,
    this.workspaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController(text: category?.name ?? '');
    final selectedIcon = useState(category?.iconName ?? 'shopping_cart');
    final selectedColor =
        useState(category?.colorValue ?? 0xFF9E9E9E); // Default light gray
    final selectedType =
        useState(category?.type ?? initialType ?? CategoryType.expense);
    final isLoading = useState(false);
    final showAllIcons = useState(false);
    final createBudget = useState(false);
    final budgetAmountController = useTextEditingController();
    final budgetPeriod = useState(budget_model.PeriodType.monthly);
    final monthStartDay = ref.watch(monthStartDayProvider);

    // Get custom icons from provider
    final customIcons = ref.watch(customIconsProvider);

    // Combine custom icons with default icons
    final List<String> allAvailableIcons = [
      ...customIcons, // Custom icons first
      ...CategoryIcons.allIconKeys.where((k) => !customIcons.contains(k)),
    ];

    final displayIconKeys = showAllIcons.value
        ? allAvailableIcons
        : [
            ...customIcons.take(5),
            ...CategoryIcons.basicIconKeys
                .where((k) => !customIcons.contains(k))
          ].take(15).toList();

    Future<void> save() => _save(
          context,
          ref,
          l10n: l10n,
          nameController: nameController,
          selectedIcon: selectedIcon,
          selectedColor: selectedColor,
          selectedType: selectedType,
          isLoading: isLoading,
          createBudget: createBudget,
          budgetAmountController: budgetAmountController,
          budgetPeriod: budgetPeriod,
          monthStartDay: monthStartDay,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(category == null ? l10n.addCategory : l10n.editCategory),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            // Live preview of the selected icon + color
            _CategoryPreview(
              colorValue: selectedColor.value,
              iconName: selectedIcon.value,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Category Type Selector
            _SectionLabel(l10n.categoryType),
            const SizedBox(height: AppSpacing.sm),
            _CategoryTypeSelector(
              selected: selectedType.value,
              onChanged: (type) => selectedType.value = type,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppInput(
              label: l10n.categoryName,
              controller: nameController,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(l10n.categoryIcon),
            const SizedBox(height: AppSpacing.sm),
            _CategoryIconGrid(
              iconKeys: displayIconKeys,
              selectedIcon: selectedIcon.value,
              colorValue: selectedColor.value,
              onSelected: (iconKey) => selectedIcon.value = iconKey,
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton.icon(
                icon: Icon(
                    showAllIcons.value ? Icons.expand_less : Icons.expand_more),
                label: Text(
                    showAllIcons.value ? l10n.collapse : l10n.showMoreIcons),
                onPressed: () => showAllIcons.value = !showAllIcons.value,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(l10n.categoryColor),
            const SizedBox(height: AppSpacing.sm),
            _CategoryColorGrid(
              selectedColor: selectedColor.value,
              onSelected: (color) => selectedColor.value = color,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.createBudgetForCategory),
                subtitle: Text(l10n.budgetOnlyForExpense),
                value: createBudget.value &&
                    selectedType.value == CategoryType.expense,
                onChanged: selectedType.value == CategoryType.expense &&
                        category == null
                    ? (value) => createBudget.value = value
                    : null,
              ),
            ),
            if (createBudget.value &&
                selectedType.value == CategoryType.expense) ...[
              const SizedBox(height: AppSpacing.lg),
              _BudgetFields(
                period: budgetPeriod.value,
                onPeriodChanged: (value) => budgetPeriod.value = value,
                amountController: budgetAmountController,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: l10n.save,
              onPressed: save,
              isLoading: isLoading.value,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required AppLocalizations l10n,
    required TextEditingController nameController,
    required ValueNotifier<String> selectedIcon,
    required ValueNotifier<int> selectedColor,
    required ValueNotifier<CategoryType> selectedType,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> createBudget,
    required TextEditingController budgetAmountController,
    required ValueNotifier<budget_model.PeriodType> budgetPeriod,
    required int monthStartDay,
  }) async {
    if (nameController.text.isEmpty) {
      showAppSnackBar(
        context,
        l10n.categoryNameRequiredError,
        type: AppSnackBarType.error,
      );
      return;
    }

    isLoading.value = true;

    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final newCategory = Category(
        id: category?.id ?? '',
        name: nameController.text,
        iconName: selectedIcon.value,
        colorValue: selectedColor.value,
        type: selectedType.value,
        createdAt: category?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (category == null) {
        final createdCategory = await categoryRepo.createCategory(
          newCategory,
          workspaceIdOverride: workspaceId,
        );
        if (createBudget.value &&
            selectedType.value == CategoryType.expense) {
          final amount =
              CurrencyFormatter.parseVND(budgetAmountController.text);
          if (amount == null) {
            throw const FormatException('Invalid budget amount');
          }
          final amountCents = CurrencyFormatter.toCents(amount);
          final now = DateTime.now();
          late final DateTime periodStart;
          late final DateTime periodEnd;
          switch (budgetPeriod.value) {
            case budget_model.PeriodType.yearly:
              periodStart = DateTime(now.year, 1, 1);
              periodEnd = DateTime(now.year, 12, 31, 23, 59, 59);
              break;
            case budget_model.PeriodType.monthly:
            default:
              final cycle = CycleUtils.getCurrentCycleRange(monthStartDay);
              periodStart = cycle.start;
              periodEnd = cycle.end;
              break;
          }

          await ref.read(budgetRepositoryProvider).createBudget(
                budget_model.Budget(
                  id: '',
                  categoryId: createdCategory.id,
                  periodType: budgetPeriod.value,
                  periodStart: periodStart,
                  periodEnd: periodEnd,
                  limitCents: amountCents,
                  consumedCents: 0,
                  allowOverdraft: false,
                  overdraftCents: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                workspaceIdOverride: workspaceId,
              );
        }
      } else {
        await categoryRepo.updateCategory(
          newCategory,
          workspaceIdOverride: workspaceId,
        );
      }

      ref.invalidate(categoriesProvider);
      ref.invalidate(categoriesByTypeProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(budgetsWithConsumedProvider);
      if (workspaceId != null && workspaceId!.isNotEmpty) {
        ref.invalidate(categoriesForWorkspaceProvider(workspaceId!));
        ref.invalidate(categoriesByTypeForWorkspaceProvider);
      }

      if (context.mounted) {
        Navigator.of(context).pop(true);
        showAppSnackBar(context, l10n.success, type: AppSnackBarType.success);
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'category',
          action: category == null ? 'create_category' : 'update_category',
          screen: 'category_edit_screen',
          extraContext: {
            if (category != null) 'category_id': category!.id,
            'category_type': selectedType.value.toString(),
            'icon_name': selectedIcon.value,
          },
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionLabelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: sectionLabelStyle),
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.colorValue, required this.iconName});

  final int colorValue;
  final String iconName;

  @override
  Widget build(BuildContext context) {
    final previewColor = Color(colorValue);
    final previewIcon = CategoryIcons.getIcon(iconName);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: previewColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Icon(previewIcon, size: 32, color: previewColor),
    );
  }
}

class _CategoryTypeSelector extends StatelessWidget {
  const _CategoryTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final CategoryType selected;
  final ValueChanged<CategoryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<CategoryType>(
      segments: [
        ButtonSegment(
          value: CategoryType.expense,
          label: Text(l10n.expense),
          icon: const Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: CategoryType.income,
          label: Text(l10n.income),
          icon: const Icon(Icons.arrow_downward),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (Set<CategoryType> selection) {
        onChanged(selection.first);
      },
    );
  }
}

class _CategoryIconGrid extends StatelessWidget {
  const _CategoryIconGrid({
    required this.iconKeys,
    required this.selectedIcon,
    required this.colorValue,
    required this.onSelected,
  });

  final List<String> iconKeys;
  final String selectedIcon;
  final int colorValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: iconKeys.map((iconKey) {
        final isSelected = selectedIcon == iconKey;
        final iconData = CategoryIcons.getIcon(iconKey);
        final iconColor = Color(colorValue);
        return GestureDetector(
          onTap: () => onSelected(iconKey),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? iconColor.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: isSelected
                  ? Border.all(color: iconColor, width: 2)
                  : Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
            ),
            child: Center(
              child: Icon(
                iconData,
                size: AppSpacing.iconSize,
                color: isSelected
                    ? iconColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryColorGrid extends StatelessWidget {
  const _CategoryColorGrid({
    required this.selectedColor,
    required this.onSelected,
  });

  static const _colors = [
    0xFF9E9E9E,
    0xFF7F3DFF,
    0xFFFD3C4A,
    0xFFFD9B63,
    0xFFFCAC12,
    0xFF00A86B,
    0xFF0077FF,
    0xFFFF7EB3,
    0xFF7F3D3D,
    0xFF9C27B0,
    0xFF673AB7,
    0xFF3F51B5,
    0xFF2196F3,
    0xFF03A9F4,
    0xFF00BCD4,
    0xFF009688,
    0xFF4CAF50,
    0xFF8BC34A,
    0xFFCDDC39,
    0xFFFFEB3B,
    0xFFFFC107,
    0xFFFF9800,
    0xFFFF5722,
    0xFF795548,
    0xFF607D8B,
  ];

  final int selectedColor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: _colors.map((color) {
        final isSelected = selectedColor == color;
        return GestureDetector(
          onTap: () => onSelected(color),
          child: Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Color(color), width: 2)
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BudgetFields extends StatelessWidget {
  const _BudgetFields({
    required this.period,
    required this.onPeriodChanged,
    required this.amountController,
  });

  final budget_model.PeriodType period;
  final ValueChanged<budget_model.PeriodType> onPeriodChanged;
  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<budget_model.PeriodType>(
          initialValue: period,
          decoration: InputDecoration(
            labelText: l10n.budgetPeriod,
          ),
          items: [
            DropdownMenuItem(
              value: budget_model.PeriodType.monthly,
              child: Text(l10n.monthly),
            ),
            DropdownMenuItem(
              value: budget_model.PeriodType.yearly,
              child: Text(l10n.yearly),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onPeriodChanged(value);
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Budget amount',
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            VNDInputFormatter(),
          ],
        ),
      ],
    );
  }
}
