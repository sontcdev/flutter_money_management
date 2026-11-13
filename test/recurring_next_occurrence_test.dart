import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_next_occurrence.dart';

void main() {
  test('weekly returns the next matching weekday on or after today', () {
    // 2026-11-10 is a Tuesday; target Friday.
    final result = nextRecurringOccurrence(
      startDate: DateTime(2026, 1, 1),
      frequency: RecurringFrequency.weekly,
      intervalCount: 1,
      dayOfWeek: DateTime.friday,
      today: DateTime(2026, 11, 10),
    );
    expect(result, DateTime(2026, 11, 13));
  });

  test('monthly day 31 clamps to month end', () {
    final result = nextRecurringOccurrence(
      startDate: DateTime(2026, 1, 31),
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      dayOfMonth: 31,
      today: DateTime(2026, 2, 1),
    );
    expect(result, DateTime(2026, 2, 28));
  });

  test('yearly Feb 29 falls back to Feb 28 in non-leap year', () {
    final result = nextRecurringOccurrence(
      startDate: DateTime(2028, 2, 29),
      frequency: RecurringFrequency.yearly,
      intervalCount: 1,
      dayOfMonth: 29,
      monthOfYear: 2,
      today: DateTime(2028, 3, 1),
    );
    expect(result, DateTime(2029, 2, 28));
  });

  test('interval greater than one skips periods', () {
    final result = nextRecurringOccurrence(
      startDate: DateTime(2026, 1, 15),
      frequency: RecurringFrequency.monthly,
      intervalCount: 3,
      dayOfMonth: 15,
      today: DateTime(2026, 2, 1),
    );
    expect(result, DateTime(2026, 4, 15));
  });

  test('returns null when the next occurrence is after the end date', () {
    final result = nextRecurringOccurrence(
      startDate: DateTime(2026, 1, 15),
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      dayOfMonth: 15,
      endDate: DateTime(2026, 3, 1),
      today: DateTime(2026, 11, 10),
    );
    expect(result, isNull);
  });

  test('occurrence today is included', () {
    final result = nextRecurringOccurrence(
      startDate: DateTime(2026, 11, 10),
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      dayOfMonth: 10,
      today: DateTime(2026, 11, 10, 15),
    );
    expect(result, DateTime(2026, 11, 10));
  });

  test('finds occurrence beyond 1000 intervals', () {
    final result = nextRecurringOccurrence(
      startDate: DateTime(2000, 1, 1),
      frequency: RecurringFrequency.weekly,
      intervalCount: 1,
      dayOfWeek: DateTime.saturday,
      today: DateTime(2026, 11, 10),
    );
    expect(result, DateTime(2026, 11, 14));
  });

  test('long history still honors end date', () {
    final result = nextRecurringOccurrence(
      startDate: DateTime(2000, 1, 1),
      frequency: RecurringFrequency.weekly,
      intervalCount: 1,
      dayOfWeek: DateTime.saturday,
      endDate: DateTime(2026, 11, 1),
      today: DateTime(2026, 11, 10),
    );
    expect(result, isNull);
  });
}
