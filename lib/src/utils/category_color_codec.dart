// path: lib/src/utils/category_color_codec.dart

import 'app_logger.dart';

const int kDefaultCategoryColorValue = 0xFF9E9E9E;
const String kDefaultCategoryColorHex = 'FF9E9E9E';

final RegExp _categoryColorHexPattern = RegExp(r'^[0-9A-F]{8}$');

String encodeCategoryColor(int value) {
  final normalizedValue = value > 0 ? value : kDefaultCategoryColorValue;
  return (normalizedValue & 0xFFFFFFFF)
      .toRadixString(16)
      .padLeft(8, '0')
      .toUpperCase();
}

int decodeCategoryColor(dynamic raw) {
  if (raw is String) {
    final normalized = raw.trim().toUpperCase();
    if (_categoryColorHexPattern.hasMatch(normalized)) {
      return int.tryParse(normalized, radix: 16) ?? kDefaultCategoryColorValue;
    }
    AppLogger.warn(
      'Invalid category color string, using default color',
      name: 'MM.Utils.CategoryColor',
    );
    return kDefaultCategoryColorValue;
  }

  if (raw is int) {
    if (raw <= 0) {
      AppLogger.warn(
        'Non-positive category color int, using default color',
        name: 'MM.Utils.CategoryColor',
      );
    }
    return raw > 0 ? (raw & 0xFFFFFFFF) : kDefaultCategoryColorValue;
  }

  if (raw is num) {
    final value = raw.toInt();
    if (value <= 0) {
      AppLogger.warn(
        'Non-positive category color number, using default color',
        name: 'MM.Utils.CategoryColor',
      );
    }
    return value > 0 ? (value & 0xFFFFFFFF) : kDefaultCategoryColorValue;
  }

  AppLogger.warn(
    'Unsupported category color value, using default color',
    name: 'MM.Utils.CategoryColor',
  );
  return kDefaultCategoryColorValue;
}
