// path: lib/src/providers/transaction_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/local/daos/budget_dao.dart';
import '../services/budget_service.dart';
import 'providers.dart';

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetDao(db);
});

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final budgetDao = ref.watch(budgetDaoProvider);
  return BudgetService(budgetDao);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return TransactionRepository(db, budgetService, categoryRepo);
});

final transactionListProvider = AsyncNotifierProvider<TransactionListNotifier, List<Transaction>>(
  TransactionListNotifier.new,
);

class TransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    return _loadTransactions();
  }

  Future<List<Transaction>> _loadTransactions() async {
    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _loadTransactions();
    });
  }

  Future<void> addTransaction(
    Transaction transaction, {
    bool allowOverdraft = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.createTransaction(
        transaction,
        allowOverdraft: allowOverdraft,
      );
      return await _loadTransactions();
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.updateTransaction(transaction);
      return await _loadTransactions();
    });
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(id);
      return await _loadTransactions();
    });
  }
}

final transactionByIdProvider = FutureProvider.family<Transaction?, String>((ref, id) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionById(id);
});

