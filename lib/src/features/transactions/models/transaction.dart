// path: lib/src/models/transaction.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  expense,
  income,
}

enum SyncStatus { pending, synced, error }

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id, // Changed from int to String (UUID)
    required int amountCents,
    required String currency,
    required DateTime dateTime,
    required String categoryId, // Changed from int to String (UUID)
    required TransactionType type,
    String? note,
    String? receiptPath,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    DateTime? syncedAt,
    String? lastSyncError,
    DateTime? deletedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
