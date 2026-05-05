// path: lib/src/data/local/tables/budgets_table_v5.dart

import 'package:drift/drift.dart';
import 'workspaces_table.dart';
import 'categories_table_v5.dart';
import 'profiles_table.dart';

@DataClassName('BudgetEntityV5')
class BudgetsV5 extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get workspaceId => text().references(Workspaces, #id)();
  TextColumn get categoryId => text().references(CategoriesV5, #id)();
  TextColumn get name => text().nullable()();
  TextColumn get periodType => text()(); // 'monthly', 'yearly', 'custom'
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  IntColumn get limitMinor => integer()(); // Limit in minor units (cents)
  TextColumn get currencyCode => text()();
  BoolColumn get allowOverdraft => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
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
  
  // Note: consumedCents is calculated, not stored
  // Note: overdraftCents is calculated, not stored

  @override
  Set<Column> get primaryKey => {id};
}
