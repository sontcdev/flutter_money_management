// path: lib/src/data/local/tables/accounts_table.dart
import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get balanceCents => integer()();
  TextColumn get currency => text()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

