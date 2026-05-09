import 'package:flutter/services.dart';

/// Haptic feedback utilities for better user interaction
class AppHaptics {
  /// Light impact - for subtle interactions like taps
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for standard interactions
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection - for toggles and selections
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Success - for successful operations
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Error - for errors or warnings
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  /// Vibrate - for notifications
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
