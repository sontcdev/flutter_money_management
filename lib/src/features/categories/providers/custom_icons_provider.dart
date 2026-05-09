import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

final customIconsProvider =
    StateNotifierProvider<CustomIconsNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomIconsNotifier(prefs);
});

class CustomIconsNotifier extends StateNotifier<List<String>> {
  static const String _customIconsKey = 'custom_icons';
  final SharedPreferences _prefs;

  CustomIconsNotifier(this._prefs) : super([]) {
    _loadCustomIcons();
  }

  void _loadCustomIcons() {
    final icons = _prefs.getStringList(_customIconsKey) ?? [];
    state = icons;
  }

  Future<bool> addIcon(String iconKey) async {
    if (state.contains(iconKey)) {
      return false;
    }

    final newList = [...state, iconKey];
    await _prefs.setStringList(_customIconsKey, newList);
    state = newList;
    return true;
  }

  Future<void> removeIcon(String iconKey) async {
    final newList = state.where((icon) => icon != iconKey).toList();
    await _prefs.setStringList(_customIconsKey, newList);
    state = newList;
  }
}
