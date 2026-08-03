// path: lib/src/models/transaction.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  expense,
  income,
  // Moves money between two wallets. Never counted as income or expense.
  transfer,
}

enum SyncStatus { pending, synced, error }

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id, // Changed from int to String (UUID)
    required int amountCents,
    required String currency,
    required DateTime dateTime,
    // Null only for transfers, which have no category.
    String? categoryId,
    required TransactionType type,
    // Source wallet. Required by the database, nullable here so older rows and
    // in-flight form state stay representable.
    String? walletId,
    // Destination wallet, set only for transfers.
    String? toWalletId,
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
