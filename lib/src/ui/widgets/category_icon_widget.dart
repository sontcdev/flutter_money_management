// path: lib/src/ui/widgets/category_icon_widget.dart

import 'package:flutter/material.dart';
import '../../utils/category_icons.dart';

/// Widget hiển thị icon của danh mục
/// Hỗ trợ cả Material Icons (icon name) và emoji (legacy)
class CategoryIconWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const CategoryIconWidget({
    super.key,
    required this.iconName,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem có phải Material Icon không
    if (CategoryIcons.isValidIconName(iconName)) {
      return Icon(
        CategoryIcons.getIcon(iconName),
        size: size,
        color: color,
      );
    }
    
    // Fallback: hiển thị emoji (legacy support)
    return Text(
      iconName,
      style: TextStyle(fontSize: size * 0.9),
    );
  }
}

/// Default color for categories without a valid color value
const int kDefaultCategoryColorValue = 0xFF9E9E9E; // Light gray (Colors.grey)

/// Helper function to get category color with fallback to light gray
Color getCategoryColor(int colorValue) {
  if (colorValue <= 0) {
    return const Color(kDefaultCategoryColorValue);
  }
  return Color(colorValue);
}
