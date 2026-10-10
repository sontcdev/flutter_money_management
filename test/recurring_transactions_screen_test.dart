import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/presentation/screens/recurring_transactions_screen.dart';
import 'package:flutter_money_management/src/features/recurring/providers/recurring_providers.dart';

class _FakeRecurringActions extends RecurringActionsNotifier {
  _FakeRecurringActions(super.ref, this.skippedIds);

  final List<String> skippedIds;

  @override
  Future<void> skipOccurrence(String occurrenceId) async {
    skippedIds.add(occurrenceId);
  }
}

RecurringTransaction _template() => RecurringTransaction(
      id: 'rec-1',
      workspaceId: 'workspace-1',
      title: 'Rent',
      categoryId: 'cat-1',
      amountCents: 100000000,
      currency: 'VND',
      type: RecurringTransactionType.expense,
      frequency: RecurringFrequency.monthly,
      mode: RecurringMode.manualConfirm,
      intervalCount: 1,
      startDate: DateTime(2026, 5, 1),
      nextOccurrenceAt: DateTime(2026, 6, 1),
      reminderDaysBefore: 3,
      isActive: true,
      createdByUserId: 'user-1',
      updatedByUserId: 'user-1',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

RecurringOccurrence _occurrence() => RecurringOccurrence(
      id: 'occ-1',
      recurringTransactionId: 'rec-1',
      workspaceId: 'workspace-1',
      scheduledFor: DateTime(2026, 6, 1),
      remindAt: DateTime(2026, 5, 29),
      status: RecurringOccurrenceStatus.pending,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

Future<List<String>> _pumpWithFakeActions(WidgetTester tester) async {
  final skippedIds = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recurringTransactionsProvider
            .overrideWith((ref) async => [_template()]),
        upcomingRecurringOccurrencesProvider
            .overrideWith((ref) async => [_occurrence()]),
        recurringNotificationsPermissionProvider
            .overrideWith((ref) async => true),
        recurringActionsProvider.overrideWith(
          (ref) => _FakeRecurringActions(ref, skippedIds),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('vi'), Locale('ja')],
        home: RecurringTransactionsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return skippedIds;
}

Future<void> _skipFromSheet(WidgetTester tester) async {
  await tester.tap(find.text('Tap for details'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Skip').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('skipping an occurrence can be undone', (tester) async {
    final skippedIds = await _pumpWithFakeActions(tester);

    await _skipFromSheet(tester);
    expect(find.text('Occurrence skipped'), findsOneWidget);
    expect(find.text('Tap for details'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Tap for details'), findsOneWidget);
    expect(skippedIds, isEmpty);
  });

  testWidgets('skip is sent once the undo window closes', (tester) async {
    final skippedIds = await _pumpWithFakeActions(tester);

    await _skipFromSheet(tester);
    expect(skippedIds, isEmpty);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(skippedIds, ['occ-1']);
  });

  testWidgets(
      'RecurringTransactionsScreen shows upcoming occurrence and templates', (
    tester,
  ) async {
    final recurring = RecurringTransaction(
      id: 'rec-1',
      workspaceId: 'workspace-1',
      title: 'Rent',
      categoryId: 'cat-1',
      amountCents: 100000000,
      currency: 'VND',
      type: RecurringTransactionType.expense,
      frequency: RecurringFrequency.monthly,
      mode: RecurringMode.manualConfirm,
      intervalCount: 1,
      startDate: DateTime(2026, 5, 1),
      nextOccurrenceAt: DateTime(2026, 6, 1),
      reminderDaysBefore: 3,
      isActive: true,
      createdByUserId: 'user-1',
      updatedByUserId: 'user-1',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
    final occurrence = RecurringOccurrence(
      id: 'occ-1',
      recurringTransactionId: 'rec-1',
      workspaceId: 'workspace-1',
      scheduledFor: DateTime(2026, 6, 1),
      remindAt: DateTime(2026, 5, 29),
      status: RecurringOccurrenceStatus.pending,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringTransactionsProvider
              .overrideWith((ref) async => [recurring]),
          upcomingRecurringOccurrencesProvider
              .overrideWith((ref) async => [occurrence]),
          recurringNotificationsPermissionProvider
              .overrideWith((ref) async => true),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('vi'), Locale('ja')],
          home: RecurringTransactionsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsAtLeastNWidgets(1));
    expect(find.text('Upcoming reminders'), findsOneWidget);
    expect(find.text('Recurring templates'), findsOneWidget);
  });

  testWidgets(
      'RecurringTransactionsScreen opens occurrence detail when highlighted id is passed',
      (
    tester,
  ) async {
    final recurring = RecurringTransaction(
      id: 'rec-1',
      workspaceId: 'workspace-1',
      title: 'Rent',
      categoryId: 'cat-1',
      amountCents: 100000000,
      currency: 'VND',
      type: RecurringTransactionType.expense,
      frequency: RecurringFrequency.monthly,
      mode: RecurringMode.manualConfirm,
      intervalCount: 1,
      startDate: DateTime(2026, 5, 1),
      nextOccurrenceAt: DateTime(2026, 6, 1),
      reminderDaysBefore: 3,
      isActive: true,
      createdByUserId: 'user-1',
      updatedByUserId: 'user-1',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
    final occurrence = RecurringOccurrence(
      id: 'occ-1',
      recurringTransactionId: 'rec-1',
      workspaceId: 'workspace-1',
      scheduledFor: DateTime(2026, 6, 1),
      remindAt: DateTime(2026, 5, 29),
      status: RecurringOccurrenceStatus.pending,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringTransactionsProvider
              .overrideWith((ref) async => [recurring]),
          upcomingRecurringOccurrencesProvider
              .overrideWith((ref) async => [occurrence]),
          recurringNotificationsPermissionProvider
              .overrideWith((ref) async => true),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('vi'), Locale('ja')],
          home: RecurringTransactionsScreen(highlightedOccurrenceId: 'occ-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mark done'), findsOneWidget);
    expect(find.text('Skip'), findsWidgets);
  });
}
