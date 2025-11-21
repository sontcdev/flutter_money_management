// path: lib/src/data/local/tables/transactions_table.dart

import 'package:drift/drift.dart';
import 'categories_table.dart';
import 'accounts_table.dart';

@DataClassName('TransactionEntity')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get type => text()(); // 'expense' or 'income'
  TextColumn get note => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

