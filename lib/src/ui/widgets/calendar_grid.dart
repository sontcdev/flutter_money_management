// path: lib/src/ui/widgets/calendar_grid.dart

import 'package:flutter/material.dart';
import 'calendar_date_cell.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, List<AmountBadge>> cellData;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.cellData,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = _generateWeeks();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          _buildWeekdayHeader(context),
          const SizedBox(height: 4),
          ...weeks.map((week) => _buildWeekRow(context, week)),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildWeekRow(BuildContext context, List<DateTime?> week) {
    return Row(
      children: week.map((date) {
        if (date == null) {
          return const Expanded(child: SizedBox(height: 48));
        }

        final badges = cellData[_normalizeDate(date)] ?? [];
        final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);
        final isToday = _isSameDay(date, DateTime.now());

        return Expanded(
          child: CalendarDateCell(
            date: date,
            badges: badges,
            isSelected: isSelected,
            isToday: isToday,
            onTap: () => onDateSelected(date),
          ),
        );
      }).toList(),
    );
  }

  List<List<DateTime?>> _generateWeeks() {
    // Chỉ hiển thị tháng hiện tại
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0); // Ngày cuối của tháng

    final weeks = <List<DateTime?>>[];
    var currentWeek = <DateTime?>[];

    // Fill initial empty cells to start on Monday
    final firstWeekday = startDate.weekday; // 1 = Monday
    for (var i = 1; i < firstWeekday; i++) {
      currentWeek.add(null);
    }

    var current = startDate;
    while (current.isBefore(endDate) || current.day == endDate.day) {
      currentWeek.add(current);

      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }

      current = current.add(const Duration(days: 1));
      
      // Thoát khi đã qua ngày cuối tháng
      if (current.month != month.month) break;
    }

    // Fill remaining cells
    while (currentWeek.isNotEmpty && currentWeek.length < 7) {
      currentWeek.add(null);
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return weeks;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class AmountBadge {
  final int amountCents;
  final bool isIncome;

  AmountBadge({required this.amountCents, required this.isIncome});
}

