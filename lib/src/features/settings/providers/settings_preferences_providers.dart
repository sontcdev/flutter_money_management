import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

final budgetPeriodProvider =
    StateNotifierProvider<BudgetPeriodNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BudgetPeriodNotifier(prefs);
});

class BudgetPeriodNotifier extends StateNotifier<String> {
  static const String _periodKey = 'budget_period';
  final SharedPreferences _prefs;

  BudgetPeriodNotifier(this._prefs) : super('monthly') {
    _loadPeriod();
  }

  void _loadPeriod() {
    final period = _prefs.getString(_periodKey);
    if (period != null) {
      state = period;
    }
  }

  Future<void> setPeriod(String period) async {
    await _prefs.setString(_periodKey, period);
    state = period;
  }
}

final monthStartDayProvider =
    StateNotifierProvider<MonthStartDayNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MonthStartDayNotifier(prefs);
});

class MonthStartDayNotifier extends StateNotifier<int> {
  static const String _startDayKey = 'month_start_day';
  final SharedPreferences _prefs;

  MonthStartDayNotifier(this._prefs) : super(1) {
    _loadStartDay();
  }

  void _loadStartDay() {
    final startDay = _prefs.getInt(_startDayKey);
    if (startDay != null) {
      state = startDay;
    }
  }

  Future<void> setStartDay(int day) async {
    final clampedDay = day.clamp(1, 31);
    await _prefs.setInt(_startDayKey, clampedDay);
    state = clampedDay;
  }
}
