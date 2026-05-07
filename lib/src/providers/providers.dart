// path: lib/src/providers/providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_attachment.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/transaction_attachment_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../services/app_lock_service.dart';
import '../services/email_persistence_service.dart';
import '../services/transaction_receipt_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../utils/cycle_utils.dart';
import '../ui/screens/settings_screen.dart';
import 'auth_providers.dart';
import 'workspace_providers.dart';

// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

// Services
final appLockServiceProvider = Provider<AppLockService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLockService(prefs);
});

final emailPersistenceServiceProvider = Provider<EmailPersistenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return EmailPersistenceService(prefs);
});

// Repositories
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final transactionAttachmentRepositoryProvider = Provider<TransactionAttachmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionAttachmentRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final transactionReceiptServiceProvider = Provider<TransactionReceiptService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final attachments = ref.watch(transactionAttachmentRepositoryProvider);
  return TransactionReceiptService(
    supabase,
    attachments,
    () => ref.read(activeWorkspaceIdProvider),
  );
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BudgetRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CategoryRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

// Data providers
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getAllTransactions();
});

final transactionCanManageProvider = FutureProvider.family<bool, String>((ref, transactionId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.canCurrentUserManageTransaction(transactionId);
});

final transactionReceiptAttachmentProvider =
    FutureProvider.family<TransactionAttachment?, String>((ref, transactionId) async {
  final repository = ref.watch(transactionAttachmentRepositoryProvider);
  return repository.getLatestReceiptAttachmentByTransactionId(transactionId);
});

final transactionReceiptImageUrlProvider = FutureProvider.family<String?, String>((ref, transactionId) async {
  final attachment = await ref.watch(
    transactionReceiptAttachmentProvider(transactionId).future,
  );
  if (attachment == null) {
    return null;
  }

  final service = ref.watch(transactionReceiptServiceProvider);
  return service.createSignedReceiptUrl(attachment);
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

final categoryProvider = FutureProvider.family<Category?, String>((ref, categoryId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
});

// Budget with calculated consumed cents from transactions
final budgetsWithConsumedProvider = FutureProvider<List<Budget>>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  final monthStartDay = ref.watch(monthStartDayProvider);
  
  return budgets.map((budget) {
    // Calculate period based on monthStartDay for monthly budgets
    late final DateTime periodStart;
    late final DateTime periodEnd;
    
    if (budget.periodType == PeriodType.monthly) {
      // Use cycle range from monthStartDay setting
      final cycleRange = CycleUtils.getCurrentCycleRange(monthStartDay);
      periodStart = cycleRange.start;
      periodEnd = cycleRange.end;
    } else {
      // Use budget's stored period for yearly/custom
      periodStart = budget.periodStart;
      periodEnd = budget.periodEnd;
    }
    
    // Calculate consumed cents from transactions for this budget's category and period
    final consumedCents = transactions
        .where((t) =>
            t.categoryId == budget.categoryId &&
            t.type == TransactionType.expense &&
            t.dateTime.isAfter(periodStart.subtract(const Duration(seconds: 1))) &&
            t.dateTime.isBefore(periodEnd.add(const Duration(seconds: 1))))
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
