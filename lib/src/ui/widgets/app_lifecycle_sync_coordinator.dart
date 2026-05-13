import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';

import '../../app.dart';
import '../../features/recurring/providers/recurring_providers.dart';
import '../../features/workspace/providers/workspace_providers.dart';
import '../../features/workspace/services/workspace_sync_helper.dart';
import '../../utils/app_logger.dart';

class AppLifecycleSyncCoordinator extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleSyncCoordinator({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLifecycleSyncCoordinator> createState() =>
      _AppLifecycleSyncCoordinatorState();
}

class _AppLifecycleSyncCoordinatorState
    extends ConsumerState<AppLifecycleSyncCoordinator>
    with WidgetsBindingObserver {
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  static const _cooldown = Duration(seconds: 20);
  StreamSubscription? _notificationIntentSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindNotificationIntents();
      _syncRecurringReminders();
    });
  }

  @override
  void dispose() {
    _notificationIntentSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.debug('App resumed', name: 'MM.Sync');
      _syncOnResume();
    }
  }

  Future<void> _syncOnResume() async {
    if (_isSyncing) {
      AppLogger.debug('Resume sync skipped: already syncing', name: 'MM.Sync');
      return;
    }

    final now = DateTime.now();
    if (_lastSyncedAt != null && now.difference(_lastSyncedAt!) < _cooldown) {
      AppLogger.debug('Resume sync skipped: cooldown active', name: 'MM.Sync');
      return;
    }

    _isSyncing = true;
    try {
      AppLogger.info('Resume sync started', name: 'MM.Sync');
      await syncCurrentWorkspaceData(ref, refreshWorkspaceList: true);
      await _syncRecurringReminders();
      _lastSyncedAt = DateTime.now();
      AppLogger.info('Resume sync succeeded', name: 'MM.Sync');
    } catch (e, stackTrace) {
      // Keep app responsive on resume even if sync fails.
      AppLogger.warn(
        'Resume sync failed',
        name: 'MM.Sync',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncRecurringReminders() async {
    try {
      await ref
          .read(recurringActionsProvider.notifier)
          .syncRecurringReminders();
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Recurring reminder sync failed',
        name: 'MM.RecurringReminder',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _bindNotificationIntents() {
    _notificationIntentSubscription?.cancel();
    final service = ref.read(recurringReminderServiceProvider);
    _notificationIntentSubscription =
        service.notificationIntents.listen((intent) {
      ref.read(activeWorkspaceIdProvider.notifier).state = intent.workspaceId;
      appNavigatorKey.currentState?.pushNamed(
        '/recurring-transactions',
        arguments: {'occurrenceId': intent.occurrenceId},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
