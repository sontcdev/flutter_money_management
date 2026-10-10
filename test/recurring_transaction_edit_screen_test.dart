import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/presentation/screens/recurring_transaction_edit_screen.dart';
import 'package:flutter_money_management/src/features/recurring/providers/recurring_providers.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_transaction_service.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';

class _FakeRecurringGateway implements RecurringTransactionsGateway {
  @override
  Future<void> completeOccurrence(
      {required String occurrenceId,
      required String generatedTransactionId}) async {}

  @override
  Future<RecurringTransaction> createRecurringTransaction(
          RecurringTransaction transaction) async =>
      transaction;

  @override
  Future<void> generateOccurrences({required DateTime throughDate}) async {}

  @override
  Future<void> skipOccurrence(String occurrenceId) async {}

  @override
  Future<void> updateRecurringTransaction(
      RecurringTransaction transaction) async {}
}

class _FakeTransactionGateway implements TransactionCreationGateway {
  @override
  Future<Transaction> createTransaction(
    Transaction transaction, {
    bool allowOverdraft = false,
  }) async =>
      transaction;
}

void main() {
  testWidgets('RecurringTransactionEditScreen validates and shows form fields',
      (
    tester,
  ) async {
    final service = RecurringTransactionService(
      _FakeRecurringGateway(),
      _FakeTransactionGateway(),
      () => 'workspace-1',
      () => 'user-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith(
            (ref) async => [
              Category(
                id: 'cat-1',
                name: 'Housing',
                iconName: 'home',
                colorValue: Colors.blue.toARGB32(),
                type: CategoryType.expense,
                createdAt: DateTime(2026, 5, 1),
                updatedAt: DateTime(2026, 5, 1),
              ),
            ],
          ),
          recurringTransactionServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('vi'), Locale('ja')],
          home: RecurringTransactionEditScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add recurring transaction'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
    expect(find.text('Behavior'), findsOneWidget);
    expect(find.text('Housing'), findsOneWidget);
    expect(find.text('Next occurrences'), findsOneWidget);
  });

  group('previewRecurringOccurrences', () {
    test('returns the next three monthly dates', () {
      final dates = previewRecurringOccurrences(
        startDate: DateTime(2026, 1, 15),
        frequency: RecurringFrequency.monthly,
        intervalCount: 1,
        dayOfMonth: 31,
      );
      expect(dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
      ]);
    });

    test('respects the weekday and interval for weekly schedules', () {
      final dates = previewRecurringOccurrences(
        startDate: DateTime(2026, 6, 3),
        frequency: RecurringFrequency.weekly,
        intervalCount: 2,
        dayOfWeek: DateTime.monday,
      );
      expect(dates, [
        DateTime(2026, 6, 8),
        DateTime(2026, 6, 22),
        DateTime(2026, 7, 6),
      ]);
    });

    test('stops at the end date', () {
      final dates = previewRecurringOccurrences(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 15),
        frequency: RecurringFrequency.monthly,
        intervalCount: 1,
        dayOfMonth: 1,
      );
      expect(dates, [DateTime(2026, 1, 1), DateTime(2026, 2, 1)]);
    });
  });
}
