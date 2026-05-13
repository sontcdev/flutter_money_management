import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';

class RecurringScheduleCalculator {
  const RecurringScheduleCalculator._();

  static DateTime normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime calculateFirstOccurrence({
    required DateTime startDate,
    required RecurringFrequency frequency,
    required int intervalCount,
    int? dayOfMonth,
    int? dayOfWeek,
    int? monthOfYear,
  }) {
    final normalizedStart = normalizeDate(startDate);
    switch (frequency) {
      case RecurringFrequency.weekly:
        final targetWeekday = dayOfWeek ?? normalizedStart.weekday;
        final delta = (targetWeekday - normalizedStart.weekday + 7) % 7;
        return normalizedStart.add(Duration(days: delta));
      case RecurringFrequency.monthly:
        final targetDay = dayOfMonth ?? normalizedStart.day;
        final inStartMonth = _withDayInMonth(
          normalizedStart.year,
          normalizedStart.month,
          targetDay,
        );
        if (!inStartMonth.isBefore(normalizedStart)) {
          return inStartMonth;
        }
        return addInterval(
          current: inStartMonth,
          frequency: frequency,
          intervalCount: intervalCount,
          dayOfMonth: targetDay,
        );
      case RecurringFrequency.yearly:
        final targetMonth = monthOfYear ?? normalizedStart.month;
        final targetDay = dayOfMonth ?? normalizedStart.day;
        final inStartYear = _withDayInMonth(
          normalizedStart.year,
          targetMonth,
          targetDay,
        );
        if (!inStartYear.isBefore(normalizedStart)) {
          return inStartYear;
        }
        return addInterval(
          current: inStartYear,
          frequency: frequency,
          intervalCount: intervalCount,
          dayOfMonth: targetDay,
          monthOfYear: targetMonth,
        );
    }
  }

  static DateTime addInterval({
    required DateTime current,
    required RecurringFrequency frequency,
    required int intervalCount,
    int? dayOfMonth,
    int? monthOfYear,
  }) {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return normalizeDate(current).add(Duration(days: 7 * intervalCount));
      case RecurringFrequency.monthly:
        final target = DateTime(current.year, current.month + intervalCount, 1);
        return _withDayInMonth(
          target.year,
          target.month,
          dayOfMonth ?? current.day,
        );
      case RecurringFrequency.yearly:
        final targetYear = current.year + intervalCount;
        return _withDayInMonth(
          targetYear,
          monthOfYear ?? current.month,
          dayOfMonth ?? current.day,
        );
    }
  }

  static DateTime _withDayInMonth(int year, int month, int day) {
    final maxDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, maxDay);
    return DateTime(year, month, safeDay);
  }
}
