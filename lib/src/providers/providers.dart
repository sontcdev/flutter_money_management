// path: lib/src/providers/providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/app_database.dart';
import '../services/budget_service.dart';
import '../services/report_service.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../i18n/locale_provider.dart';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetService(db);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepository(db);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  return BudgetRepository(db, budgetService);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  return TransactionRepository(db, budgetService, categoryRepo, accountRepo);
});

final reportServiceProvider = Provider<ReportService>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return ReportService(transactionRepo, categoryRepo);
});

final categoriesProvider = FutureProvider((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getAllCategories();
});

final accountsProvider = FutureProvider((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  return await repo.getAllAccounts();
});

final budgetsProvider = FutureProvider((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return await repo.getAllBudgets();
});

final transactionsProvider = FutureProvider((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getTransactions();
});

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('isLoggedIn') ?? false;
});

