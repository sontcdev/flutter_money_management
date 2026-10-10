import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/features/reports/models/report_period.dart';

void main() {
  test('week range runs Monday to Sunday', () {
    final period = ReportPeriod(ReportPeriodUnit.week, DateTime(2025, 11, 13));
    final range = period.range(1);
    expect(range.start, DateTime(2025, 11, 10));
    expect(range.end, DateTime(2025, 11, 16, 23, 59, 59));
    expect(period.previous(1).range(1).start, DateTime(2025, 11, 3));
    expect(period.next(1).range(1).start, DateTime(2025, 11, 17));
  });

  test('calendar month range covers the whole month', () {
    final period = ReportPeriod(ReportPeriodUnit.month, DateTime(2025, 2, 10));
    final range = period.range(1);
    expect(range.start, DateTime(2025, 2, 1));
    expect(period.contains(DateTime(2025, 2, 28, 23, 59, 59), 1), isTrue);
    expect(period.contains(DateTime(2025, 3, 1), 1), isFalse);
    expect(period.previous(1).range(1).start, DateTime(2025, 1, 1));
    expect(period.next(1).range(1).start, DateTime(2025, 3, 1));
  });

  test('custom cycle months are contiguous', () {
    final period = ReportPeriod(ReportPeriodUnit.month, DateTime(2025, 11, 10));
    final range = period.range(25);
    final previous = period.previous(25).range(25);
    final next = period.next(25).range(25);
    expect(range.start.day, 25);
    expect(previous.end.add(const Duration(seconds: 1)), range.start);
    expect(range.end.add(const Duration(seconds: 1)), next.start);
  });

  test('year range and navigation', () {
    final period = ReportPeriod(ReportPeriodUnit.year, DateTime(2024, 6, 1));
    expect(period.range(1).start, DateTime(2024, 1, 1));
    expect(period.range(1).end, DateTime(2024, 12, 31, 23, 59, 59));
    expect(period.previous(1).anchor.year, 2023);
    expect(period.next(1).anchor.year, 2025);
  });

  test('hasNext is false for the current period', () {
    final now = DateTime(2025, 11, 13);
    for (final unit in ReportPeriodUnit.values) {
      expect(ReportPeriod(unit, now).hasNext(1, now), isFalse);
      expect(ReportPeriod(unit, now).previous(1).hasNext(1, now), isTrue);
    }
  });
}
