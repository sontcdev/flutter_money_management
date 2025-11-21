// path: lib/src/services/report_service.dart
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';

class CategoryBreakdown {
  final String categoryId;
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
  final int totalCents;
  final List<CategoryBreakdown> breakdown;

  MonthlyReport({
    required this.year,
    required this.month,
    required this.totalCents,
    required this.breakdown,
  });
}

class YearlyReport {
  final int year;
  final int totalCents;
  final List<CategoryBreakdown> breakdown;

  YearlyReport({
    required this.year,
    required this.totalCents,
    required this.breakdown,
  });
}

class ReportService {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;

  ReportService(this._transactionRepository, this._categoryRepository);

  Future<MonthlyReport> monthlyReport(int year, int month) async {
    final totalCents = await _transactionRepository.getTotalByMonth(year, month);
    
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final categories = await _categoryRepository.getAllCategories();
    final breakdown = <CategoryBreakdown>[];
    
    for (final category in categories) {
      final amountCents = await _transactionRepository.getTotalByCategory(
          category.id, start, end);
      if (amountCents > 0) {
        final percentage = totalCents > 0
            ? (amountCents / totalCents) * 100
            : 0.0;
        breakdown.add(CategoryBreakdown(
          categoryId: category.id,
          categoryName: category.name,
          amountCents: amountCents,
          percentage: percentage,
        ));
      }
    }
    
    breakdown.sort((a, b) => b.amountCents.compareTo(a.amountCents));
    
    return MonthlyReport(
      year: year,
      month: month,
      totalCents: totalCents,
      breakdown: breakdown,
    );
  }

  Future<YearlyReport> yearlyReport(int year) async {
    final totalCents = await _transactionRepository.getTotalByYear(year);
    
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    
    final categories = await _categoryRepository.getAllCategories();
    final breakdown = <CategoryBreakdown>[];
    
    for (final category in categories) {
      final amountCents = await _transactionRepository.getTotalByCategory(
          category.id, start, end);
      if (amountCents > 0) {
        final percentage = totalCents > 0
            ? (amountCents / totalCents) * 100
            : 0.0;
        breakdown.add(CategoryBreakdown(
          categoryId: category.id,
          categoryName: category.name,
          amountCents: amountCents,
          percentage: percentage,
        ));
      }
    }
    
    breakdown.sort((a, b) => b.amountCents.compareTo(a.amountCents));
    
    return YearlyReport(
      year: year,
      totalCents: totalCents,
      breakdown: breakdown,
    );
  }
}

