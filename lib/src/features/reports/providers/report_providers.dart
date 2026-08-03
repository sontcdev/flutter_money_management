import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/utils/category_color_codec.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';

// Tính toán tháng chu kỳ dựa trên ngày hiện tại và monthStartDay
DateTime _calculateCycleMonth(int monthStartDay) {
  final now = DateTime.now();
  // Nếu ngày hiện tại < ngày bắt đầu chu kỳ → lùi 1 tháng
  if (now.day < monthStartDay) {
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    return DateTime(prevMonth.year, prevMonth.month, 1);
  }
  return DateTime(now.year, now.month, 1);
}

// Selected month provider
// Khởi tạo dựa trên tháng của chu kỳ hiện tại, không phải tháng thực tế
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final monthStartDay = ref.watch(monthStartDayProvider);
  return _calculateCycleMonth(monthStartDay);
});

// Selected date provider
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

// Calendar data provider
final calendarDataProvider =
    FutureProvider.family<Map<DateTime, List<AmountBadge>>, DateTime>(
        (ref, month) async {
  // Watch transactionsProvider và monthStartDayProvider để tự động reload khi có thay đổi
  ref.watch(transactionsProvider);
  final monthStartDay = ref.watch(monthStartDayProvider);

  // Sử dụng cycle dates thay vì calendar month
  final cycleRange = CycleUtils.getCycleRangeForMonth(month, monthStartDay);
  final startDate = cycleRange.start;
  final endDate = cycleRange.end;

  final txnRepo = ref.watch(transactionRepositoryProvider);
  final allTransactions = await txnRepo.getAllTransactions();

  final transactions = allTransactions.where((txn) {
    return txn.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
        txn.dateTime.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  final Map<DateTime, List<AmountBadge>> cellData = {};

  // Group transactions by date and calculate totals
  final Map<DateTime, int> dailyIncome = {};
  final Map<DateTime, int> dailyExpense = {};

  for (final txn in transactions) {
    final date =
        DateTime(txn.dateTime.year, txn.dateTime.month, txn.dateTime.day);

    // Transfers only move money between wallets, so they belong to neither
    // total.
    if (txn.type == TransactionType.income) {
      dailyIncome[date] = (dailyIncome[date] ?? 0) + txn.amountCents;
    } else if (txn.type == TransactionType.expense) {
      dailyExpense[date] = (dailyExpense[date] ?? 0) + txn.amountCents;
    }
  }

  // Get all unique dates
  final allDates = {...dailyIncome.keys, ...dailyExpense.keys};

  // Convert daily totals to AmountBadges
  for (final date in allDates) {
    cellData[date] = [];

    final incomeTotal = dailyIncome[date] ?? 0;
    final expenseTotal = dailyExpense[date] ?? 0;

    // Add income badge if there's income
    if (incomeTotal > 0) {
      cellData[date]!.add(AmountBadge(
        amountCents: incomeTotal,
        isIncome: true,
      ));
    }

    // Add expense badge if there's expense
    if (expenseTotal > 0) {
      cellData[date]!.add(AmountBadge(
        amountCents: expenseTotal,
        isIncome: false,
      ));
    }
  }

  return cellData;
});

// Monthly summary provider
final monthlySummaryProvider =
    FutureProvider.family<Map<String, int>, DateTime>((ref, month) async {
  // Watch transactionsProvider và monthStartDayProvider để tự động reload khi có thay đổi
  ref.watch(transactionsProvider);
  final monthStartDay = ref.watch(monthStartDayProvider);

  // Sử dụng cycle dates thay vì calendar month
  final cycleRange = CycleUtils.getCycleRangeForMonth(month, monthStartDay);
  final startDate = cycleRange.start;
  final endDate = cycleRange.end;

  final txnRepo = ref.watch(transactionRepositoryProvider);
  final allTransactions = await txnRepo.getAllTransactions();

  final transactions = allTransactions.where((txn) {
    return txn.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
        txn.dateTime.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  int totalIncome = 0;
  int totalExpense = 0;

  for (final txn in transactions) {
    // Transfers are excluded from both totals.
    if (txn.type == TransactionType.income) {
      totalIncome += txn.amountCents;
    } else if (txn.type == TransactionType.expense) {
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
final transactionGroupsProvider =
    FutureProvider.family<List<TransactionGroup>, DateTime>((ref, month) async {
  // Watch transactionsProvider và monthStartDayProvider để tự động reload khi có thay đổi
  ref.watch(transactionsProvider);
  final monthStartDay = ref.watch(monthStartDayProvider);

  // Sử dụng cycle dates thay vì calendar month
  final cycleRange = CycleUtils.getCycleRangeForMonth(month, monthStartDay);
  final startDate = cycleRange.start;
  final endDate = cycleRange.end;

  final txnRepo = ref.watch(transactionRepositoryProvider);
  final allTransactions = await txnRepo.getAllTransactions();

  final transactions = allTransactions.where((txn) {
    return txn.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
        txn.dateTime.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

  final Map<DateTime, List<TransactionWithCategory>> groups = {};

  for (final txn in transactions) {
    final date =
        DateTime(txn.dateTime.year, txn.dateTime.month, txn.dateTime.day);

    if (!groups.containsKey(date)) {
      groups[date] = [];
    }

    // Get category name. Transfers carry no category, so they get a neutral
    // placeholder; the UI renders them as "Wallet A → Wallet B" instead.
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final categories = await categoryRepo.getAllCategories();
    final category =
        categories.where((c) => c.id == txn.categoryId).firstOrNull;

    groups[date]!.add(TransactionWithCategory(
      transaction: txn,
      categoryName: category?.name ?? '',
      categoryIconName: category?.iconName ?? 'swap_horiz',
      categoryColorValue: category?.colorValue ?? kDefaultCategoryColorValue,
    ));
  }

  final result = <TransactionGroup>[];

  for (final entry in groups.entries) {
    final dayTransactions = entry.value;
    int totalIncome = 0;
    int totalExpense = 0;

    for (final txnWithCat in dayTransactions) {
      // Transfers are excluded from both totals.
      if (txnWithCat.transaction.type == TransactionType.income) {
        totalIncome += txnWithCat.transaction.amountCents;
      } else if (txnWithCat.transaction.type == TransactionType.expense) {
        totalExpense += txnWithCat.transaction.amountCents;
      }
    }

    result.add(TransactionGroup(
      date: entry.key,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactions: dayTransactions,
    ));
  }

  result.sort((a, b) => b.date.compareTo(a.date));

  return result;
});

// Transaction list notifier
final transactionListNotifierProvider =
    StateNotifierProvider<TransactionListNotifier, AsyncValue<void>>((ref) {
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

  void goToMonth(DateTime month) {
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(month.year, month.month, 1);
    ref.read(selectedDateProvider.notifier).state = null;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      await syncCurrentWorkspaceData(ref);

      final month = ref.read(selectedMonthProvider);
      // Invalidate all report providers to force reload
      ref.invalidate(calendarDataProvider(month));
      ref.invalidate(monthlySummaryProvider(month));
      ref.invalidate(transactionGroupsProvider(month));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void selectDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
  }

  Future<void> deleteTransaction(String transactionId) async {
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
  final int totalIncome;
  final int totalExpense;
  final List<TransactionWithCategory> transactions;

  TransactionGroup({
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
  });
}

// Transaction with category name
class TransactionWithCategory {
  final Transaction transaction;
  final String categoryName;
  final String categoryIconName;
  final int categoryColorValue;

  TransactionWithCategory({
    required this.transaction,
    required this.categoryName,
    required this.categoryIconName,
    required this.categoryColorValue,
  });
}
