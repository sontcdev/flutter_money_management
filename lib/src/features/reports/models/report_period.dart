import 'package:intl/intl.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';

enum ReportPeriodUnit { week, month, year }

typedef ReportDateRange = ({DateTime start, DateTime end});

class ReportPeriod {
  final ReportPeriodUnit unit;
  final DateTime anchor;

  const ReportPeriod(this.unit, this.anchor);

  factory ReportPeriod.current(ReportPeriodUnit unit) =>
      ReportPeriod(unit, DateTime.now());

  ReportDateRange range(int monthStartDay) {
    switch (unit) {
      case ReportPeriodUnit.week:
        final start = DateTime(
          anchor.year,
          anchor.month,
          anchor.day - (anchor.weekday - DateTime.monday),
        );
        return (
          start: start,
          end: DateTime(start.year, start.month, start.day + 6, 23, 59, 59),
        );
      case ReportPeriodUnit.month:
        return CycleUtils.getCycleRangeForDate(anchor, monthStartDay);
      case ReportPeriodUnit.year:
        return (
          start: DateTime(anchor.year, 1, 1),
          end: DateTime(anchor.year, 12, 31, 23, 59, 59),
        );
    }
  }

  ReportPeriod previous(int monthStartDay) {
    switch (unit) {
      case ReportPeriodUnit.week:
        return ReportPeriod(
          unit,
          DateTime(anchor.year, anchor.month, anchor.day - 7),
        );
      case ReportPeriodUnit.month:
        final start = range(monthStartDay).start;
        return ReportPeriod(
          unit,
          DateTime(start.year, start.month, start.day - 1),
        );
      case ReportPeriodUnit.year:
        return ReportPeriod(unit, DateTime(anchor.year - 1));
    }
  }

  ReportPeriod next(int monthStartDay) {
    switch (unit) {
      case ReportPeriodUnit.week:
        return ReportPeriod(
          unit,
          DateTime(anchor.year, anchor.month, anchor.day + 7),
        );
      case ReportPeriodUnit.month:
        final end = range(monthStartDay).end;
        return ReportPeriod(unit, DateTime(end.year, end.month, end.day + 1));
      case ReportPeriodUnit.year:
        return ReportPeriod(unit, DateTime(anchor.year + 1));
    }
  }

  bool hasNext(int monthStartDay, DateTime now) =>
      !next(monthStartDay).range(monthStartDay).start.isAfter(now);

  bool contains(DateTime value, int monthStartDay) {
    final bounds = range(monthStartDay);
    return !value.isBefore(bounds.start) &&
        value.isBefore(bounds.end.add(const Duration(seconds: 1)));
  }

  String label(AppLocalizations l10n, int monthStartDay) {
    final bounds = range(monthStartDay);
    switch (unit) {
      case ReportPeriodUnit.week:
        final format = DateFormat.MMMd(l10n.localeName);
        return '${format.format(bounds.start)} – ${format.format(bounds.end)}';
      case ReportPeriodUnit.month:
        return DateFormat.yMMMM(l10n.localeName).format(bounds.end);
      case ReportPeriodUnit.year:
        return '${l10n.year} ${anchor.year}';
    }
  }

  String? caption(int monthStartDay) {
    if (unit != ReportPeriodUnit.month || monthStartDay.clamp(1, 28) == 1) {
      return null;
    }
    final bounds = range(monthStartDay);
    return CycleUtils.getCycleLabel(bounds.start, bounds.end);
  }
}
