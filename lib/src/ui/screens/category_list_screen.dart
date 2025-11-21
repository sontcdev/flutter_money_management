// path: lib/src/ui/screens/category_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../providers/category_providers.dart';
import '../../data/repositories/category_repository.dart';
import 'category_edit_screen.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories yet. Add one using the + button.'),
            );
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Dismissible(
                key: Key(category.id),
                background: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Edit
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryEditScreen(category: category),
                      ),
                    );
                    return false;
                  } else {
                    // Delete
                    return await _showDeleteConfirmDialog(context);
                  }
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    try {
                      await ref.read(categoryListProvider.notifier).deleteCategory(category.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${category.name} deleted')),
                        );
                      }
                    } on CategoryInUseException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cannot delete: ${e.transactionsCount} transaction(s) and ${e.budgetsCount} budget(s) use this category'),
                            duration: const Duration(seconds: 4),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      // Refresh to restore item
                      ref.read(categoryListProvider.notifier).refresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting category: $e')),
                        );
                      }
                      ref.read(categoryListProvider.notifier).refresh();
                    }
                  }
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.colorHex != null
                        ? Color(int.parse('0xFF${category.colorHex!.replaceFirst('#', '')}'))
                        : Colors.grey,
                    child: Icon(
                      category.iconName != null
                          ? _getIconData(category.iconName!)
                          : Icons.category,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(category.name),
                  subtitle: Text(category.type == CategoryType.expense ? 'Expense' : 'Income'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryEditScreen(category: category),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading categories: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CategoryEditScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'movie':
        return Icons.movie;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }
}

