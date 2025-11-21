// path: lib/src/data/local/app_database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/budgets_table.dart';

import 'daos/transaction_dao.dart';
import 'daos/category_dao.dart';
import 'daos/budget_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, Categories, Budgets],
  daos: [TransactionDao, CategoryDao, BudgetDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Test constructor
  AppDatabase.withQueryExecutor(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          // Remove accountId column from transactions
          // Drift doesn't support dropping columns directly, so we recreate the table
          await customStatement('DROP TABLE IF EXISTS accounts');

          // Create temporary transactions table without accountId
          await customStatement('''
            CREATE TABLE IF NOT EXISTS transactions_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount_cents INTEGER NOT NULL,
              currency TEXT NOT NULL,
              transaction_date INTEGER NOT NULL,
              category_id INTEGER NOT NULL REFERENCES categories(id),
              type TEXT NOT NULL,
              note TEXT,
              receipt_path TEXT,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
              updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            )
          ''');

          // Copy data from old table to new (excluding accountId)
          await customStatement('''
            INSERT INTO transactions_new 
            (id, amount_cents, currency, transaction_date, category_id, type, note, receipt_path, created_at, updated_at)
            SELECT id, amount_cents, currency, transaction_date, category_id, type, note, receipt_path, created_at, updated_at
            FROM transactions
          ''');

          // Drop old table and rename new one
          await customStatement('DROP TABLE transactions');
          await customStatement('ALTER TABLE transactions_new RENAME TO transactions');
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'money_management.sqlite'));
    return NativeDatabase(file);
  });
}

