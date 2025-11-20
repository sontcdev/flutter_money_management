// path: lib/src/services/report_service.dart

import '../data/local/app_database.dart';

class CategoryBreakdown {
  final int categoryId;
  final String categoryName;
  final int amountCents;
  final double percentage;

  CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amountCents,
    required this.percentage,
  });
}

class MonthlyReport {
  final int year;
  final int month;
  final int totalIncomeCents;
  final int totalExpenseCents;
  final int netCents;
  final List<CategoryBreakdown> incomeBreakdown;
  final List<CategoryBreakdown> expenseBreakdown;

  MonthlyReport({
    required this.year,
    required this.month,
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.netCents,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
  });
}

class YearlyReport {
  final int year;
  final int totalIncomeCents;
  final int totalExpenseCents;
  final int netCents;
  final List<CategoryBreakdown> incomeBreakdown;
  final List<CategoryBreakdown> expenseBreakdown;
  final List<MonthlyReport> monthlyReports;

  YearlyReport({
    required this.year,
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.netCents,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.monthlyReports,
  });
}

class ReportService {
  final AppDatabase _db;

  ReportService(this._db);

  Future<MonthlyReport> monthlyReport(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final totalIncome = await _db.transactionDao
        .sumAmountByDateRange(start, end, type: 'income');
    final totalExpense = await _db.transactionDao
        .sumAmountByDateRange(start, end, type: 'expense');

    final incomeByCategory = await _db.transactionDao
        .sumAmountByCategoryInRange(start, end, 'income');
    final expenseByCategory = await _db.transactionDao
        .sumAmountByCategoryInRange(start, end, 'expense');

    final incomeBreakdown = await _buildCategoryBreakdown(
        incomeByCategory, totalIncome);
    final expenseBreakdown = await _buildCategoryBreakdown(
        expenseByCategory, totalExpense);

    return MonthlyReport(
      year: year,
      month: month,
      totalIncomeCents: totalIncome,
      totalExpenseCents: totalExpense,
      netCents: totalIncome - totalExpense,
      incomeBreakdown: incomeBreakdown,
      expenseBreakdown: expenseBreakdown,
    );
  }

  Future<YearlyReport> yearlyReport(int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);

    final totalIncome = await _db.transactionDao
        .sumAmountByDateRange(start, end, type: 'income');
    final totalExpense = await _db.transactionDao
        .sumAmountByDateRange(start, end, type: 'expense');

    final incomeByCategory = await _db.transactionDao
        .sumAmountByCategoryInRange(start, end, 'income');
    final expenseByCategory = await _db.transactionDao
        .sumAmountByCategoryInRange(start, end, 'expense');

    final incomeBreakdown = await _buildCategoryBreakdown(
        incomeByCategory, totalIncome);
    final expenseBreakdown = await _buildCategoryBreakdown(
        expenseByCategory, totalExpense);

    // Generate monthly reports
    final monthlyReports = <MonthlyReport>[];
    for (int month = 1; month <= 12; month++) {
      final report = await monthlyReport(year, month);
      monthlyReports.add(report);
    }

    return YearlyReport(
      year: year,
      totalIncomeCents: totalIncome,
      totalExpenseCents: totalExpense,
      netCents: totalIncome - totalExpense,
      incomeBreakdown: incomeBreakdown,
      expenseBreakdown: expenseBreakdown,
      monthlyReports: monthlyReports,
    );
  }

  Future<List<CategoryBreakdown>> _buildCategoryBreakdown(
      Map<int, int> categoryMap, int total) async {
    final breakdown = <CategoryBreakdown>[];

    for (final entry in categoryMap.entries) {
      final category = await _db.categoryDao.getCategoryById(entry.key);
      final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

      breakdown.add(CategoryBreakdown(
        categoryId: entry.key,
        categoryName: category.name,
        amountCents: entry.value,
        percentage: percentage,
      ));
    }

    // Sort by amount descending
    breakdown.sort((a, b) => b.amountCents.compareTo(a.amountCents));

    return breakdown;
  }
}

