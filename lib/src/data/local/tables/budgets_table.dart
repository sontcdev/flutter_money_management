// path: lib/src/data/local/tables/budgets_table.dart

import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('BudgetEntity')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get periodType => text()(); // 'monthly', 'yearly', 'custom'
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  IntColumn get limitCents => integer()();
  IntColumn get consumedCents => integer()();
  BoolColumn get allowOverdraft => boolean()();
  IntColumn get overdraftCents => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

