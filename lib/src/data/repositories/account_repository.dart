// path: lib/src/data/repositories/account_repository.dart
import 'package:test3_cursor/src/models/account.dart' as model;
import 'package:test3_cursor/src/data/local/app_database.dart';

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Future<List<model.Account>> getAllAccounts() async {
    return await _db.accountDao.getAllAccounts();
  }

  Future<model.Account?> getAccountById(String id) async {
    return await _db.accountDao.getAccountById(id);
  }

  Future<model.Account> createAccount(model.Account account) async {
    await _db.accountDao.insertAccount(account);
    return account;
  }

  Future<model.Account> updateAccount(model.Account account) async {
    await _db.accountDao.updateAccount(account);
    return account;
  }

  Future<void> deleteAccount(String id) async {
    await _db.accountDao.deleteAccount(id);
  }
}

