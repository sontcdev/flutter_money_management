// path: lib/src/data/repositories/account_repository.dart

import 'package:drift/drift.dart';
import '../local/app_database.dart';
import '../../models/account.dart' as model;

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Future<List<model.Account>> getAllAccounts() async {
    final entities = await _db.accountDao.getAllAccounts();
    return entities.map(_entityToModel).toList();
  }

  Future<model.Account> getAccountById(int id) async {
    final entity = await _db.accountDao.getAccountById(id);
    return _entityToModel(entity);
  }

  Future<model.Account> createAccount(model.Account account) async {
    final companion = _modelToCompanion(account);
    final id = await _db.accountDao.insertAccount(companion);
    return getAccountById(id);
  }

  Future<void> updateAccount(model.Account account) async {
    final companion = _modelToCompanion(account);
    await _db.accountDao.updateAccount(companion);
  }

  Future<void> deleteAccount(int id) async {
    await _db.accountDao.deleteAccount(id);
  }

  model.Account _entityToModel(AccountEntity entity) {
    return model.Account(
      id: entity.id,
      name: entity.name,
      balanceCents: entity.balanceCents,
      currency: entity.currency,
      type: _stringToAccountType(entity.type),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AccountsCompanion _modelToCompanion(model.Account account) {
    return AccountsCompanion(
      id: account.id > 0 ? Value(account.id) : const Value.absent(),
      name: Value(account.name),
      balanceCents: Value(account.balanceCents),
      currency: Value(account.currency),
      type: Value(_accountTypeToString(account.type)),
      createdAt: Value(account.createdAt),
      updatedAt: Value(account.updatedAt),
    );
  }

  model.AccountType _stringToAccountType(String type) {
    switch (type) {
      case 'cash':
        return model.AccountType.cash;
      case 'card':
        return model.AccountType.card;
      case 'bank':
        return model.AccountType.bank;
      default:
        return model.AccountType.cash;
    }
  }

  String _accountTypeToString(model.AccountType type) {
    switch (type) {
      case model.AccountType.cash:
        return 'cash';
      case model.AccountType.card:
        return 'card';
      case model.AccountType.bank:
        return 'bank';
    }
  }
}

