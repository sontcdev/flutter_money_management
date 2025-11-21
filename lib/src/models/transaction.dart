// path: lib/src/models/transaction.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  expense,
  income,
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required int id,
    required int amountCents,
    required String currency,
    required DateTime dateTime,
    required int categoryId,
    required int accountId,
    required TransactionType type,
    String? note,
    String? receiptPath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

