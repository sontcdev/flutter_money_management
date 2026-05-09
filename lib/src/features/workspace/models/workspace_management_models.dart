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
      matchedUserId: map['matched_user_id'] as String?,
      matchedDisplayName: map['matched_display_name'] as String?,
      matchedAvatarUrl: map['matched_avatar_url'] as String?,
    );
  }
}
