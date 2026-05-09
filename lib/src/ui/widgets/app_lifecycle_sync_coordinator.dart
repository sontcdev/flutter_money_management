import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
