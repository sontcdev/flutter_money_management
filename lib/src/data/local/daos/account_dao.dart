// path: lib/src/data/local/daos/account_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/accounts_table.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(AppDatabase db) : super(db);

  Future<List<AccountEntity>> getAllAccounts() {
    return select(accounts).get();
  }

  Future<AccountEntity> getAccountById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingle();
  }

  Future<int> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  Future<bool> updateAccount(AccountsCompanion account) {
    return update(accounts).replace(account);
  }

  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  Future<void> updateBalance(int accountId, int amountCents) async {
    final account = await getAccountById(accountId);
    final newBalance = account.balanceCents + amountCents;
    await (update(accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(
        balanceCents: Value(newBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

