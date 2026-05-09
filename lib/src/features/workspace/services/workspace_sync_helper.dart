import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';

Future<String?> syncCurrentWorkspaceData(
  Object ref, {
  bool refreshWorkspaceList = false,
}) async {
  AppLogger.info('Sync requested for current workspace', name: 'MM.Sync');

  final session = _read(ref, currentSessionProvider);
  if (session == null) {
    AppLogger.debug('No active session, skipping sync', name: 'MM.Sync');
    return null;
  }

  if (refreshWorkspaceList) {
    AppLogger.debug('Refreshing workspace list before sync', name: 'MM.Sync');
    _invalidate(ref, workspaceListProvider);
  }

  var workspaceId = _read<String?>(ref, activeWorkspaceIdProvider);

  if (workspaceId == null || workspaceId.isEmpty) {
    AppLogger.info('Active workspace missing, resolving fallback',
        name: 'MM.Workspace');
    final workspaces = await _read(ref, workspaceListProvider.future);
    if (workspaces.isEmpty) {
      AppLogger.warn('No workspaces available for sync', name: 'MM.Workspace');
      return null;
    }
    workspaceId = workspaces.first.id;
    _read(ref, activeWorkspaceIdProvider.notifier).state = workspaceId;
    AppLogger.info('Resolved active workspace for sync', name: 'MM.Workspace');
  }

  try {
    AppLogger.debug('Invalidating core providers for sync', name: 'MM.Sync');
    invalidateCoreDataProviders(ref);
    AppLogger.info('Sync completed for current workspace', name: 'MM.Sync');
  } catch (e, stackTrace) {
    AppLogger.error(
      'Sync failed for current workspace',
      name: 'MM.Sync',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }

  return workspaceId;
}

void invalidateCoreDataProviders(Object ref) {
  _invalidate(ref, categoriesProvider);
}

T _read<T>(Object ref, ProviderListenable<T> provider) {
  if (ref is WidgetRef) {
    return ref.read(provider);
  }
  if (ref is Ref) {
    return ref.read(provider);
  }
  throw ArgumentError('Unsupported ref type: ${ref.runtimeType}');
}

void _invalidate(Object ref, ProviderOrFamily provider) {
  if (ref is WidgetRef) {
    ref.invalidate(provider);
    return;
  }
  if (ref is Ref) {
    ref.invalidate(provider);
    return;
  }
  throw ArgumentError('Unsupported ref type: ${ref.runtimeType}');
}
