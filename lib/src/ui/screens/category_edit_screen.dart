// path: lib/src/ui/screens/category_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/category.dart';
import '../widgets/app_input.dart';
import '../widgets/app_button.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const CategoryEditScreen({
    super.key,
    this.categoryId,
  });

  @override
  ConsumerState<CategoryEditScreen> createState() =>
      _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _colorController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _loadCategory();
    } else {
      _iconController.text = '💰';
      _colorController.text = '#6366F1';
    }
  }

  Future<void> _loadCategory() async {
    final repo = ref.read(categoryRepositoryProvider);
    final category = await repo.getCategoryById(widget.categoryId!);
    if (category != null) {
      setState(() {
        _nameController.text = category.name;
        _iconController.text = category.icon;
        _colorController.text = category.color;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(categoryRepositoryProvider);
      final category = Category(
        id: widget.categoryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        icon: _iconController.text,
        color: _colorController.text,
        createdAt: widget.categoryId != null ? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.categoryId != null) {
        await repo.updateCategory(category);
      } else {
        await repo.createCategory(category);
      }

      if (mounted) {
        ref.invalidate(categoriesProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryId != null
            ? l10n.editCategory
            : l10n.addCategory),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                label: l10n.name,
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.icon,
                controller: _iconController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.color,
                controller: _colorController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                text: l10n.save,
                onPressed: _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

