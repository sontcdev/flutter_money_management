import 'package:drift/drift.dart';
import 'package:test3_cursor/src/models/transaction.dart' as model;
import '../tables/transactions_table.dart';
import '../app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<List<model.Transaction>> getAllTransactions({
    int? limit,
    int? offset,
    String? categoryId,
    model.TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = select(transactionsTable);

    if (categoryId != null) {
      query = query..where((t) => t.categoryId.equals(categoryId));
    }
    if (type != null) {
      query = query..where((t) => t.type.equals(type.name));
    }
    if (startDate != null) {
      query = query..where((t) => t.transactionDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query = query..where((t) => t.transactionDate.isSmallerOrEqualValue(endDate));
    }
    
    query = query..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);
    
    if (limit != null) {
      query = query..limit(limit, offset: offset ?? 0);
    }
    
    final rows = await query.get();
    return rows.map(_rowToTransaction).toList();
  }

  Future<model.Transaction?> getTransactionById(String id) async {
    final row = await (select(transactionsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _rowToTransaction(row) : null;
  }

  Future<void> insertTransaction(model.Transaction transaction) async {
    await into(transactionsTable).insert(_transactionToRow(transaction),
        mode: InsertMode.replace);
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    await (update(transactionsTable)..where((t) => t.id.equals(transaction.id)))
        .write(_transactionToRow(transaction));
  }

  Future<void> deleteTransaction(String id) async {
    await (delete(transactionsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getTotalByCategory(String categoryId, DateTime start, DateTime end) async {
    final condition = transactionsTable.categoryId.equals(categoryId) &
        transactionsTable.transactionDate.isBiggerOrEqualValue(start) &
        transactionsTable.transactionDate.isSmallerOrEqualValue(end) &
        transactionsTable.type.equals('expense');

    final query = selectOnly(transactionsTable)
      ..addColumns([transactionsTable.amountCents.sum()])
      ..where(condition);
    
    final result = await query.getSingle();
    final sum = result.read(transactionsTable.amountCents.sum());
    return sum?.toInt() ?? 0;
  }

  Future<int> getTotalByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final condition = transactionsTable.transactionDate.isBiggerOrEqualValue(start) &
        transactionsTable.transactionDate.isSmallerOrEqualValue(end) &
        transactionsTable.type.equals('expense');

    final query = selectOnly(transactionsTable)
      ..addColumns([transactionsTable.amountCents.sum()])
      ..where(condition);
    
    final result = await query.getSingle();
    final sum = result.read(transactionsTable.amountCents.sum());
    return sum?.toInt() ?? 0;
  }

  Future<int> getTotalByYear(int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    final condition = transactionsTable.transactionDate.isBiggerOrEqualValue(start) &
        transactionsTable.transactionDate.isSmallerOrEqualValue(end) &
        transactionsTable.type.equals('expense');

    final query = selectOnly(transactionsTable)
      ..addColumns([transactionsTable.amountCents.sum()])
      ..where(condition);
    
    final result = await query.getSingle();
    final sum = result.read(transactionsTable.amountCents.sum());
    return sum?.toInt() ?? 0;
  }

  model.Transaction _rowToTransaction(TransactionEntity row) {
    return model.Transaction(
      id: row.id,
      amountCents: row.amountCents,
      currency: row.currency,
      dateTime: row.transactionDate,
      categoryId: row.categoryId,
      type: model.TransactionType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => model.TransactionType.expense,
      ),
      note: row.note,
      receiptPath: row.receiptPath,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TransactionsTableCompanion _transactionToRow(model.Transaction transaction) {
    return TransactionsTableCompanion(
      id: Value(transaction.id),
      amountCents: Value(transaction.amountCents),
      currency: Value(transaction.currency),
      transactionDate: Value(transaction.dateTime),
      categoryId: Value(transaction.categoryId),
      type: Value(transaction.type.name),
      note: Value(transaction.note),
      receiptPath: Value(transaction.receiptPath),
      createdAt: Value(transaction.createdAt),
      updatedAt: Value(transaction.updatedAt),
    );
  }
}

