// path: lib/src/data/local/tables/transactions_table_v5.dart

import 'package:drift/drift.dart';
import 'workspaces_table.dart';
import 'categories_table_v5.dart';
import 'profiles_table.dart';

@DataClassName('TransactionEntityV5')
class TransactionsV5 extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get workspaceId => text().references(Workspaces, #id)();
  TextColumn get categoryId => text().references(CategoriesV5, #id)();
  IntColumn get amountMinor => integer()(); // Amount in minor units (cents)
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get transactionType => text()(); // 'expense' or 'income'
  DateTimeColumn get transactionAt => dateTime()(); // Business datetime
  TextColumn get note => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // 'manual', 'import', 'system'
  TextColumn get clientReferenceId => text().nullable()(); // Offline ID hint
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
