// path: lib/src/data/local/tables/accounts_table.dart

import 'package:drift/drift.dart';

@DataClassName('AccountEntity')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get balanceCents => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get type => text()(); // 'cash', 'card', 'bank'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

