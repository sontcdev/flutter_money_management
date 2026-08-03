import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Tab navigation enum for type-safe tab management
enum AppTab {
  today,
  activity,
  plan,
  insights,
}

/// Tracks which bottom-navigation tab is currently active in [HomeScreen],
/// so that child screens (e.g. TodayScreen) can request a tab switch.
final currentTabProvider = StateProvider<AppTab>((ref) => AppTab.today);
