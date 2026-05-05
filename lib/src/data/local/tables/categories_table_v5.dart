// path: lib/src/data/local/tables/categories_table_v5.dart

import 'package:drift/drift.dart';
import 'workspaces_table.dart';
import 'profiles_table.dart';

@DataClassName('CategoryEntityV5')
class CategoriesV5 extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get workspaceId => text().references(Workspaces, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get normalizedName => text()();
  TextColumn get type => text()(); // 'expense' or 'income'
  TextColumn get iconName => text()();
  IntColumn get colorValue => integer()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdByUserId => text().references(Profiles, #id)();
  TextColumn get updatedByUserId => text().references(Profiles, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedByUserId => text().nullable().references(Profiles, #id)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get metadata => text().withDefault(const Constant('{}'))(); // JSON string
  
  // Sync fields
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
