// path: lib/src/data/local/tables/sync_state_table.dart

import 'package:drift/drift.dart';

@DataClassName('SyncStateEntity')
class SyncState extends Table {
  TextColumn get workspaceId => text()(); // PK
  DateTimeColumn get lastPulledAt => dateTime().nullable()();
  DateTimeColumn get lastPushedAt => dateTime().nullable()();
  DateTimeColumn get lastRemoteUpdatedAtCursor => dateTime().nullable()();
  BoolColumn get fullSyncCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {workspaceId};
}
