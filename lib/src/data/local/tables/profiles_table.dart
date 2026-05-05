// path: lib/src/data/local/tables/profiles_table.dart

import 'package:drift/drift.dart';

@DataClassName('ProfileEntity')
class Profiles extends Table {
  TextColumn get id => text()(); // UUID from Supabase
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get defaultCurrencyCode => text().withDefault(const Constant('VND'))();
  TextColumn get locale => text().withDefault(const Constant('vi'))();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Ho_Chi_Minh'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get lastActiveAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
