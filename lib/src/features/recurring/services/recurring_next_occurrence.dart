import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_schedule_calculator.dart';

/// Returns the first occurrence on or after [today], or null when it falls
/// after [endDate] (or the schedule cannot advance).
DateTime? nextRecurringOccurrence({
  required DateTime startDate,
  required RecurringFrequency frequency,
  required int intervalCount,
  required DateTime today,
  int? dayOfMonth,
  int? dayOfWeek,
  int? monthOfYear,
  DateTime? endDate,
}) {
  final interval = intervalCount < 1 ? 1 : intervalCount;
  final normalizedToday = RecurringScheduleCalculator.normalizeDate(today);
  final normalizedEnd = endDate == null
      ? null
      : RecurringScheduleCalculator.normalizeDate(endDate);

  var current = RecurringScheduleCalculator.calculateFirstOccurrence(
    startDate: startDate,
    frequency: frequency,
    intervalCount: interval,
    dayOfMonth: dayOfMonth,
    dayOfWeek: dayOfWeek,
    monthOfYear: monthOfYear,
  );

  while (true) {
    if (normalizedEnd != null && current.isAfter(normalizedEnd)) {
      return null;
    }
    if (!current.isBefore(normalizedToday)) {
      return current;
    }
    final next = RecurringScheduleCalculator.addInterval(
      current: current,
      frequency: frequency,
      intervalCount: interval,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
    );
    // Guard against a non-advancing schedule to avoid an infinite loop.
    if (!next.isAfter(current)) return null;
    current = next;
  }
}
