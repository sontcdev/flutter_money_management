// path: lib/src/data/local/daos/transaction_dao.dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<List<TransactionEntity>> getAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  Future<List<TransactionEntity>> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.transactionDate.isBiggerOrEqualValue(start) &
              t.transactionDate.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  Future<List<TransactionEntity>> getTransactionsByCategory(int categoryId) {
    return (select(transactions)..where((t) => t.categoryId.equals(categoryId)))
        .get();
  }

  Future<List<TransactionEntity>> getTransactionsByAccount(int accountId) {
    return (select(transactions)..where((t) => t.accountId.equals(accountId)))
        .get();
  }

  Future<TransactionEntity> getTransactionById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> insertTransaction(TransactionsCompanion transaction) {
    return into(transactions).insert(transaction);
  }

  Future<bool> updateTransaction(TransactionsCompanion transaction) {
    return update(transactions).replace(transaction);
  }

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  // Aggregate queries
  Future<int> sumAmountByCategory(int categoryId, DateTime start, DateTime end) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amountCents.sum()])
      ..where(transactions.categoryId.equals(categoryId) &
          transactions.transactionDate.isBiggerOrEqualValue(start) &
          transactions.transactionDate.isSmallerOrEqualValue(end));

    final result = await query.getSingle();
    return result.read(transactions.amountCents.sum()) ?? 0;
  }

  Future<int> sumAmountByDateRange(DateTime start, DateTime end, {String? type}) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amountCents.sum()])
      ..where(transactions.transactionDate.isBiggerOrEqualValue(start) &
          transactions.transactionDate.isSmallerOrEqualValue(end));

    if (type != null) {
      query.where(transactions.type.equals(type));
    }

    final result = await query.getSingle();
    return result.read(transactions.amountCents.sum()) ?? 0;
  }

  Future<Map<int, int>> sumAmountByCategoryInRange(
      DateTime start, DateTime end, String type) async {
    final query = selectOnly(transactions, distinct: false)
      ..addColumns([transactions.categoryId, transactions.amountCents.sum()])
      ..where(transactions.transactionDate.isBiggerOrEqualValue(start) &
          transactions.transactionDate.isSmallerOrEqualValue(end) &
          transactions.type.equals(type))
      ..groupBy([transactions.categoryId]);

    final results = await query.get();
    final Map<int, int> map = {};
    for (final row in results) {
      final categoryId = row.read(transactions.categoryId);
      final sum = row.read(transactions.amountCents.sum()) ?? 0;
      if (categoryId != null) {
        map[categoryId] = sum;
      }
    }
    return map;
  }
}

