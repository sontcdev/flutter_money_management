// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkspaceImpl _$$WorkspaceImplFromJson(Map<String, dynamic> json) =>
    _$WorkspaceImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      ownerId: json['ownerId'] as String,
      role: json['role'] as String,
      description: json['description'] as String?,
      avatarPath: json['avatarPath'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$WorkspaceImplToJson(_$WorkspaceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'ownerId': instance.ownerId,
      'role': instance.role,
      'description': instance.description,
      'avatarPath': instance.avatarPath,
      'memberCount': instance.memberCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
