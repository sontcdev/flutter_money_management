import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/providers/custom_icons_provider.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

class CategoryEditScreen extends HookConsumerWidget {
  final Category? category;
  final CategoryType? initialType;

  const CategoryEditScreen({super.key, this.category, this.initialType});

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

    final colors = [
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

    Future<void> save() async {
      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.categoryNameRequiredError)),
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
          await categoryRepo.createCategory(newCategory);
        } else {
          await categoryRepo.updateCategory(newCategory);
        }

        if (context.mounted) {
          Navigator.of(context).pop(true);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(category == null ? l10n.addCategory : l10n.editCategory),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Category Type Selector
            Text(l10n.categoryType,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<CategoryType>(
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
              selected: {selectedType.value},
              onSelectionChanged: (Set<CategoryType> selection) {
                selectedType.value = selection.first;
              },
            ),
            const SizedBox(height: 16),
            AppInput(
              label: l10n.categoryName,
              controller: nameController,
            ),
            const SizedBox(height: 16),
            Text(l10n.categoryIcon,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayIconKeys.map((iconKey) {
                final isSelected = selectedIcon.value == iconKey;
                final iconData = CategoryIcons.getIcon(iconKey);
                final iconColor = Color(selectedColor.value);
                return GestureDetector(
                  onTap: () => selectedIcon.value = iconKey,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? iconColor.withValues(alpha: 0.2)
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: iconColor, width: 2)
                          : Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        size: 24,
                        color: isSelected
                            ? iconColor
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: Icon(
                    showAllIcons.value ? Icons.expand_less : Icons.expand_more),
                label: Text(
                    showAllIcons.value ? l10n.collapse : l10n.showMoreIcons),
                onPressed: () => showAllIcons.value = !showAllIcons.value,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.categoryColor,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((color) {
                final isSelected = selectedColor.value == color;
                return GestureDetector(
                  onTap: () => selectedColor.value = color,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: l10n.save,
                onPressed: save,
                isLoading: isLoading.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
