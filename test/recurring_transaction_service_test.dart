import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_transaction_service.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';

class _MockRecurringGateway extends Mock
    implements RecurringTransactionsGateway {}

class _MockTransactionGateway extends Mock
    implements TransactionCreationGateway {}

class _FakeRecurringTransaction extends Fake implements RecurringTransaction {}

class _FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRecurringTransaction());
    registerFallbackValue(_FakeTransaction());
  });

  group('RecurringTransactionService', () {
    late _MockRecurringGateway recurringGateway;
    late _MockTransactionGateway transactionGateway;
    late RecurringTransactionService service;

    setUp(() {
      recurringGateway = _MockRecurringGateway();
      transactionGateway = _MockTransactionGateway();
      service = RecurringTransactionService(
        recurringGateway,
        transactionGateway,
        () => 'workspace-1',
        () => 'user-1',
      );
    });

    test(
        'saveRecurringTransaction creates recurring template and generates occurrences',
        () async {
      when(() => recurringGateway.createRecurringTransaction(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.first as RecurringTransaction,
      );
      when(() => recurringGateway.generateOccurrences(
          throughDate: any(named: 'throughDate'))).thenAnswer((_) async {});

      final saved = await service.saveRecurringTransaction(
        title: 'Rent',
        categoryId: 'category-1',
        amountCents: 150000000,
        type: RecurringTransactionType.expense,
        frequency: RecurringFrequency.monthly,
        mode: RecurringMode.manualConfirm,
        intervalCount: 1,
        startDate: DateTime(2026, 5, 12),
        reminderDaysBefore: 3,
        dayOfMonth: 12,
        isActive: true,
      );

      expect(saved.title, 'Rent');
      expect(saved.workspaceId, 'workspace-1');
      expect(saved.createdByUserId, 'user-1');
      verify(() => recurringGateway.createRecurringTransaction(any()))
          .called(1);
      verify(() => recurringGateway.generateOccurrences(
          throughDate: any(named: 'throughDate'))).called(1);
    });

    test('confirmOccurrence creates transaction and completes occurrence',
        () async {
      final occurrence = RecurringOccurrence(
        id: 'occ-1',
        recurringTransactionId: 'rec-1',
        workspaceId: 'workspace-1',
        scheduledFor: DateTime(2026, 5, 20),
        remindAt: DateTime(2026, 5, 19),
        status: RecurringOccurrenceStatus.pending,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );
      final recurring = RecurringTransaction(
        id: 'rec-1',
        workspaceId: 'workspace-1',
        title: 'Electricity',
        categoryId: 'cat-1',
        amountCents: 4200000,
        currency: 'VND',
        type: RecurringTransactionType.expense,
        frequency: RecurringFrequency.monthly,
        mode: RecurringMode.manualConfirm,
        intervalCount: 1,
        startDate: DateTime(2026, 5, 1),
        nextOccurrenceAt: DateTime(2026, 5, 20),
        reminderDaysBefore: 1,
        isActive: true,
        createdByUserId: 'user-1',
        updatedByUserId: 'user-1',
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );

      when(
        () => transactionGateway.createTransaction(
          any(),
          allowOverdraft: any(named: 'allowOverdraft'),
        ),
      ).thenAnswer(
        (invocation) async =>
            (invocation.positionalArguments.first as Transaction)
                .copyWith(id: 'txn-1'),
      );
      when(
        () => recurringGateway.completeOccurrence(
          occurrenceId: any(named: 'occurrenceId'),
          generatedTransactionId: any(named: 'generatedTransactionId'),
        ),
      ).thenAnswer((_) async {});
      when(() => recurringGateway.generateOccurrences(
          throughDate: any(named: 'throughDate'))).thenAnswer((_) async {});

      await service.confirmOccurrence(
        occurrence: occurrence,
        recurringTransaction: recurring,
      );

      verify(
        () => transactionGateway.createTransaction(
          any(),
          allowOverdraft: false,
        ),
      ).called(1);
      verify(
        () => recurringGateway.completeOccurrence(
          occurrenceId: 'occ-1',
          generatedTransactionId: 'txn-1',
        ),
      ).called(1);
    });
  });
}
