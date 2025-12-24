// path: lib/src/ui/screens/transaction_management_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../utils/currency_formatter.dart';
import '../../theme/app_colors.dart';
import '../widgets/category_icon_widget.dart';

class TransactionManagementScreen extends HookConsumerWidget {
  const TransactionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    // State
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedCategoryId = useState<int?>(null);
    final selectedBudgetId = useState<int?>(null);
    final selectedTransactionIds = useState<Set<int>>({});
    final isSelectionMode = useState(false);

    // Listen to search controller
    useEffect(() {
      void listener() {
        searchQuery.value = searchController.text;
      }
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageTransactions),
        actions: [
          if (isSelectionMode.value && selectedTransactionIds.value.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditOptions(
                context,
                ref,
                l10n,
                selectedTransactionIds.value.toList(),
                categoriesAsync.valueOrNull ?? [],
                onSuccess: () {
                  selectedTransactionIds.value = {};
                  isSelectionMode.value = false;
                },
              ),
              tooltip: l10n.editSelected,
            ),
          IconButton(
            icon: Icon(isSelectionMode.value ? Icons.close : Icons.checklist),
            onPressed: () {
              isSelectionMode.value = !isSelectionMode.value;
              if (!isSelectionMode.value) {
                selectedTransactionIds.value = {};
              }
            },
            tooltip: isSelectionMode.value ? l10n.cancel : l10n.selectAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          _buildFilters(
            context,
            l10n,
            searchController,
            categoriesAsync.valueOrNull ?? [],
            budgetsAsync.valueOrNull ?? [],
            selectedCategoryId,
            selectedBudgetId,
          ),

          // Selection bar
          if (isSelectionMode.value && selectedTransactionIds.value.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Text(
                    l10n.selectedCount(selectedTransactionIds.value.length),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.select_all),
                    label: Text(l10n.selectAll),
                    onPressed: () {
                      final allTransactions = transactionsAsync.valueOrNull ?? [];
                      final filteredIds = _filterTransactions(
                        allTransactions,
                        searchQuery.value,
                        selectedCategoryId.value,
                        selectedBudgetId.value,
                        budgetsAsync.valueOrNull ?? [],
                      ).map((t) => t.id).toSet();
                      selectedTransactionIds.value = filteredIds;
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.deselect),
                    label: Text(l10n.deselectAll),
                    onPressed: () {
                      selectedTransactionIds.value = {};
                    },
                  ),
                ],
              ),
            ),

          // Transactions list
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filteredTransactions = _filterTransactions(
                  transactions,
                  searchQuery.value,
                  selectedCategoryId.value,
                  selectedBudgetId.value,
                  budgetsAsync.valueOrNull ?? [],
                );

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTransactions,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return categoriesAsync.when(
                  data: (categories) {
                    return ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        final category = categories.firstWhere(
                          (c) => c.id == transaction.categoryId,
                          orElse: () => Category(
                            id: 0,
                            name: 'Unknown',
                            iconName: '📦',
                            colorValue: Colors.grey.toARGB32(),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );

                        final isSelected = selectedTransactionIds.value.contains(transaction.id);
                        final isExpense = transaction.type == TransactionType.expense;
                        final amountColor = isExpense ? AppColors.expense : AppColors.income;
                        final amountPrefix = isExpense ? '-' : '+';

                        return ListTile(
                          leading: isSelectionMode.value
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    final newSet = Set<int>.from(selectedTransactionIds.value);
                                    if (value == true) {
                                      newSet.add(transaction.id);
                                    } else {
                                      newSet.remove(transaction.id);
                                    }
                                    selectedTransactionIds.value = newSet;
                                  },
                                )
                              : CircleAvatar(
                                  backgroundColor: getCategoryColor(category.colorValue).withValues(alpha: 0.1),
                                  child: CategoryIconWidget(
                                    iconName: category.iconName,
                                    size: 20,
                                    color: getCategoryColor(category.colorValue),
                                  ),
                                ),
                          title: Text(
                            transaction.note?.isNotEmpty == true
                                ? transaction.note!
                                : category.name,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.name),
                              Text(
                                DateFormat('dd/MM/yyyy').format(transaction.dateTime),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Text(
                            '$amountPrefix${CurrencyFormatter.formatVNDFromCents(transaction.amountCents)}',
                            style: TextStyle(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () {
                            if (isSelectionMode.value) {
                              final newSet = Set<int>.from(selectedTransactionIds.value);
                              if (isSelected) {
                                newSet.remove(transaction.id);
                              } else {
                                newSet.add(transaction.id);
                              }
                              selectedTransactionIds.value = newSet;
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/transaction-detail',
                                arguments: transaction.id,
                              );
                            }
                          },
                          onLongPress: () {
                            if (!isSelectionMode.value) {
                              isSelectionMode.value = true;
                              selectedTransactionIds.value = {transaction.id};
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading categories: $error'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading transactions: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    AppLocalizations l10n,
    TextEditingController searchController,
    List<Category> categories,
    List<Budget> budgets,
    ValueNotifier<int?> selectedCategoryId,
    ValueNotifier<int?> selectedBudgetId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchByNameOrAmount,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Dropdowns
          Row(
            children: [
              // Category dropdown
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: selectedCategoryId.value,
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.allCategories),
                    ),
                    ...categories.map((cat) => DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(cat.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (value) {
                    selectedCategoryId.value = value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Budget dropdown
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: selectedBudgetId.value,
                  decoration: InputDecoration(
                    labelText: l10n.budget,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.allBudgets),
                    ),
                    ...budgets.map((budget) {
                      final periodStr =
                          '${DateFormat('dd/MM').format(budget.periodStart)} - ${DateFormat('dd/MM').format(budget.periodEnd)}';
                      return DropdownMenuItem<int?>(
                        value: budget.id,
                        child: Text(
                          periodStr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    selectedBudgetId.value = value;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    String searchQuery,
    int? categoryId,
    int? budgetId,
    List<Budget> budgets,
  ) {
    var filtered = List<Transaction>.from(transactions);

    // Sort by date descending
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Filter by search query (note or amount)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
        final amountMatch = CurrencyFormatter.formatVNDFromCents(t.amountCents)
            .toLowerCase()
            .contains(query);
        final rawAmountMatch = (t.amountCents / 100).toString().contains(query);
        return noteMatch || amountMatch || rawAmountMatch;
      }).toList();
    }

    // Filter by category
    if (categoryId != null) {
      filtered = filtered.where((t) => t.categoryId == categoryId).toList();
    }

    // Filter by budget
    if (budgetId != null) {
      final budget = budgets.firstWhere(
        (b) => b.id == budgetId,
        orElse: () => throw Exception('Budget not found'),
      );
      filtered = filtered.where((t) {
        return t.categoryId == budget.categoryId &&
            t.dateTime.isAfter(budget.periodStart.subtract(const Duration(seconds: 1))) &&
            t.dateTime.isBefore(budget.periodEnd.add(const Duration(seconds: 1)));
      }).toList();
    }

    return filtered;
  }

  void _showEditOptions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<int> transactionIds,
    List<Category> categories, {
    required VoidCallback onSuccess,
  }) {
    // Store parent context before showing bottom sheet
    final parentContext = context;
    
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title: Text(l10n.changeCategory),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCategoryPicker(parentContext, ref, l10n, transactionIds, categories, onSuccess: onSuccess);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.changeDate),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDatePicker(parentContext, ref, l10n, transactionIds, onSuccess: onSuccess);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<int> transactionIds,
    List<Category> categories, {
    required VoidCallback onSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.selectNewCategory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: getCategoryColor(category.colorValue).withValues(alpha: 0.1),
                      child: CategoryIconWidget(
                        iconName: category.iconName,
                        size: 20,
                        color: getCategoryColor(category.colorValue),
                      ),
                    ),
                    title: Text(category.name),
                    onTap: () async {
                      Navigator.pop(context);
                      await _updateTransactionsCategory(
                        context,
                        ref,
                        l10n,
                        transactionIds,
                        category.id,
                        onSuccess: onSuccess,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTransactionsCategory(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<int> transactionIds,
    int newCategoryId, {
    required VoidCallback onSuccess,
  }) async {
    try {
      final repository = ref.read(transactionRepositoryProvider);

      for (final id in transactionIds) {
        final transaction = await repository.getTransactionById(id);
        final updated = transaction.copyWith(
          categoryId: newCategoryId,
          updatedAt: DateTime.now(),
        );
        await repository.updateTransaction(updated);
      }

      ref.invalidate(transactionsProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(categoriesProvider);
      
      onSuccess();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  void _showDatePicker(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<int> transactionIds, {
    required VoidCallback onSuccess,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: l10n.selectNewDate,
    );

    if (picked != null && context.mounted) {
      await _updateTransactionsDate(context, ref, l10n, transactionIds, picked, onSuccess: onSuccess);
    }
  }

  Future<void> _updateTransactionsDate(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<int> transactionIds,
    DateTime newDate, {
    required VoidCallback onSuccess,
  }) async {
    try {
      final repository = ref.read(transactionRepositoryProvider);

      for (final id in transactionIds) {
        final transaction = await repository.getTransactionById(id);
        final updated = transaction.copyWith(
          dateTime: newDate,
          updatedAt: DateTime.now(),
        );
        await repository.updateTransaction(updated);
      }

      ref.invalidate(transactionsProvider);
      ref.invalidate(budgetsProvider);
      
      onSuccess();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }
}
