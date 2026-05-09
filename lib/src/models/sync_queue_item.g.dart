// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncQueueItemImpl _$$SyncQueueItemImplFromJson(Map<String, dynamic> json) =>
    _$SyncQueueItemImpl(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: $enumDecode(_$SyncOperationEnumMap, json['operation']),
      status: $enumDecode(_$SyncQueueStatusEnumMap, json['status']),
      retryCount: (json['retryCount'] as num).toInt(),
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
    );

Map<String, dynamic> _$$SyncQueueItemImplToJson(_$SyncQueueItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'operation': _$SyncOperationEnumMap[instance.operation]!,
      'status': _$SyncQueueStatusEnumMap[instance.status]!,
      'retryCount': instance.retryCount,
      'errorMessage': instance.errorMessage,
      'createdAt': instance.createdAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
    };

const _$SyncOperationEnumMap = {
  SyncOperation.create: 'create',
  SyncOperation.update: 'update',
  SyncOperation.delete: 'delete',
};

const _$SyncQueueStatusEnumMap = {
  SyncQueueStatus.pending: 'pending',
  SyncQueueStatus.processing: 'processing',
  SyncQueueStatus.completed: 'completed',
  SyncQueueStatus.failed: 'failed',
};
