import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';

/// Provider for Supabase client (re-exported for convenience)
final supabaseProvider = supabaseClientProvider;

/// Provider that fetches the list of workspaces for the current user
final workspaceListProvider = FutureProvider<List<Workspace>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final session = ref.watch(currentSessionProvider);

  if (session == null) {
    AppLogger.debug('No session, returning empty workspace list',
        name: 'MM.Workspace');
    return [];
  }

  try {
    AppLogger.info('Workspace fetch started', name: 'MM.Workspace');
    // Fetch workspaces where user is a member
    final response = await supabase
        .from('workspace_members')
        .select('''
          workspace_id,
          role,
          workspaces!inner(
            id,
            type,
            name,
            settings,
            owner_user_id,
            created_at,
            updated_at
          )
        ''')
        .eq('user_id', session.user.id)
        .isFilter('workspaces.deleted_at', null);

    final workspaces = <Workspace>[];
    for (final item in response as List) {
      final workspaceData = item['workspaces'] as Map<String, dynamic>;
      workspaces.add(Workspace(
        id: workspaceData['id'] as String,
        name: workspaceData['name'] as String,
        type: workspaceData['type'] as String,
        ownerId: workspaceData['owner_user_id'] as String,
        role: item['role'] as String,
        description:
            (workspaceData['settings'] as Map?)?['description'] as String?,
        avatarPath:
            (workspaceData['settings'] as Map?)?['avatar_path'] as String?,
        createdAt: DateTime.parse(workspaceData['created_at'] as String),
        updatedAt: DateTime.parse(workspaceData['updated_at'] as String),
      ));
    }

    AppLogger.info(
      'Workspace fetch completed: ${workspaces.length} workspaces',
      name: 'MM.Workspace',
    );
    return workspaces;
  } catch (e, stackTrace) {
    AppLogger.error(
      'Workspace fetch failed',
      name: 'MM.Workspace',
      error: e,
      stackTrace: stackTrace,
    );
    throw Exception('Failed to fetch workspaces: $e');
  }
});

/// Provider for the currently active workspace ID
/// Stored in SharedPreferences for persistence
final activeWorkspaceIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the currently active workspace
final activeWorkspaceProvider = Provider<Workspace?>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final workspaces = ref.watch(workspaceListProvider);

  return workspaces.when(
    data: (list) {
      if (workspaceId == null || list.isEmpty) {
        return list.isNotEmpty ? list.first : null;
      }
      return list.firstWhere(
        (w) => w.id == workspaceId,
        orElse: () => list.first,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider to check if user has any workspaces
final hasWorkspacesProvider = Provider<bool>((ref) {
  final workspaces = ref.watch(workspaceListProvider);
  return workspaces.maybeWhen(
    data: (list) => list.isNotEmpty,
    orElse: () => false,
  );
});

/// Provider to check if user is owner of active workspace
final isWorkspaceOwnerProvider = Provider<bool>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  final session = ref.watch(currentSessionProvider);

  if (workspace == null || session == null) {
    return false;
  }

  return workspace.ownerId == session.user.id;
});

/// Provider to get user's role in active workspace
final workspaceRoleProvider = Provider<String?>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  return workspace?.role;
});

final isPersonalWorkspaceProvider = Provider<bool>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  return workspace?.type == 'personal';
});

final isWorkspaceAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(workspaceRoleProvider);
  return role == 'admin';
});

final canManageWorkspaceMembersProvider = Provider<bool>((ref) {
  final role = ref.watch(workspaceRoleProvider);
  return role == 'owner' || role == 'admin';
});

final canManageWorkspaceContentProvider = Provider<bool>((ref) {
  final role = ref.watch(workspaceRoleProvider);
  return role == 'owner' || role == 'admin';
});

final canLeaveWorkspaceProvider = Provider<bool>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  final role = ref.watch(workspaceRoleProvider);
  if (workspace == null || workspace.type == 'personal') {
    return false;
  }
  return role != 'owner';
});

/// Helper to clear active workspace (for sign out)
void clearActiveWorkspace(WidgetRef ref) {
  ref.read(activeWorkspaceIdProvider.notifier).state = null;
}
