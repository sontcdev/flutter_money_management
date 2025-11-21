// path: lib/src/providers/providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/app_database.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/account_repository.dart';
import '../services/budget_service.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/account.dart';

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

final reportServiceProvider = Provider<ReportService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReportService(db);
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

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepository(db);
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

final categoryProvider = FutureProvider.family<Category?, int>((ref, categoryId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAllAccounts();
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

