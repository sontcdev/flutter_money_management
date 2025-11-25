// path: lib/src/theme/report_theme.dart

import 'package:flutter/material.dart';

class ReportTheme {
  // Colors matching the sample image
  static const Color incomeColor = Color(0xFF2196F3); // Blue
  static const Color expenseColor = Color(0xFFFF6B3D); // Orange-red
  static const Color selectedDateBackground = Color(0xFFFFE4E8); // Pale pink
  static const Color todayBackground = Color(0xFFF5F5F5); // Light gray
  static const Color groupHeaderBackground = Color(0xFFF8F9FA); // Very light gray

  // Text styles
  static const TextStyle monthLabelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle dateLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle amountLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle summaryLabelStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  static const TextStyle summaryAmountStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle groupDateStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle transactionTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle transactionSubtitleStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  static const TextStyle transactionAmountStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  // Spacing constants
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 12.0;
  static const double cardBorderRadius = 12.0;
  static const double cellBorderRadius = 8.0;
  static const double iconSize = 24.0;
  static const double categoryIconSize = 40.0;

  // Calendar grid spacing
  static const double cellHeight = 70.0;
  static const double cellMargin = 2.0;
  static const double weekdayHeaderHeight = 30.0;

  // Transaction list spacing
  static const double transactionItemHeight = 60.0;
  static const double groupHeaderHeight = 44.0;

  // Get color for amount display
  static Color getAmountColor(bool isIncome, bool isPositive) {
    if (isIncome) {
      return incomeColor;
    } else {
      return expenseColor;
    }
  }

  // Get color for net amount
  static Color getNetColor(int netAmount) {
    return netAmount >= 0 ? incomeColor : expenseColor;
  }

  // Background decoration for selected items
  static BoxDecoration selectedDecoration = BoxDecoration(
    color: selectedDateBackground,
    borderRadius: BorderRadius.circular(cellBorderRadius),
  );

  // Background decoration for today
  static BoxDecoration todayDecoration = BoxDecoration(
    color: todayBackground,
    borderRadius: BorderRadius.circular(cellBorderRadius),
    border: Border.all(color: incomeColor.withValues(alpha: 0.3), width: 1),
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Category icon decoration
  static BoxDecoration categoryIconDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    );
  }

  // Amount badge decoration
  static BoxDecoration amountBadgeDecoration(bool isIncome) {
    return BoxDecoration(
      color: isIncome ? incomeColor.withValues(alpha: 0.15) : expenseColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    );
  }
}

