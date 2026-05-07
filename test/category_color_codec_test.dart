import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/utils/category_color_codec.dart';

void main() {
  group('encodeCategoryColor', () {
    test('encodes default gray to uppercase hex', () {
      expect(encodeCategoryColor(0xFF9E9E9E), 'FF9E9E9E');
    });

    test('encodes bright red to uppercase hex', () {
      expect(encodeCategoryColor(0xFFFD3C4A), 'FFFD3C4A');
    });

    test('falls back for non-positive values', () {
      expect(encodeCategoryColor(0), kDefaultCategoryColorHex);
    });
  });

  group('decodeCategoryColor', () {
    test('decodes uppercase hex strings', () {
      expect(decodeCategoryColor('FF9E9E9E'), 0xFF9E9E9E);
      expect(decodeCategoryColor('FFFD3C4A'), 0xFFFD3C4A);
    });

    test('decodes lowercase hex strings after normalization', () {
      expect(decodeCategoryColor('ff9e9e9e'), 0xFF9E9E9E);
    });

    test('supports legacy integer values during rollout', () {
      expect(decodeCategoryColor(0xFF9E9E9E), 0xFF9E9E9E);
    });

    test('falls back for invalid input', () {
      expect(decodeCategoryColor('invalid'), kDefaultCategoryColorValue);
      expect(decodeCategoryColor(null), kDefaultCategoryColorValue);
      expect(decodeCategoryColor(-1), kDefaultCategoryColorValue);
    });
  });
}
