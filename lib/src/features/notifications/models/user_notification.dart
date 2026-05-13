class UserNotification {
  const UserNotification({
    required this.id,
    required this.recipientUserId,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String recipientUserId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;
  bool get isWorkspaceInvite => type == 'workspace_invite';

  String? get inviteId => payload['invite_id'] as String?;
  String? get inviteToken => payload['invite_token'] as String?;
  String? get workspaceId => payload['workspace_id'] as String?;
  String? get workspaceName => payload['workspace_name'] as String?;
  String? get invitedByEmail => payload['invited_by_email'] as String?;
  String? get invitedByDisplayName =>
      payload['invited_by_display_name'] as String?;

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    return UserNotification(
      id: map['id'] as String,
      recipientUserId: map['recipient_user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      payload: (map['payload'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      readAt: map['read_at'] == null
          ? null
          : DateTime.parse(map['read_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
