// path: lib/src/ui/screens/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/category_item.dart';
import '../../data/repositories/category_repository.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: categories.when(
        data: (categoriesList) {
          if (categoriesList.isEmpty) {
            return Center(
              child: Text(l10n.noCategories),
            );
          }

          return ListView.builder(
            itemCount: categoriesList.length,
            itemBuilder: (context, index) {
              final category = categoriesList[index];
              return CategoryItem(
                category: category,
                onEdit: () {
                  Navigator.pushNamed(
                    context,
                    '/edit-category',
                    arguments: category.id,
                  );
                },
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.delete),
                      content: Text(l10n.confirmDelete),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      final repo = ref.read(categoryRepositoryProvider);
                      await repo.deleteCategory(category.id);
                      ref.invalidate(categoriesProvider);
                    } on CategoryInUseException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-category'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

