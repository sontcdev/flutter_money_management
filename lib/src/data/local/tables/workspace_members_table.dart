// path: lib/src/data/local/tables/workspace_members_table.dart

import 'package:drift/drift.dart';
import 'workspaces_table.dart';
import 'profiles_table.dart';

@DataClassName('WorkspaceMemberEntity')
class WorkspaceMembers extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get workspaceId => text().references(Workspaces, #id)();
  TextColumn get userId => text().references(Profiles, #id)();
  TextColumn get role => text()(); // 'owner' or 'member'
  TextColumn get membershipStatus => text().withDefault(const Constant('active'))();
  TextColumn get permissions => text().withDefault(const Constant('{}'))(); // JSON string
  DateTimeColumn get joinedAt => dateTime().nullable()();
  TextColumn get invitedByUserId => text().nullable().references(Profiles, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get removedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
