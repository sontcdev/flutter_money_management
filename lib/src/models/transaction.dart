// path: lib/src/models/transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required int amountCents,
    required String currency,
    required DateTime dateTime,
    String? categoryId,
    required TransactionType type,
    String? note,
    String? receiptPath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

enum TransactionType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

