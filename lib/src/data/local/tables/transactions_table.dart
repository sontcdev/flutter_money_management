// path: lib/src/data/local/tables/transactions_table.dart
import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get type => text()();
  TextColumn get note => text().nullable()();
  TextColumn get receiptPath => text().named('receipt_path').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

