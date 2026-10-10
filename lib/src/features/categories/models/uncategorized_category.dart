import 'package:flutter_money_management/src/features/categories/models/category.dart';

Category uncategorizedCategory(String id, String name) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return Category(
    id: id,
    name: name,
    iconName: 'more_horiz',
    colorValue: 0,
    createdAt: epoch,
    updatedAt: epoch,
  );
}
