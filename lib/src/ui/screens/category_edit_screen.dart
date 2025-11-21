// path: lib/src/ui/screens/category_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/src/models/category.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import '../../../l10n/app_localizations.dart';

class CategoryEditScreen extends HookConsumerWidget {
  final Category? category;

  const CategoryEditScreen({super.key, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController(text: category?.name ?? '');
    final selectedIcon = useState(category?.iconName ?? '🏷️');
    final selectedColor = useState(category?.colorValue ?? 0xFF7F3DFF);
    final isLoading = useState(false);

    final icons = ['🏷️', '🍔', '🚗', '🏠', '💊', '🎓', '💰', '🎮', '✈️', '👕'];
    final colors = [
      0xFF7F3DFF, 0xFFFD3C4A, 0xFFFD9B63, 0xFFFCAC12,
      0xFF00A86B, 0xFF0077FF, 0xFFFF7EB3, 0xFF7F3D3D,
    ];

    Future<void> save() async {
      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter category name')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final categoryRepo = ref.read(categoryRepositoryProvider);
        final newCategory = Category(
          id: category?.id ?? 0,
          name: nameController.text,
          iconName: selectedIcon.value,
          colorValue: selectedColor.value,
          createdAt: category?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (category == null) {
          await categoryRepo.createCategory(newCategory);
          // Không cần gọi invalidate - provider sẽ tự động refresh khi màn hình trở lại
        } else {
          await categoryRepo.updateCategory(newCategory);
        }

        if (context.mounted) {
          Navigator.of(context).pop(true);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppInput(
              label: l10n.categoryName,
              controller: nameController,
            ),
            const SizedBox(height: 16),
            Text(l10n.categoryIcon, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
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
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(l10n.categoryColor, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
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

