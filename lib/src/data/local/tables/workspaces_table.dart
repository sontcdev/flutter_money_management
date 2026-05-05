// path: lib/src/data/local/tables/workspaces_table.dart

import 'package:drift/drift.dart';
import 'profiles_table.dart';

@DataClassName('WorkspaceEntity')
class Workspaces extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get type => text()(); // 'personal' or 'group'
  TextColumn get name => text()();
  TextColumn get slug => text().nullable()();
  TextColumn get ownerUserId => text().references(Profiles, #id)();
  TextColumn get defaultCurrencyCode => text().withDefault(const Constant('VND'))();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Ho_Chi_Minh'))();
  IntColumn get monthStartDay => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get settings => text().withDefault(const Constant('{}'))(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  // Sync fields
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))(); // pending_create, pending_update, pending_delete, synced, conflicted

  @override
  Set<Column> get primaryKey => {id};
}
