import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

part 'transaction_management_screen_sections.dart';

void _useSearchDebounce(
  TextEditingController searchController,
  ValueNotifier<String> searchQuery,
) {
  useEffect(() {
    Timer? debounce;
    void listener() {
      debounce?.cancel();
      debounce = Timer(
        const Duration(milliseconds: 300),
        () => searchQuery.value = searchController.text,
      );
    }

    searchController.addListener(listener);
    return () {
      debounce?.cancel();
      searchController.removeListener(listener);
    };
  }, [searchController]);
}

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
    final selectedCategoryId = useState<String?>(null);
    final selectedBudgetId = useState<String?>(null);
    final selectedTransactionIds = useState<Set<String>>({});
    final isSelectionMode = useState(false);

    // Listen to search controller
    _useSearchDebounce(searchController, searchQuery);

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
          _SelectionModeToggle(
            isSelectionMode: isSelectionMode.value,
            onPressed: () {
              isSelectionMode.value = !isSelectionMode.value;
              if (!isSelectionMode.value) {
                selectedTransactionIds.value = {};
              }
            },
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
            _SelectionBar(
              count: selectedTransactionIds.value.length,
              onSelectAll: () {
                final allTransactions =
                    transactionsAsync.valueOrNull ?? [];
                final filteredIds = _filterTransactions(
                  context,
                  allTransactions,
                  searchQuery.value,
                  selectedCategoryId.value,
                  selectedBudgetId.value,
                  budgetsAsync.valueOrNull ?? [],
                ).map((t) => t.id).toSet();
                selectedTransactionIds.value = filteredIds;
              },
              onDeselectAll: () {
                selectedTransactionIds.value = {};
              },
            ),

          // Transactions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => syncCurrentWorkspaceData(ref),
              child: transactionsAsync.when(
                data: (transactions) {
                  final filteredTransactions = _filterTransactions(
                    context,
                    transactions,
                    searchQuery.value,
                    selectedCategoryId.value,
                    selectedBudgetId.value,
                    budgetsAsync.valueOrNull ?? [],
                  );

                  if (filteredTransactions.isEmpty) {
                    return _ManagementEmptyState(
                      hasFilter: searchQuery.value.isNotEmpty ||
                          selectedCategoryId.value != null ||
                          selectedBudgetId.value != null,
                      onClearFilter: () {
                        searchController.clear();
                        selectedCategoryId.value = null;
                        selectedBudgetId.value = null;
                      },
                    );
                  }

                  return categoriesAsync.when(
                    data: (categories) {
                      final categoryMap = {
                        for (final c in categories) c.id: c
                      };
                      return _TransactionRowsList(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (i) => _buildTransactionRow(
                          context,
                          l10n,
                          filteredTransactions[i],
                          categoryMap,
                          selectedTransactionIds,
                          isSelectionMode,
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(l10n.errorLoadingCategories('$error')),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(l10n.errorLoadingTransactions('$error')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    AppLocalizations l10n,
    Transaction transaction,
    Map<String, Category> categoryMap,
    ValueNotifier<Set<String>> selectedTransactionIds,
    ValueNotifier<bool> isSelectionMode,
  ) {
    final category = categoryMap[transaction.categoryId];
    final categoryColor =
        category != null ? getCategoryColor(category.colorValue) : null;
    final isSelected =
        selectedTransactionIds.value.contains(transaction.id);

    void toggle() {
      final newSet = Set<String>.from(selectedTransactionIds.value);
      if (isSelected) {
        newSet.remove(transaction.id);
      } else {
        newSet.add(transaction.id);
      }
      selectedTransactionIds.value = newSet;
    }

    final item = TransactionItem(
      transaction: transaction,
      categoryName: category?.name ?? l10n.unknown,
      categoryIconName: category?.iconName ?? 'inventory_2',
      categoryColor: categoryColor,
      showDate: true,
      showChevron: !isSelectionMode.value,
      onTap: () {
        if (isSelectionMode.value) {
          toggle();
        } else {
          Navigator.pushNamed(
            context,
            '/transaction-detail',
            arguments: transaction.id,
          );
        }
      },
    );

    if (!isSelectionMode.value) {
      return GestureDetector(
        onLongPress: () {
          isSelectionMode.value = true;
          selectedTransactionIds.value = {transaction.id};
        },
        child: item,
      );
    }

    return Container(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
          : null,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => toggle(),
            ),
          ),
          Expanded(child: item),
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
    ValueNotifier<String?> selectedCategoryId,
    ValueNotifier<String?> selectedBudgetId,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: l10n.clear,
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
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('category-${selectedCategoryId.value}'),
                  initialValue: selectedCategoryId.value,
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.allCategories),
                    ),
                    ...categories.map((cat) => DropdownMenuItem<String?>(
                          value: cat.id,
                          child:
                              Text(cat.name, overflow: TextOverflow.ellipsis),
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
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('budget-${selectedBudgetId.value}'),
                  initialValue: selectedBudgetId.value,
                  decoration: InputDecoration(
                    labelText: l10n.budget,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.allBudgets),
                    ),
                    ...budgets.map((budget) {
                      final periodStr =
                          '${formatLocalizedMonthDay(context, budget.periodStart)} - ${formatLocalizedMonthDay(context, budget.periodEnd)}';
                      return DropdownMenuItem<String?>(
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
    BuildContext context,
    List<Transaction> transactions,
    String searchQuery,
    String? categoryId,
    String? budgetId,
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
        final amountMatch = CurrencyFormatter.formatVNDFromCents(
          t.amountCents,
          locale: localeNameOf(context),
        ).toLowerCase().contains(query);
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
            t.dateTime.isAfter(
                budget.periodStart.subtract(const Duration(seconds: 1))) &&
            t.dateTime
                .isBefore(budget.periodEnd.add(const Duration(seconds: 1)));
      }).toList();
    }

    return filtered;
  }

  void _showEditOptions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<String> transactionIds,
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
                _showCategoryPicker(
                    parentContext, ref, l10n, transactionIds, categories,
                    onSuccess: onSuccess);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.changeDate),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDatePicker(parentContext, ref, l10n, transactionIds,
                    onSuccess: onSuccess);
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
    List<String> transactionIds,
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
                      backgroundColor: getCategoryColor(category.colorValue)
                          .withValues(alpha: 0.1),
                      child: CategoryIconWidget(
                        iconName: category.iconName,
                        size: AppSpacing.iconSizeSm,
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
    List<String> transactionIds,
    String newCategoryId, {
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
        showAppSnackBar(
          context,
          l10n.updateSuccess,
          type: AppSnackBarType.success,
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'transaction',
          action: 'bulk_update_category',
          screen: 'transaction_management_screen',
          extraContext: {
            'transaction_count': transactionIds.length,
            'new_category_id': newCategoryId,
          },
        );
      }
    }
  }

  void _showDatePicker(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<String> transactionIds, {
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
      await _updateTransactionsDate(context, ref, l10n, transactionIds, picked,
          onSuccess: onSuccess);
    }
  }

  Future<void> _updateTransactionsDate(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<String> transactionIds,
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
        showAppSnackBar(
          context,
          l10n.updateSuccess,
          type: AppSnackBarType.success,
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'transaction',
          action: 'bulk_update_date',
          screen: 'transaction_management_screen',
          extraContext: {
            'transaction_count': transactionIds.length,
            'new_date': newDate.toIso8601String(),
          },
        );
      }
    }
  }
}
