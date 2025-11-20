// path: lib/src/data/local/tables/transactions_table.dart
import 'package:drift/drift.dart';

@DataClassName('TransactionEntity')
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get note => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Generated code will be in transactions_table.g.dart

