// path: lib/src/ui/screens/budget_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../services/budget_service.dart';
import '../widgets/app_input.dart';
import '../widgets/app_button.dart';

class BudgetEditScreen extends ConsumerStatefulWidget {
  final Budget? budget;

  const BudgetEditScreen({
    super.key,
    this.budget,
  });

  @override
  ConsumerState<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends ConsumerState<BudgetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  Category? _selectedCategory;
  PeriodType _selectedPeriodType = PeriodType.monthly;
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();
  bool _allowOverdraft = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _nameController.text = widget.budget!.name ?? '';
      _limitController.text = '${widget.budget!.limitCents / 100}';
      _selectedPeriodType = widget.budget!.periodType;
      _selectedStartDate = widget.budget!.periodStart;
      _selectedEndDate = widget.budget!.periodEnd;
      _allowOverdraft = widget.budget!.allowOverdraft;
    } else {
      // Set default dates for monthly period
      final now = DateTime.now();
      _selectedStartDate = DateTime(now.year, now.month, 1);
      _selectedEndDate = DateTime(now.year, now.month + 1, 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedStartDate = date;
        if (_selectedPeriodType == PeriodType.monthly) {
          _selectedEndDate = DateTime(date.year, date.month + 1, 0);
        } else if (_selectedPeriodType == PeriodType.yearly) {
          _selectedEndDate = DateTime(date.year, 12, 31);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedEndDate = date);
    }
  }

  void _updatePeriodDates() {
    setState(() {
      if (_selectedPeriodType == PeriodType.monthly) {
        _selectedStartDate = DateTime(_selectedStartDate.year, _selectedStartDate.month, 1);
        _selectedEndDate = DateTime(_selectedStartDate.year, _selectedStartDate.month + 1, 0);
      } else if (_selectedPeriodType == PeriodType.yearly) {
        _selectedStartDate = DateTime(_selectedStartDate.year, 1, 1);
        _selectedEndDate = DateTime(_selectedStartDate.year, 12, 31);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.required)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final limitText = _limitController.text.replaceAll(',', '');
      final limitCents = (double.parse(limitText) * 100).toInt();

      final budget = Budget(
        id: widget.budget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        categoryId: _selectedCategory!.id,
        periodType: _selectedPeriodType,
        periodStart: _selectedStartDate,
        periodEnd: _selectedEndDate,
        limitCents: limitCents,
        consumedCents: widget.budget?.consumedCents ?? 0,
        allowOverdraft: _allowOverdraft,
        overdraftCents: widget.budget?.overdraftCents ?? 0,
        createdAt: widget.budget?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(budgetRepositoryProvider);

      if (widget.budget != null) {
        await repo.updateBudget(budget);
      } else {
        await repo.createBudget(budget);
      }

      if (mounted) {
        ref.invalidate(budgetsProvider);
        Navigator.of(context).pop();
      }
    } on BudgetDuplicateException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget != null ? l10n.editBudget : l10n.addBudget),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              categories.when(
                data: (categoriesList) {
                  // Filter categories to only expense type for budgets
                  final expenseCategories = categoriesList
                      .where((c) => c.type == CategoryType.expense)
                      .toList();

                  // Auto-select first category if none selected
                  if (_selectedCategory == null && expenseCategories.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedCategory = expenseCategories.first);
                    });
                  }

                  if (expenseCategories.isEmpty) {
                    return Column(
                      children: [
                        Text(
                          'No expense categories available. Please add an expense category first.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/add-category'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Category'),
                        ),
                      ],
                    );
                  }

                  return DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(labelText: l10n.category),
                    items: expenseCategories.map((category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                    validator: (value) {
                      if (value == null) {
                        return l10n.required;
                      }
                      return null;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stackTrace) {
                  debugPrint('Error loading categories: $error');
                  return Text(
                    'Error loading categories: $error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  );
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'Tên hũ chi tiêu',
                controller: _nameController,
                hint: 'Nhập tên hũ (tùy chọn)',
              ),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.limit,
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return l10n.invalidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.period,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<PeriodType>(
                segments: [
                  ButtonSegment(
                    value: PeriodType.monthly,
                    label: Text(l10n.monthly),
                  ),
                  ButtonSegment(
                    value: PeriodType.yearly,
                    label: Text(l10n.yearly),
                  ),
                  ButtonSegment(
                    value: PeriodType.custom,
                    label: Text(l10n.custom),
                  ),
                ],
                selected: {_selectedPeriodType},
                onSelectionChanged: (Set<PeriodType> selected) {
                  setState(() {
                    _selectedPeriodType = selected.first;
                    _updatePeriodDates();
                  });
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'Start Date',
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(_selectedStartDate),
                ),
                readOnly: true,
                onTap: _selectStartDate,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'End Date',
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(_selectedEndDate),
                ),
                readOnly: _selectedPeriodType != PeriodType.custom,
                onTap: _selectedPeriodType == PeriodType.custom ? _selectEndDate : null,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(l10n.allowOverdraft),
                value: _allowOverdraft,
                onChanged: (value) {
                  setState(() => _allowOverdraft = value ?? false);
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

