import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';

class WorkspaceManagementService {
  WorkspaceManagementService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<WorkspaceMemberSummary>> getWorkspaceMembers(
    String workspaceId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_workspace_members_with_profiles',
        params: {'p_workspace_id': workspaceId},
      );

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(WorkspaceMemberSummary.fromMap)
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        // Function not found in database - return empty list as fallback
        debugPrint(
          'Warning: get_workspace_members_with_profiles function not found in database',
        );
        return [];
      }
      rethrow;
    }
  }

  Future<List<WorkspaceInviteSummary>> getWorkspaceInvites(
      String workspaceId) async {
    try {
      final response = await _supabase.rpc(
        'get_workspace_invites_with_profiles',
        params: {'p_workspace_id': workspaceId},
      );

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(WorkspaceInviteSummary.fromMap)
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        debugPrint(
          'Warning: get_workspace_invites_with_profiles function not found in database',
        );
        return [];
      }
      rethrow;
    }
  }

  Future<WorkspaceInviteSummary> createInvite({
    required String workspaceId,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ArgumentError('Email is required');
    }

    final response = await _supabase.rpc(
      'create_workspace_invite',
      params: {
        'p_workspace_id': workspaceId,
        'p_email': normalizedEmail,
      },
    );

    return WorkspaceInviteSummary.fromMap(
      (response as List).cast<Map<String, dynamic>>().single,
    );
  }

  Future<List<WorkspaceInviteNotification>> getMyPendingInvites() async {
    final response = await _supabase.rpc('get_my_pending_workspace_invites');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(WorkspaceInviteNotification.fromMap)
        .toList();
  }

  Future<void> revokeInvite(String inviteId) async {
    await _supabase.rpc('revoke_workspace_invite', params: {
      'invite_id': inviteId,
    });
  }

  Future<void> declineInvite(String token) async {
    final response = await _supabase.rpc('decline_workspace_invite', params: {
      'invite_token': token.trim(),
    });

    final payload = response as Map<String, dynamic>;
    final success = payload['success'] == true;
    if (!success) {
      throw StateError(
        payload['error']?.toString() ?? 'Unable to decline workspace invite',
      );
    }
  }

  Future<WorkspaceInviteSummary> refreshInvite(String inviteId) async {
    final response = await _supabase.rpc('refresh_workspace_invite', params: {
      'p_invite_id': inviteId,
    });

    return WorkspaceInviteSummary.fromMap(
      (response as List).cast<Map<String, dynamic>>().single,
    );
  }

  Future<void> removeMember({
    required String workspaceId,
    required String userId,
  }) async {
    await _supabase.rpc('remove_workspace_member', params: {
      'p_workspace_id': workspaceId,
      'p_user_id': userId,
    });
  }

  Future<String> acceptInvite(String token) async {
    final response = await _supabase.rpc('accept_workspace_invite', params: {
      'invite_token': token.trim(),
    });

    final payload = response as Map<String, dynamic>;
    final success = payload['success'] == true;
    if (!success) {
      throw StateError(
          payload['error']?.toString() ?? 'Unable to join workspace');
    }

    return payload['workspace_id'] as String;
  }
}
