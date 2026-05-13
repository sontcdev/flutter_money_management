// path: lib/src/models/workspace.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace.freezed.dart';
part 'workspace.g.dart';

@freezed
class Workspace with _$Workspace {
  const factory Workspace({
    required String id,
    required String name,
    required String type,
    required String ownerId,
    required String role,
    String? description,
    String? avatarPath,
    int? memberCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Workspace;

  factory Workspace.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceFromJson(json);
}
