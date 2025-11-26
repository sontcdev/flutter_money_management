// path: lib/src/providers/providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/app_database.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../services/budget_service.dart';
import '../services/auth_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';

// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Services
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetService(db);
});


// Repositories
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  return TransactionRepository(db, budgetService);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  return BudgetRepository(db, budgetService);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

// Data providers
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getAllTransactions();
});

final transactionsByDateRangeProvider = FutureProvider.family<List<Transaction>, DateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getTransactionsByDateRange(dateRange.start, dateRange.end);
  },
);

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getAllBudgets();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories();
});

final categoriesByTypeProvider = FutureProvider.family<List<Category>, CategoryType>((ref, type) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoriesByType(type);
});

final categoryProvider = FutureProvider.family<Category?, int>((ref, categoryId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
});

// Budget with calculated consumed cents from transactions
final budgetsWithConsumedProvider = FutureProvider<List<Budget>>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  
  return budgets.map((budget) {
    // Calculate consumed cents from transactions for this budget's category and period
    final consumedCents = transactions
        .where((t) =>
            t.categoryId == budget.categoryId &&
            t.type == TransactionType.expense &&
            t.dateTime.isAfter(budget.periodStart.subtract(const Duration(seconds: 1))) &&
            t.dateTime.isBefore(budget.periodEnd.add(const Duration(seconds: 1))))
        .fold<int>(0, (sum, t) => sum + t.amountCents);
    
    return budget.copyWith(consumedCents: consumedCents);
  }).toList();
});

// Helper classes
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

