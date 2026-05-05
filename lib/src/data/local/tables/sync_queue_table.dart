// path: lib/src/data/local/tables/sync_queue_table.dart

import 'package:drift/drift.dart';

@DataClassName('SyncQueueEntity')
class SyncQueue extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get entityType => text()(); // 'workspace', 'category', 'transaction', 'budget', etc.
  TextColumn get entityId => text()(); // Local/cloud UUID
  TextColumn get workspaceId => text()();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get payloadJson => text()(); // Serialized record
  IntColumn get baseVersion => integer().nullable()(); // Version at edit time
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'processing', 'failed'
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
