import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_schedule_calculator.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';

abstract class RecurringTransactionsGateway {
  Future<RecurringTransaction> createRecurringTransaction(
    RecurringTransaction transaction,
  );

  Future<void> updateRecurringTransaction(RecurringTransaction transaction);

  Future<void> generateOccurrences({required DateTime throughDate});

  Future<void> skipOccurrence(String occurrenceId);

  Future<void> completeOccurrence({
    required String occurrenceId,
    required String generatedTransactionId,
  });
}

abstract class TransactionCreationGateway {
  Future<Transaction> createTransaction(
    Transaction transaction, {
    bool allowOverdraft = false,
  });
}

class RecurringTransactionService {
  RecurringTransactionService(
    this._repository,
    this._transactionRepository,
    this._getActiveWorkspaceId,
    this._getCurrentUserId,
  );

  final RecurringTransactionsGateway _repository;
  final TransactionCreationGateway _transactionRepository;
  final String? Function() _getActiveWorkspaceId;
  final String? Function() _getCurrentUserId;

  Future<RecurringTransaction> saveRecurringTransaction({
    String? existingId,
    required String title,
    required String categoryId,
    required int amountCents,
    required RecurringTransactionType type,
    required RecurringFrequency frequency,
    required RecurringMode mode,
    required int intervalCount,
    required DateTime startDate,
    required int reminderDaysBefore,
    String? note,
    int? dayOfMonth,
    int? dayOfWeek,
    int? monthOfYear,
    DateTime? endDate,
    required bool isActive,
  }) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();
    final now = DateTime.now();
    final normalizedStartDate = RecurringScheduleCalculator.normalizeDate(
      startDate,
    );
    final nextOccurrenceAt =
        RecurringScheduleCalculator.calculateFirstOccurrence(
      startDate: normalizedStartDate,
      frequency: frequency,
      intervalCount: intervalCount,
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      monthOfYear: monthOfYear,
    );

    final transaction = RecurringTransaction(
      id: existingId ?? '',
      workspaceId: workspaceId,
      title: title.trim(),
      categoryId: categoryId,
      amountCents: amountCents,
      currency: 'VND',
      type: type,
      frequency: frequency,
      mode: mode,
      intervalCount: intervalCount,
      startDate: normalizedStartDate,
      nextOccurrenceAt: nextOccurrenceAt,
      reminderDaysBefore: reminderDaysBefore,
      isActive: isActive,
      createdByUserId: userId,
      updatedByUserId: userId,
      createdAt: now,
      updatedAt: now,
      note: _normalizeOptionalText(note),
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      monthOfYear: monthOfYear,
      endDate: endDate == null
          ? null
          : RecurringScheduleCalculator.normalizeDate(endDate),
    );

    final saved = existingId == null || existingId.isEmpty
        ? await _repository.createRecurringTransaction(transaction)
        : await _repository.updateRecurringTransaction(transaction).then(
              (_) => transaction,
            );

    await _repository.generateOccurrences(
      throughDate: DateTime.now().add(const Duration(days: 30)),
    );

    return saved;
  }

  Future<void> skipOccurrence(String occurrenceId) async {
    await _repository.skipOccurrence(occurrenceId);
    await _repository.generateOccurrences(
      throughDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<void> confirmOccurrence({
    required RecurringOccurrence occurrence,
    required RecurringTransaction recurringTransaction,
    bool allowOverdraft = false,
  }) async {
    final now = DateTime.now();
    final transaction = Transaction(
      id: '',
      amountCents: recurringTransaction.amountCents,
      currency: recurringTransaction.currency,
      dateTime: occurrence.scheduledFor,
      categoryId: recurringTransaction.categoryId,
      type: recurringTransaction.type == RecurringTransactionType.expense
          ? TransactionType.expense
          : TransactionType.income,
      note: recurringTransaction.note,
      createdAt: now,
      updatedAt: now,
    );

    final created = await _transactionRepository.createTransaction(
      transaction,
      allowOverdraft: allowOverdraft,
    );

    await _repository.completeOccurrence(
      occurrenceId: occurrence.id,
      generatedTransactionId: created.id,
    );
    await _repository.generateOccurrences(
      throughDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  String _requireWorkspaceId() {
    final workspaceId = _getActiveWorkspaceId();
    if (workspaceId == null || workspaceId.isEmpty) {
      throw Exception('No active workspace selected');
    }
    return workspaceId;
  }

  String _requireUserId() {
    final userId = _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user');
    }
    return userId;
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
