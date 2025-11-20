// path: lib/src/data/local/daos/account_dao.dart
import 'package:drift/drift.dart';
import 'package:test3_cursor/src/models/account.dart' as model;
import '../tables/accounts_table.dart';
import '../app_database.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<model.Account>> getAllAccounts() async {
    final rows = await select(accounts).get();
    return rows.map(_rowToAccount).toList();
  }

  Future<model.Account?> getAccountById(String id) async {
    final row = await (select(accounts)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _rowToAccount(row) : null;
  }

  Future<void> insertAccount(model.Account account) async {
    await into(accounts).insert(_accountToRow(account),
        mode: InsertMode.replace);
  }

  Future<void> updateAccount(model.Account account) async {
    await (update(accounts)..where((a) => a.id.equals(account.id)))
        .write(_accountToRow(account));
  }

  Future<void> deleteAccount(String id) async {
    await (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  Future<void> updateBalance(String id, int newBalanceCents) async {
    await (update(accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(balanceCents: Value(newBalanceCents)));
  }

  model.Account _rowToAccount(Account row) {
    return model.Account(
      id: row.id,
      name: row.name,
      balanceCents: row.balanceCents,
      currency: row.currency,
      type: model.AccountType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => model.AccountType.cash,
      ),
      createdAt: row.createdAt,
    );
  }

  AccountsCompanion _accountToRow(model.Account account) {
    return AccountsCompanion(
      id: Value(account.id),
      name: Value(account.name),
      balanceCents: Value(account.balanceCents),
      currency: Value(account.currency),
      type: Value(account.type.name),
      createdAt: Value(account.createdAt),
    );
  }
}

