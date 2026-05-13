import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_schedule_calculator.dart';

void main() {
  group('RecurringScheduleCalculator', () {
    test('keeps monthly occurrences on last valid day', () {
      final first = RecurringScheduleCalculator.calculateFirstOccurrence(
        startDate: DateTime(2026, 1, 31),
        frequency: RecurringFrequency.monthly,
        intervalCount: 1,
        dayOfMonth: 31,
      );

      final next = RecurringScheduleCalculator.addInterval(
        current: first,
        frequency: RecurringFrequency.monthly,
        intervalCount: 1,
        dayOfMonth: 31,
      );

      expect(first, DateTime(2026, 1, 31));
      expect(next, DateTime(2026, 2, 28));
    });

    test('aligns weekly occurrences to requested weekday', () {
      final first = RecurringScheduleCalculator.calculateFirstOccurrence(
        startDate: DateTime(2026, 5, 12),
        frequency: RecurringFrequency.weekly,
        intervalCount: 1,
        dayOfWeek: DateTime.friday,
      );

      expect(first.weekday, DateTime.friday);
      expect(first, DateTime(2026, 5, 15));
    });

    test('keeps yearly occurrences on same month/day when possible', () {
      final first = RecurringScheduleCalculator.calculateFirstOccurrence(
        startDate: DateTime(2026, 3, 5),
        frequency: RecurringFrequency.yearly,
        intervalCount: 1,
        dayOfMonth: 5,
        monthOfYear: 11,
      );

      final next = RecurringScheduleCalculator.addInterval(
        current: first,
        frequency: RecurringFrequency.yearly,
        intervalCount: 1,
        dayOfMonth: 5,
        monthOfYear: 11,
      );

      expect(first, DateTime(2026, 11, 5));
      expect(next, DateTime(2027, 11, 5));
    });
  });
}
