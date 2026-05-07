# Supabase Sync Implementation Guide

## Overview

This document describes the implementation of local-first sync with Supabase push-on-write for the Flutter Money Management app. The implementation follows these principles:

- **Local-first**: All writes happen to local Drift database first
- **Async push**: Changes are queued and pushed to Supabase asynchronously
- **UUID primary keys**: Shared between local and remote (no mapping table needed)
- **Soft delete**: Records are marked as deleted, not physically removed
- **Sync metadata**: Track sync status, errors, and timestamps
- **Derived fields**: Budget `consumedCents` is calculated from transactions, not synced

## Schema Changes (Version 5)

### Migration Summary

The schema has been migrated from integer auto-increment IDs to UUID primary keys with sync metadata. This is a **breaking change** that requires data migration.

### New Fields Added to All Tables

All tables (transactions, budgets, categories) now include:

```dart
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
DateTimeColumn get syncedAt => dateTime().nullable()();
TextColumn get lastSyncError => text().nullable()();
DateTimeColumn get deletedAt => dateTime().nullable()();
```

### New SyncQueue Table

```dart
class SyncQueue extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get entityType => text()(); // 'transaction', 'budget', 'category'
  TextColumn get entityId => text()(); // UUID of the entity
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
}
```

## Files Modified

### Database Schema
- `lib/src/data/local/tables/categories_table.dart` - UUID + sync metadata
- `lib/src/data/local/tables/budgets_table.dart` - UUID + sync metadata
- `lib/src/data/local/tables/transactions_table.dart` - UUID + sync metadata
- `lib/src/data/local/tables/sync_queue_table.dart` - NEW
- `lib/src/data/local/app_database.dart` - Schema v5 + migration logic

### DAOs
- `lib/src/data/local/daos/transaction_dao.dart` - UUID support + soft delete
- `lib/src/data/local/daos/budget_dao.dart` - UUID support + soft delete
- `lib/src/data/local/daos/category_dao.dart` - UUID support + soft delete
- `lib/src/data/local/daos/sync_queue_dao.dart` - NEW

### Models
- `lib/src/models/transaction.dart` - String ID + sync fields
- `lib/src/models/budget.dart` - String ID + sync fields
- `lib/src/models/category.dart` - String ID + sync fields
- `lib/src/models/sync_queue_item.dart` - NEW

### Services
- `lib/src/services/sync/supabase_sync_service.dart` - NEW
- `lib/src/services/sync/sync_queue_processor.dart` - NEW

### UI Updates
- `lib/src/ui/screens/today_screen.dart` - Removed "Add Income", renamed to "Add Transaction"
- `lib/src/ui/widgets/transaction_item.dart` - Removed icon/avatar, show category/note/date only
- `lib/src/ui/screens/transactions_screen.dart` - Show date in transaction items

### Dependencies
- `pubspec.yaml` - Added `uuid: ^4.5.1`

## Manual Steps Required

### 1. Install Dependencies

```bash
flutter pub get
```

**Note**: If this times out, try:
```bash
flutter pub cache repair
flutter pub get
```

### 2. Run Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This will generate:
- `.g.dart` files for Drift tables and DAOs
- `.freezed.dart` and `.g.dart` files for models

### 3. Update Repositories

The following repository files need to be updated to:
- Generate UUIDs for new records
- Enqueue sync operations after create/update/delete
- Use String IDs instead of int

Files to update:
- `lib/src/data/repositories/transaction_repository.dart`
- `lib/src/data/repositories/budget_repository.dart`
- `lib/src/data/repositories/category_repository.dart`

Example pattern for TransactionRepository:

```dart
import 'package:uuid/uuid.dart';
import '../local/daos/sync_queue_dao.dart';

class TransactionRepository {
  final TransactionDao _dao;
  final SyncQueueDao _syncQueueDao;
  final _uuid = const Uuid();

  Future<String> createTransaction({
    required int amountCents,
    required String currency,
    required DateTime dateTime,
    required String categoryId,
    required TransactionType type,
    String? note,
    String? receiptPath,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    
    await _dao.insertTransaction(
      TransactionsCompanion.insert(
        id: id,
        amountCents: amountCents,
        currency: currency,
        transactionDate: dateTime,
        categoryId: categoryId,
        type: type.name,
        note: Value(note),
        receiptPath: Value(receiptPath),
        createdAt: now,
        updatedAt: now,
        syncStatus: const Value('pending'),
      ),
    );
    
    // Enqueue sync operation
    await _syncQueueDao.addSyncItem(
      SyncQueueCompanion.insert(
        id: _uuid.v4(),
        entityType: 'transaction',
        entityId: id,
        operation: 'create',
        createdAt: now,
      ),
    );
    
    return id;
  }
}
```

### 4. Create Sync Service Provider

Create `lib/src/providers/sync_providers.dart`:

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sync/supabase_sync_service.dart';
import '../services/sync/sync_queue_processor.dart';
import '../data/local/app_database.dart';
import 'providers.dart';

final supabaseSyncServiceProvider = Provider<SupabaseSyncService>((ref) {
  final supabase = Supabase.instance.client;
  final database = ref.watch(databaseProvider);
  return SupabaseSyncService(supabase, database);
});

final syncQueueProcessorProvider = Provider<SyncQueueProcessor>((ref) {
  final database = ref.watch(databaseProvider);
  final syncService = ref.watch(supabaseSyncServiceProvider);
  final syncQueueDao = database.syncQueueDao;
  final transactionDao = database.transactionDao;
  final budgetDao = database.budgetDao;
  final categoryDao = database.categoryDao;
  
  final processor = SyncQueueProcessor(
    database,
    syncService,
    syncQueueDao,
    transactionDao,
    budgetDao,
    categoryDao,
  );
  
  // Start auto-processing every 30 seconds
  processor.startAutoProcessing();
  
  ref.onDispose(() {
    processor.dispose();
  });
  
  return processor;
});
```

### 5. Initialize Sync Processor

In your app initialization (e.g., `main.dart` or root widget):

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize sync processor
    ref.watch(syncQueueProcessorProvider);
    
    return MaterialApp(
      // ... rest of app
    );
  }
}
```

### 6. Create Supabase Tables

Run these SQL commands in your Supabase SQL editor:

```sql
-- Categories table
CREATE TABLE categories (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  color_value INTEGER NOT NULL,
  type TEXT NOT NULL DEFAULT 'expense',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

-- Budgets table
CREATE TABLE budgets (
  id UUID PRIMARY KEY,
  category_id UUID NOT NULL REFERENCES categories(id),
  period_type TEXT NOT NULL,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  limit_cents INTEGER NOT NULL,
  allow_overdraft BOOLEAN NOT NULL,
  overdraft_cents INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL,
  transaction_date TIMESTAMPTZ NOT NULL,
  category_id UUID NOT NULL REFERENCES categories(id),
  type TEXT NOT NULL,
  note TEXT,
  receipt_path TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_deleted_at ON transactions(deleted_at);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
CREATE INDEX idx_budgets_period ON budgets(period_start, period_end);
CREATE INDEX idx_budgets_deleted_at ON budgets(deleted_at);
CREATE INDEX idx_categories_deleted_at ON categories(deleted_at);

-- Row Level Security (RLS)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies (adjust based on your auth setup)
CREATE POLICY "Users can view their own categories"
  ON categories FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert their own categories"
  ON categories FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their own categories"
  ON categories FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- Repeat similar policies for budgets and transactions
```

### 7. Run Verification

```bash
flutter gen-l10n
flutter analyze
flutter test
```

### 8. Test the Implementation

1. Create a new transaction/budget/category
2. Check that it appears in the local database with `syncStatus = 'pending'`
3. Check that a sync queue item is created
4. Wait 30 seconds (or trigger manual sync)
5. Verify the record appears in Supabase
6. Verify local `syncStatus` changes to 'synced'

## Architecture Decisions

### Why UUID?
- Enables offline-first: generate IDs locally without server round-trip
- No ID conflicts when syncing from multiple devices
- Simplifies sync: same ID used locally and remotely

### Why Soft Delete?
- Enables sync of deletions across devices
- Allows undo functionality
- Maintains referential integrity during sync

### Why Sync Queue?
- Decouples write operations from network calls
- Enables retry logic for failed syncs
- Allows batching of sync operations
- Provides visibility into sync status

### Why Not Sync consumedCents?
- It's derived from transactions
- Syncing transactions is sufficient
- Reduces sync conflicts
- Single source of truth

## Troubleshooting

### Build Errors After Migration

```bash
flutter clean
rm -rf .dart_tool/build
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Sync Not Working

1. Check Supabase connection: `Supabase.instance.client.auth.currentUser`
2. Check sync queue: Query `sync_queue` table for pending items
3. Check sync status: Query entities for `sync_status = 'error'`
4. Check logs: Look for error messages in `last_sync_error` field

### Migration Issues

If the automatic migration fails:
1. Export existing data using the app's export feature
2. Uninstall the app (clears local database)
3. Reinstall and let it create the new schema
4. Import the data back

## Future Enhancements

- [ ] Pull sync: Fetch changes from Supabase
- [ ] Conflict resolution: Handle concurrent edits
- [ ] Batch sync: Sync multiple items in one request
- [ ] Sync status UI: Show sync progress to users
- [ ] Manual sync trigger: Allow users to force sync
- [ ] Offline indicator: Show when app is offline
- [ ] Sync settings: Configure sync frequency

## References

- [Drift Documentation](https://drift.simonbinder.eu/)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)
- [UUID Package](https://pub.dev/packages/uuid)
- [Riverpod Documentation](https://riverpod.dev/)
