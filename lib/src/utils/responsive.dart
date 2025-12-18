import 'package:flutter/material.dart';

/// Responsive utility class for auto-dimension based on screen size
class Responsive {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;
  
  // Design reference (iPhone 14 Pro: 393 x 852)
  static const double _designWidth = 393;
  static const double _designHeight = 852;

  /// Initialize responsive dimensions
  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _blockSizeHorizontal = _screenWidth / 100;
    _blockSizeVertical = _screenHeight / 100;
  }

  /// Get screen width
  static double get screenWidth => _screenWidth;

  /// Get screen height
  static double get screenHeight => _screenHeight;

  /// Calculate responsive width based on design width
  /// Example: width(100) returns 100 scaled to current screen
  static double width(double designWidth) {
    return (designWidth / _designWidth) * _screenWidth;
  }

  /// Calculate responsive height based on design height
  /// Example: height(50) returns 50 scaled to current screen
  static double height(double designHeight) {
    return (designHeight / _designHeight) * _screenHeight;
  }

  /// Calculate responsive font size
  /// Example: sp(16) returns 16 scaled to current screen
  /// Automatically applies larger scale on tablets
  static double sp(double fontSize) {
    double scaleFactor = _screenWidth / _designWidth;
    
    // Apply additional scale for tablets to make text more readable
    if (isTablet) {
      scaleFactor *= 1.3; // 30% larger on tablets
    } else if (isLargeTablet) {
      scaleFactor *= 1.5; // 50% larger on large tablets
    }
    
    return fontSize * scaleFactor;
  }

  /// Get responsive padding/margin value
  /// Example: padding(16) returns 16 scaled to current screen
  /// Automatically applies larger scale on tablets
  static double padding(double value) {
    double scaleFactor = _screenWidth / _designWidth;
    
    // Apply additional scale for tablets
    if (isTablet) {
      scaleFactor *= 1.2; // 20% larger on tablets
    } else if (isLargeTablet) {
      scaleFactor *= 1.4; // 40% larger on large tablets
    }
    
    return value * scaleFactor;
  }

  /// Check if device is a small phone (width < 375)
  static bool get isSmallPhone => _screenWidth < 375;

  /// Check if device is a tablet (width >= 600)
  static bool get isTablet => _screenWidth >= 600;

  /// Check if device is a large tablet (width >= 900)
  static bool get isLargeTablet => _screenWidth >= 900;

  /// Get responsive value based on screen size
  /// Example: responsive(small: 12, medium: 14, large: 16)
  static T responsive<T>({
    required T small,
    T? medium,
    T? large,
  }) {
    if (_screenWidth >= 900 && large != null) {
      return large;
    } else if (_screenWidth >= 600 && medium != null) {
      return medium;
    } else {
      return small;
    }
  }

  /// Get percentage of screen width
  /// Example: widthPercent(50) returns 50% of screen width
  static double widthPercent(double percent) {
    return _blockSizeHorizontal * percent;
  }

  /// Get percentage of screen height
  /// Example: heightPercent(50) returns 50% of screen height
  static double heightPercent(double percent) {
    return _blockSizeVertical * percent;
  }
}
