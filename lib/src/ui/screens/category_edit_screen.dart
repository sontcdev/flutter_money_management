// path: lib/src/ui/screens/category_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../providers/providers.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryEditScreen({Key? key, this.category}) : super(key: key);

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late CategoryType _selectedType;
  String? _selectedColorHex;
  String? _selectedIconName;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  final List<MapEntry<String, IconData>> _availableIcons = [
    const MapEntry('shopping_cart', Icons.shopping_cart),
    const MapEntry('restaurant', Icons.restaurant),
    const MapEntry('directions_car', Icons.directions_car),
    const MapEntry('home', Icons.home),
    const MapEntry('local_hospital', Icons.local_hospital),
    const MapEntry('school', Icons.school),
    const MapEntry('flight', Icons.flight),
    const MapEntry('movie', Icons.movie),
    const MapEntry('fitness_center', Icons.fitness_center),
    const MapEntry('attach_money', Icons.attach_money),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type ?? CategoryType.expense;
    _selectedColorHex = widget.category?.colorHex;
    _selectedIconName = widget.category?.iconName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            RadioListTile<CategoryType>(
              title: const Text('Expense'),
              value: CategoryType.expense,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            RadioListTile<CategoryType>(
              title: const Text('Income'),
              value: CategoryType.income,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                final isSelected = _selectedColorHex == colorHex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorHex = colorHex;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((entry) {
                final isSelected = _selectedIconName == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIconName = entry.key;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(entry.value, color: isSelected ? Colors.blue : Colors.black54),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveCategory,
              child: Text(isEditing ? 'Update Category' : 'Create Category'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final repository = ref.read(categoryRepositoryProvider);
      
      if (widget.category != null) {
        // Update existing category
        final updated = widget.category!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          colorHex: _selectedColorHex,
          iconName: _selectedIconName,
        );
        await repository.updateCategory(updated);
      } else {
        // Create new category
        await repository.createCategory(
          name: _nameController.text.trim(),
          type: _selectedType,
          colorHex: _selectedColorHex,
          iconName: _selectedIconName,
        );
      }

      // Refresh categoriesProvider to update the list screen
      //await ref.refresh(categoriesProvider.future);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null ? 'Category updated' : 'Category created'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

