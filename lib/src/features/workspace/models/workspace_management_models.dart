// path: lib/src/models/workspace_management_models.dart

class WorkspaceMemberSummary {
  const WorkspaceMemberSummary({
    required this.memberId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.membershipStatus,
    required this.joinedAt,
  });

  final String memberId;
  final String userId;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String role;
  final String membershipStatus;
  final DateTime? joinedAt;

  factory WorkspaceMemberSummary.fromMap(Map<String, dynamic> map) {
    return WorkspaceMemberSummary(
      memberId: map['member_id'] as String,
      userId: map['user_id'] as String,
      displayName: map['display_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String,
      membershipStatus: map['membership_status'] as String,
      joinedAt: map['joined_at'] == null
          ? null
          : DateTime.parse(map['joined_at'] as String),
    );
  }
}

class WorkspaceInviteSummary {
  const WorkspaceInviteSummary({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.matchedUserId,
    required this.matchedDisplayName,
    required this.matchedAvatarUrl,
  });

  final String id;
  final String email;
  final String role;
  final String status;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? matchedUserId;
  final String? matchedDisplayName;
  final String? matchedAvatarUrl;

  factory WorkspaceInviteSummary.fromMap(Map<String, dynamic> map) {
    return WorkspaceInviteSummary(
      id: map['id'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
      matchedUserId: map['matched_user_id'] as String?,
      matchedDisplayName: map['matched_display_name'] as String?,
      matchedAvatarUrl: map['matched_avatar_url'] as String?,
    );
  }
}

class WorkspaceInviteNotification {
  const WorkspaceInviteNotification({
    required this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.email,
    required this.role,
    required this.status,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
    required this.invitedByUserId,
    required this.invitedByEmail,
    required this.invitedByDisplayName,
  });

  final String id;
  final String workspaceId;
  final String workspaceName;
  final String email;
  final String role;
  final String status;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? invitedByUserId;
  final String? invitedByEmail;
  final String? invitedByDisplayName;

  factory WorkspaceInviteNotification.fromMap(Map<String, dynamic> map) {
    return WorkspaceInviteNotification(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      workspaceName: map['workspace_name'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      invitedByUserId: map['invited_by_user_id'] as String?,
      invitedByEmail: map['invited_by_email'] as String?,
      invitedByDisplayName: map['invited_by_display_name'] as String?,
    );
  }
}

class WorkspaceDetailSummary {
  const WorkspaceDetailSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerUserId,
    required this.description,
    required this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
    required this.memberCount,
    required this.currentUserRole,
  });

  final String id;
  final String name;
  final String type;
  final String ownerUserId;
  final String? description;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final String currentUserRole;

  bool get isPersonal => type == 'personal';
  bool get isOwner => currentUserRole == 'owner';
  bool get isAdmin => currentUserRole == 'admin';
  bool get canManageContent => isOwner || isAdmin;

  factory WorkspaceDetailSummary.fromMap(Map<String, dynamic> map) {
    return WorkspaceDetailSummary(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      ownerUserId: map['owner_user_id'] as String,
      description: map['description'] as String?,
      avatarPath: map['avatar_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      memberCount: (map['member_count'] as num?)?.toInt() ?? 0,
      currentUserRole: map['current_user_role'] as String,
    );
  }
}

class WorkspaceInvitePreviewMember {
  const WorkspaceInvitePreviewMember({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String role;
  final DateTime? joinedAt;

  factory WorkspaceInvitePreviewMember.fromMap(Map<String, dynamic> map) {
    return WorkspaceInvitePreviewMember(
      userId: map['user_id'] as String,
      displayName: map['display_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String,
      joinedAt: map['joined_at'] == null
          ? null
          : DateTime.parse(map['joined_at'] as String),
    );
  }
}

class WorkspaceInvitePreview {
  const WorkspaceInvitePreview({
    required this.workspaceId,
    required this.workspaceName,
    required this.workspaceType,
    required this.description,
    required this.avatarPath,
    required this.email,
    required this.role,
    required this.token,
    required this.expiresAt,
    required this.invitedByUserId,
    required this.invitedByDisplayName,
    required this.invitedByEmail,
    required this.members,
  });

  final String workspaceId;
  final String workspaceName;
  final String workspaceType;
  final String? description;
  final String? avatarPath;
  final String email;
  final String role;
  final String token;
  final DateTime expiresAt;
  final String? invitedByUserId;
  final String? invitedByDisplayName;
  final String? invitedByEmail;
  final List<WorkspaceInvitePreviewMember> members;

  factory WorkspaceInvitePreview.fromMap(Map<String, dynamic> map) {
    final rawMembers =
        (map['members'] as List?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    return WorkspaceInvitePreview(
      workspaceId: map['workspace_id'] as String,
      workspaceName: map['workspace_name'] as String,
      workspaceType: map['workspace_type'] as String,
      description: map['description'] as String?,
      avatarPath: map['avatar_path'] as String?,
      email: map['email'] as String,
      role: map['role'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      invitedByUserId: map['invited_by_user_id'] as String?,
      invitedByDisplayName: map['invited_by_display_name'] as String?,
      invitedByEmail: map['invited_by_email'] as String?,
      members: rawMembers.map(WorkspaceInvitePreviewMember.fromMap).toList(),
    );
  }
}

class WorkspaceActivityItem {
  const WorkspaceActivityItem({
    required this.id,
    required this.workspaceId,
    required this.actorUserId,
    required this.actorDisplayName,
    required this.actorEmail,
    required this.actorAvatarUrl,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.summary,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String workspaceId;
  final String actorUserId;
  final String? actorDisplayName;
  final String? actorEmail;
  final String? actorAvatarUrl;
  final String entityType;
  final String entityId;
  final String action;
  final String? summary;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory WorkspaceActivityItem.fromMap(Map<String, dynamic> map) {
    return WorkspaceActivityItem(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      actorUserId: map['actor_user_id'] as String,
      actorDisplayName: map['actor_display_name'] as String?,
      actorEmail: map['actor_email'] as String?,
      actorAvatarUrl: map['actor_avatar_url'] as String?,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      action: map['action'] as String,
      summary: map['summary'] as String?,
      payload: (map['payload'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
