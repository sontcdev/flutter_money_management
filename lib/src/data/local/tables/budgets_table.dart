// path: lib/src/data/local/tables/budgets_table.dart
import 'package:drift/drift.dart';

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get periodType => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  IntColumn get limitCents => integer()();
  IntColumn get consumedCents => integer().withDefault(const Constant(0))();
  BoolColumn get allowOverdraft => boolean().withDefault(const Constant(false))();
  IntColumn get overdraftCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

