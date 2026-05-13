import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/features/recurring/services/recurring_reminder_service.dart';

class _FakeNotificationsGateway implements LocalNotificationsGateway {
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];
  final List<String?> scheduledPayloads = [];
  List<PendingNotificationRequest> pending = const [];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async {
    return const NotificationAppLaunchDetails(false);
  }

  @override
  Future<bool?> requestNotificationsPermission() async => true;

  @override
  Future<bool?> areNotificationsEnabled() async => true;

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return pending;
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required UILocalNotificationDateInterpretation
        uiLocalNotificationDateInterpretation,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduledIds.add(id);
    scheduledPayloads.add(payload);
  }
}

void main() {
  test(
      'syncPendingRecurringReminders schedules future pending reminders and cancels stale ones',
      () async {
    final gateway = _FakeNotificationsGateway();
    final service = RecurringReminderService(gateway);
    final occurrence = RecurringOccurrence(
      id: 'occ-1',
      recurringTransactionId: 'rec-1',
      workspaceId: 'workspace-1',
      scheduledFor: DateTime.now().add(const Duration(days: 2)),
      remindAt: DateTime.now().add(const Duration(days: 1)),
      status: RecurringOccurrenceStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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
      startDate: DateTime.now(),
      nextOccurrenceAt: DateTime.now().add(const Duration(days: 2)),
      reminderDaysBefore: 1,
      isActive: true,
      createdByUserId: 'user-1',
      updatedByUserId: 'user-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    gateway.pending = const [
      PendingNotificationRequest(
          42, 'old', 'old', '{"type":"recurring_occurrence"}'),
    ];

    await service.syncPendingRecurringReminders(
      occurrences: [occurrence],
      recurringById: {recurring.id: recurring},
    );

    expect(gateway.scheduledIds, hasLength(1));
    expect(gateway.cancelledIds, contains(42));
    expect(
      jsonDecode(gateway.scheduledPayloads.single!)['occurrence_id'],
      'occ-1',
    );
  });
}
