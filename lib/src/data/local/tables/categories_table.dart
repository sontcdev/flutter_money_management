// path: lib/src/data/local/tables/categories_table.dart

import 'package:drift/drift.dart';

@DataClassName('CategoryEntity')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get iconName => text()();
  IntColumn get colorValue => integer()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

