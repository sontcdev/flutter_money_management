// path: lib/src/data/local/app_database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/accounts_table.dart';
import 'tables/budgets_table.dart';

import 'daos/transaction_dao.dart';
import 'daos/category_dao.dart';
import 'daos/account_dao.dart';
import 'daos/budget_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, Categories, Accounts, Budgets],
  daos: [TransactionDao, CategoryDao, AccountDao, BudgetDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Test constructor
  AppDatabase.withQueryExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
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

