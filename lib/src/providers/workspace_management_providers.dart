// path: lib/src/providers/workspace_management_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/workspace_management_models.dart';
import '../services/workspace_management_service.dart';
import 'auth_providers.dart';
import 'workspace_providers.dart';

final workspaceManagementServiceProvider =
    Provider<WorkspaceManagementService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return WorkspaceManagementService(supabase);
});

final workspaceMembersProvider =
    FutureProvider<List<WorkspaceMemberSummary>>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  if (activeWorkspace == null) {
    return [];
  }

  final service = ref.watch(workspaceManagementServiceProvider);
  return service.getWorkspaceMembers(activeWorkspace.id);
});

final workspacePendingInvitesProvider =
    FutureProvider<List<WorkspaceInviteSummary>>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  final isOwner = ref.watch(isWorkspaceOwnerProvider);
  if (activeWorkspace == null || !isOwner) {
    return [];
  }

  final service = ref.watch(workspaceManagementServiceProvider);
  return service.getPendingInvites(activeWorkspace.id);
});
