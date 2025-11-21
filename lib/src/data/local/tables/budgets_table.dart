// path: lib/src/data/local/tables/budgets_table.dart
import 'package:drift/drift.dart';

@DataClassName('BudgetEntity')
class BudgetsTable extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get name => text().nullable()(); // Tên hũ chi tiêu
  TextColumn get categoryId => text()(); // FK to categories
  IntColumn get limitCents => integer()();
  IntColumn get consumedCents => integer().withDefault(const Constant(0))();
  BoolColumn get allowOverdraft => boolean().withDefault(const Constant(false))();
  IntColumn get overdraftCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {categoryId, periodStart},
  ];
}

// Generated code will be in budgets_table.g.dart
// Index on (categoryId, periodStart) for efficient lookups of active budgets

