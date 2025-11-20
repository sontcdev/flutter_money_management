// path: lib/src/ui/screens/category_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/src/models/category.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryEditScreen extends HookConsumerWidget {
  final Category? category;

  const CategoryEditScreen({Key? key, this.category}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController(text: category?.name ?? '');
    final selectedIcon = useState(category?.icon ?? '🏷️');
    final selectedColor = useState(category?.color ?? '#7F3DFF');
    final selectedType = useState(category?.type ?? CategoryType.expense);
    final isLoading = useState(false);

    final icons = ['🏷️', '🍔', '🚗', '🏠', '💊', '🎓', '💰', '🎮', '✈️', '👕'];
    final colors = [
      '#7F3DFF', '#FD3C4A', '#FD9B63', '#FCAC12',
      '#00A86B', '#0077FF', '#FF7EB3', '#7F3D3D',
    ];

    Future<void> _save() async {
      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter category name')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final categoryRepo = ref.read(categoryRepositoryProvider);
        final newCategory = Category(
          id: category?.id ?? 0,
          name: nameController.text,
          icon: selectedIcon.value,
          color: selectedColor.value,
          type: selectedType.value,
          createdAt: category?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (category == null) {
          await categoryRepo.create(newCategory);
        } else {
          await categoryRepo.update(newCategory);
        }

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.success)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            AppInput(
              label: l10n.categoryName,
              controller: nameController,
            ),
            SizedBox(height: 16),
            Text(l10n.categoryIcon, style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: icons.map((icon) {
                final isSelected = selectedIcon.value == icon;
                return GestureDetector(
                  onTap: () => selectedIcon.value = icon,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(icon, style: TextStyle(fontSize: 24))),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text(l10n.categoryColor, style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
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
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            SegmentedButton<CategoryType>(
              segments: [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text(l10n.expense),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text(l10n.income),
                ),
              ],
              selected: {selectedType.value},
              onSelectionChanged: (Set<CategoryType> types) {
                selectedType.value = types.first;
              },
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: l10n.save,
                onPressed: _save,
                isLoading: isLoading.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

