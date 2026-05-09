// path: lib/src/utils/cycle_utils.dart

/// Utility class để tính toán chu kỳ tháng dựa trên ngày bắt đầu của tháng
class CycleUtils {
  /// Lấy khoảng thời gian chu kỳ hiện tại
  /// [monthStartDay] là ngày bắt đầu của tháng (1-31)
  ///
  /// Ví dụ: monthStartDay = 25
  /// - Nếu hôm nay là 26/12/2024 → chu kỳ từ 25/12/2024 đến 24/01/2025
  /// - Nếu hôm nay là 20/12/2024 → chu kỳ từ 25/11/2024 đến 24/12/2024
  static ({DateTime start, DateTime end}) getCurrentCycleRange(
      int monthStartDay) {
    return getCycleRangeForDate(DateTime.now(), monthStartDay);
  }

  /// Lấy khoảng thời gian chu kỳ chứa ngày [date]
  static ({DateTime start, DateTime end}) getCycleRangeForDate(
      DateTime date, int monthStartDay) {
    // Đảm bảo monthStartDay trong khoảng hợp lệ
    final startDay = monthStartDay.clamp(
        1, 28); // Clamp to 28 to avoid month overflow issues

    DateTime cycleStart;
    DateTime cycleEnd;

    if (date.day >= startDay) {
      // Ngày hiện tại >= ngày bắt đầu → đang trong chu kỳ bắt đầu từ tháng này
      cycleStart = DateTime(date.year, date.month, startDay);
      // Kết thúc là ngày (startDay - 1) của tháng sau
      final nextMonth = DateTime(date.year, date.month + 1, 1);
      cycleEnd =
          DateTime(nextMonth.year, nextMonth.month, startDay - 1, 23, 59, 59);
      // Xử lý trường hợp startDay = 1, cycleEnd sẽ là ngày cuối tháng hiện tại
      if (startDay == 1) {
        cycleEnd = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
      }
    } else {
      // Ngày hiện tại < ngày bắt đầu → đang trong chu kỳ bắt đầu từ tháng trước
      final prevMonth = DateTime(date.year, date.month - 1, 1);
      cycleStart = DateTime(prevMonth.year, prevMonth.month, startDay);
      // Kết thúc là ngày (startDay - 1) của tháng hiện tại
      cycleEnd = DateTime(date.year, date.month, startDay - 1, 23, 59, 59);
      // Xử lý trường hợp startDay = 1, cycleEnd sẽ là ngày cuối tháng trước
      if (startDay == 1) {
        cycleEnd = DateTime(date.year, date.month, 0, 23, 59, 59);
      }
    }

    return (start: cycleStart, end: cycleEnd);
  }

  /// Lấy khoảng thời gian chu kỳ cho tháng được hiển thị trong Calendar
  /// Khác với getCycleRangeForDate(), method này tính cycle dựa trên tháng được chọn
  /// Khi user chọn "Tháng 12/2025" với monthStartDay = 15:
  /// → Chu kỳ từ 15/12/2025 đến 14/1/2026
  static ({DateTime start, DateTime end}) getCycleRangeForMonth(
      DateTime month, int monthStartDay) {
    final startDay = monthStartDay.clamp(1, 28);

    // Ngày bắt đầu luôn là ngày startDay của tháng được chọn
    final cycleStart = DateTime(month.year, month.month, startDay);

    DateTime cycleEnd;
    if (startDay == 1) {
      // Nếu startDay = 1, kết thúc là ngày cuối tháng
      cycleEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    } else {
      // Kết thúc là ngày (startDay - 1) của tháng sau
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      cycleEnd =
          DateTime(nextMonth.year, nextMonth.month, startDay - 1, 23, 59, 59);
    }

    return (start: cycleStart, end: cycleEnd);
  }

  /// Lấy label hiển thị cho chu kỳ
  static String getCycleLabel(DateTime start, DateTime end) {
    final startStr =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}';
    final endStr =
        '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }
}
