import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_attachment_repository.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/transactions/services/transaction_receipt_service.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction_attachment.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final transactionAttachmentRepositoryProvider =
    Provider<TransactionAttachmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionAttachmentRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final transactionReceiptServiceProvider =
    Provider<TransactionReceiptService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final attachments = ref.watch(transactionAttachmentRepositoryProvider);
  return TransactionReceiptService(
    supabase,
    attachments,
    () => ref.read(activeWorkspaceIdProvider),
  );
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getAllTransactions();
});

final transactionCanManageProvider =
    FutureProvider.family<bool, String>((ref, transactionId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.canCurrentUserManageTransaction(transactionId);
});

final transactionReceiptAttachmentProvider =
    FutureProvider.family<TransactionAttachment?, String>(
        (ref, transactionId) async {
  final repository = ref.watch(transactionAttachmentRepositoryProvider);
  return repository.getLatestReceiptAttachmentByTransactionId(transactionId);
});

final transactionReceiptImageUrlProvider =
    FutureProvider.family<String?, String>((ref, transactionId) async {
  final attachment = await ref.watch(
    transactionReceiptAttachmentProvider(transactionId).future,
  );
  if (attachment == null) {
    return null;
  }

  final service = ref.watch(transactionReceiptServiceProvider);
  return service.createSignedReceiptUrl(attachment);
});

final transactionsByDateRangeProvider =
    FutureProvider.family<List<Transaction>, DateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getTransactionsByDateRange(
      dateRange.start,
      dateRange.end,
    );
  },
);

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
