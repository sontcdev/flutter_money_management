import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_management_service.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';

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
