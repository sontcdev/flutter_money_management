// path: lib/src/data/local/tables/categories_table.dart
import 'package:drift/drift.dart';

@DataClassName('CategoryEntity')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text().unique()();
  TextColumn get type => text()(); // 'expense' or 'income'
  TextColumn get colorHex => text().nullable()();
  TextColumn get iconName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Generated code will be in categories_table.g.dart

