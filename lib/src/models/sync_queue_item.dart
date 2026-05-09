// path: lib/src/models/sync_queue_item.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue_item.freezed.dart';
part 'sync_queue_item.g.dart';

enum SyncOperation { create, update, delete }

enum SyncQueueStatus { pending, processing, completed, failed }

@freezed
class SyncQueueItem with _$SyncQueueItem {
  const factory SyncQueueItem({
    required String id,
    required String entityType, // 'transaction', 'budget', 'category'
    required String entityId,
    required SyncOperation operation,
    required SyncQueueStatus status,
    required int retryCount,
    String? errorMessage,
    required DateTime createdAt,
    DateTime? processedAt,
  }) = _SyncQueueItem;

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueItemFromJson(json);
}
