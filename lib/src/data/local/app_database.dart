// path: lib/src/data/local/app_database.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
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

@DriftDatabase(tables: [TransactionsTable, CategoriesTable, BudgetsTable], daos: [TransactionDao, CategoryDao, BudgetDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Remove accounts table
          await m.deleteTable('accounts');
          // Note: accountId column in transactions table will be ignored
          // as it's no longer in the schema definition
        }
        if (from < 3) {
          // Add type column to categories table if it doesn't exist
          try {
            // Use raw SQL to add column (SQLite doesn't support IF NOT EXISTS for ALTER TABLE)
            await m.database.customStatement('ALTER TABLE categories ADD COLUMN type TEXT');
            // Set default value for existing rows
            await m.database.customStatement("UPDATE categories SET type = 'expense' WHERE type IS NULL");
          } catch (e) {
            // Column might already exist, ignore error
            debugPrint('Migration note (type column may already exist): $e');
          }
        }
        if (from < 4) {
          // Add name column to budgets table if it doesn't exist
          try {
            await m.database.customStatement('ALTER TABLE budgets ADD COLUMN name TEXT');
          } catch (e) {
            // Column might already exist, ignore error
            debugPrint('Migration note (name column may already exist): $e');
          }
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'app.db'));
      debugPrint('Database path: ${file.path}');
      debugPrint('Database exists: ${await file.exists()}');
      final database = NativeDatabase(file);
      debugPrint('Database connection opened successfully');
      return database;
    } catch (e, stackTrace) {
      debugPrint('Error opening database: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  });
}

