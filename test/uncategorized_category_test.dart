import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/features/categories/models/uncategorized_category.dart';

void main() {
  test('keeps the missing category id and uses the given name', () {
    final category = uncategorizedCategory('deleted-cat', 'Uncategorized');

    expect(category.id, 'deleted-cat');
    expect(category.name, 'Uncategorized');
  });

  test('uses the neutral fallback icon and colour', () {
    final category = uncategorizedCategory('deleted-cat', 'Uncategorized');

    expect(category.iconName, 'more_horiz');
    expect(category.colorValue, 0);
  });
}
