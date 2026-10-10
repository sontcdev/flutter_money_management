import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_deletion_blocker.freezed.dart';
part 'account_deletion_blocker.g.dart';

@freezed
class AccountDeletionBlocker with _$AccountDeletionBlocker {
  const factory AccountDeletionBlocker({
    required String workspaceId,
    required String workspaceName,
  }) = _AccountDeletionBlocker;

  factory AccountDeletionBlocker.fromMap(Map<String, dynamic> row) =>
      AccountDeletionBlocker(
        workspaceId: row['workspace_id'] as String,
        workspaceName: row['workspace_name'] as String,
      );

  factory AccountDeletionBlocker.fromJson(Map<String, dynamic> json) =>
      _$AccountDeletionBlockerFromJson(json);
}
