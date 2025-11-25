// path: lib/src/providers/report_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/transaction.dart';
import '../ui/widgets/calendar_grid.dart';
import 'providers.dart';

// Selected month provider
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// Selected date provider
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);


// Calendar data provider
final calendarDataProvider = FutureProvider.family<Map<DateTime, List<AmountBadge>>, DateTime>((ref, month) async {
  // Watch transactionsProvider để tự động reload khi có thay đổi
  ref.watch(transactionsProvider);
  
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  final txnRepo = ref.watch(transactionRepositoryProvider);
  final allTransactions = await txnRepo.getAllTransactions();

  final transactions = allTransactions.where((txn) {
    return txn.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
           txn.dateTime.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  final Map<DateTime, List<AmountBadge>> cellData = {};

  for (final txn in transactions) {
    final date = DateTime(txn.dateTime.year, txn.dateTime.month, txn.dateTime.day);

    if (!cellData.containsKey(date)) {
      cellData[date] = [];
    }

    cellData[date]!.add(AmountBadge(
      amountCents: txn.amountCents,
      isIncome: txn.type == TransactionType.income,
    ));
  }

  return cellData;
});

// Monthly summary provider
final monthlySummaryProvider = FutureProvider.family<Map<String, int>, DateTime>((ref, month) async {
  // Watch transactionsProvider để tự động reload khi có thay đổi
  ref.watch(transactionsProvider);
  
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  final txnRepo = ref.watch(transactionRepositoryProvider);
  final allTransactions = await txnRepo.getAllTransactions();

  final transactions = allTransactions.where((txn) {
    return txn.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
           txn.dateTime.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  int totalIncome = 0;
  int totalExpense = 0;

  for (final txn in transactions) {
    if (txn.type == TransactionType.income) {
      totalIncome += txn.amountCents;
    } else {
      totalExpense += txn.amountCents;
    }
  }

  return {
    'income': totalIncome,
    'expense': totalExpense,
    'net': totalIncome - totalExpense,
  };
});

// Transaction groups provider
final transactionGroupsProvider = FutureProvider.family<List<TransactionGroup>, DateTime>((ref, month) async {
  // Watch transactionsProvider để tự động reload khi có thay đổi
  ref.watch(transactionsProvider);
  
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  final txnRepo = ref.watch(transactionRepositoryProvider);
  final allTransactions = await txnRepo.getAllTransactions();

  final transactions = allTransactions.where((txn) {
    return txn.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
           txn.dateTime.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

  final Map<DateTime, List<TransactionWithCategory>> groups = {};

  for (final txn in transactions) {
    final date = DateTime(txn.dateTime.year, txn.dateTime.month, txn.dateTime.day);

    if (!groups.containsKey(date)) {
      groups[date] = [];
    }

    // Get category name
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final categories = await categoryRepo.getAllCategories();
    final category = categories.firstWhere((c) => c.id == txn.categoryId, orElse: () => categories.first);

    groups[date]!.add(TransactionWithCategory(
      transaction: txn,
      categoryName: category.name,
    ));
  }

  final result = <TransactionGroup>[];

  for (final entry in groups.entries) {
    final dayTransactions = entry.value;
    int netAmount = 0;

    for (final txnWithCat in dayTransactions) {
      if (txnWithCat.transaction.type == TransactionType.income) {
        netAmount += txnWithCat.transaction.amountCents;
      } else {
        netAmount -= txnWithCat.transaction.amountCents;
      }
    }

    result.add(TransactionGroup(
      date: entry.key,
      netAmount: netAmount,
      transactions: dayTransactions,
    ));
  }

  result.sort((a, b) => b.date.compareTo(a.date));

  return result;
});

// Transaction list notifier
final transactionListNotifierProvider = StateNotifierProvider<TransactionListNotifier, AsyncValue<void>>((ref) {
  return TransactionListNotifier(ref);
});

class TransactionListNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  TransactionListNotifier(this.ref) : super(const AsyncValue.data(null));

  void loadNextMonth() {
    final currentMonth = ref.read(selectedMonthProvider);
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    ref.read(selectedMonthProvider.notifier).state = nextMonth;
    ref.read(selectedDateProvider.notifier).state = null;
  }

  void loadPreviousMonth() {
    final currentMonth = ref.read(selectedMonthProvider);
    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    ref.read(selectedMonthProvider.notifier).state = prevMonth;
    ref.read(selectedDateProvider.notifier).state = null;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      // Invalidate all providers to force reload
      ref.invalidate(calendarDataProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(transactionGroupsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void selectDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
  }

  Future<void> deleteTransaction(int transactionId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.deleteTransaction(transactionId);

      // Refresh data
      await refresh();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Transaction group model
class TransactionGroup {
  final DateTime date;
  final int netAmount;
  final List<TransactionWithCategory> transactions;

  TransactionGroup({
    required this.date,
    required this.netAmount,
    required this.transactions,
  });
}

// Transaction with category name
class TransactionWithCategory {
  final Transaction transaction;
  final String categoryName;

  TransactionWithCategory({
    required this.transaction,
    required this.categoryName,
  });
}

