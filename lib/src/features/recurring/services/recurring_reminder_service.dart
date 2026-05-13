import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_money_management/src/features/recurring/models/recurring_occurrence.dart';
import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';

abstract class LocalNotificationsGateway {
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  });

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
  });

  Future<void> cancel(int id, {String? tag});

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();

  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails();

  Future<bool?> requestNotificationsPermission();

  Future<bool?> areNotificationsEnabled();
}

class FlutterLocalNotificationsGateway implements LocalNotificationsGateway {
  const FlutterLocalNotificationsGateway(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) {
    return _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
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
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          uiLocalNotificationDateInterpretation,
      androidScheduleMode: androidScheduleMode,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  @override
  Future<void> cancel(int id, {String? tag}) => _plugin.cancel(id, tag: tag);

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() {
    return _plugin.pendingNotificationRequests();
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() {
    return _plugin.getNotificationAppLaunchDetails();
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    if (kIsWeb) {
      return false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return android.requestNotificationsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      return macos.requestPermissions(alert: true, badge: true, sound: true);
    }

    return false;
  }

  @override
  Future<bool?> areNotificationsEnabled() async {
    if (kIsWeb) {
      return false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return android.areNotificationsEnabled();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled ?? false;
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      final permissions = await macos.checkPermissions();
      return permissions?.isEnabled ?? false;
    }

    return false;
  }
}

class RecurringNotificationIntent {
  const RecurringNotificationIntent({
    required this.occurrenceId,
    required this.workspaceId,
  });

  final String occurrenceId;
  final String workspaceId;
}

class RecurringReminderService {
  RecurringReminderService(this._gateway);

  static const _androidChannelId = 'recurring_reminders';
  static const _androidChannelName = 'Recurring reminders';
  static const _androidChannelDescription =
      'Notifications for recurring transactions and reminders';
  static const _payloadType = 'recurring_occurrence';

  final LocalNotificationsGateway _gateway;
  bool _initialized = false;
  bool _launchIntentHandled = false;
  final _notificationIntentController =
      StreamController<RecurringNotificationIntent>.broadcast();

  Stream<RecurringNotificationIntent> get notificationIntents =>
      _notificationIntentController.stream;

  Future<void> ensureInitialized() async {
    if (_initialized) {
      await _publishLaunchIntentIfNeeded();
      return;
    }

    tz_data.initializeTimeZones();
    await _gateway.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        _publishPayload(response.payload);
      },
    );
    _initialized = true;
    await _publishLaunchIntentIfNeeded();
  }

  Future<bool> requestPermission() async {
    await ensureInitialized();
    return await _gateway.requestNotificationsPermission() ?? false;
  }

  Future<bool> areNotificationsAllowed() async {
    await ensureInitialized();
    return await _gateway.areNotificationsEnabled() ?? false;
  }

  Future<void> syncPendingRecurringReminders({
    required List<RecurringOccurrence> occurrences,
    required Map<String, RecurringTransaction> recurringById,
  }) async {
    await ensureInitialized();

    final pending = await _gateway.pendingNotificationRequests();
    final expectedIds = <int>{};
    for (final occurrence in occurrences) {
      if (occurrence.status != RecurringOccurrenceStatus.pending) {
        continue;
      }
      if (occurrence.remindAt.isBefore(DateTime.now())) {
        continue;
      }
      final recurring = recurringById[occurrence.recurringTransactionId];
      if (recurring == null || !recurring.isActive) {
        continue;
      }
      final notificationId = _notificationIdForOccurrence(occurrence.id);
      expectedIds.add(notificationId);
      await _scheduleOccurrenceReminder(
        notificationId: notificationId,
        occurrence: occurrence,
        recurringTransaction: recurring,
      );
    }

    for (final request in pending) {
      final payload = request.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }
      final decoded = _tryDecodePayload(payload);
      if (decoded == null || decoded['type'] != _payloadType) {
        continue;
      }
      if (!expectedIds.contains(request.id)) {
        await _gateway.cancel(request.id);
      }
    }
  }

  Future<void> _scheduleOccurrenceReminder({
    required int notificationId,
    required RecurringOccurrence occurrence,
    required RecurringTransaction recurringTransaction,
  }) async {
    final scheduledAtUtc = tz.TZDateTime.from(
      occurrence.remindAt.toUtc(),
      tz.UTC,
    );
    final payload = jsonEncode({
      'type': _payloadType,
      'occurrence_id': occurrence.id,
      'workspace_id': occurrence.workspaceId,
    });

    await _gateway.zonedSchedule(
      notificationId,
      recurringTransaction.title,
      _buildBody(recurringTransaction),
      scheduledAtUtc,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    AppLogger.info(
      'Recurring reminder scheduled',
      name: 'MM.RecurringReminder',
      error: {
        'occurrence_id': occurrence.id,
        'notification_id': notificationId,
      },
    );
  }

  String _buildBody(RecurringTransaction recurringTransaction) {
    final amount = recurringTransaction.amountCents / 100;
    final amountLabel = amount.toStringAsFixed(0);
    return '${recurringTransaction.type.name}: $amountLabel ${recurringTransaction.currency}';
  }

  int _notificationIdForOccurrence(String occurrenceId) {
    return occurrenceId.hashCode & 0x7fffffff;
  }

  Map<String, dynamic>? _tryDecodePayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _publishLaunchIntentIfNeeded() async {
    if (_launchIntentHandled) {
      return;
    }

    final details = await _gateway.getNotificationAppLaunchDetails();
    _launchIntentHandled = true;
    if (details?.didNotificationLaunchApp != true) {
      return;
    }

    _publishPayload(details?.notificationResponse?.payload);
  }

  void _publishPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    final decoded = _tryDecodePayload(payload);
    if (decoded == null || decoded['type'] != _payloadType) {
      return;
    }

    final occurrenceId = decoded['occurrence_id'] as String?;
    final workspaceId = decoded['workspace_id'] as String?;
    if (occurrenceId == null || workspaceId == null) {
      return;
    }

    _notificationIntentController.add(
      RecurringNotificationIntent(
        occurrenceId: occurrenceId,
        workspaceId: workspaceId,
      ),
    );
  }
}
