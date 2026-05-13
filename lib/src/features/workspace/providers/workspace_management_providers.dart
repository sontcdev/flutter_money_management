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
  final canManageMembers = ref.watch(canManageWorkspaceMembersProvider);
  if (activeWorkspace == null || !canManageMembers) {
    return [];
  }

  final service = ref.watch(workspaceManagementServiceProvider);
  return service.getWorkspaceInvites(activeWorkspace.id);
});

final myWorkspaceInviteNotificationsProvider =
    FutureProvider<List<WorkspaceInviteNotification>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return [];
  }

  final service = ref.watch(workspaceManagementServiceProvider);
  return service.getMyPendingInvites();
});

final myWorkspaceInviteCountProvider = Provider<int>((ref) {
  final invitesAsync = ref.watch(myWorkspaceInviteNotificationsProvider);
  return invitesAsync.maybeWhen(
    data: (invites) => invites.length,
    orElse: () => 0,
  );
});

final workspaceDetailProvider =
    FutureProvider<WorkspaceDetailSummary?>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  if (activeWorkspace == null) {
    return null;
  }

  final service = ref.watch(workspaceManagementServiceProvider);
  return service.getWorkspaceDetail(activeWorkspace.id);
});

final workspaceActivityProvider =
    FutureProvider<List<WorkspaceActivityItem>>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  if (activeWorkspace == null) {
    return [];
  }

  final service = ref.watch(workspaceManagementServiceProvider);
  return service.getWorkspaceActivity(workspaceId: activeWorkspace.id);
});

final workspaceInvitePreviewProvider =
    FutureProvider.family<WorkspaceInvitePreview, String>((ref, token) async {
  final service = ref.watch(workspaceManagementServiceProvider);
  return service.getInvitePreview(token);
});
