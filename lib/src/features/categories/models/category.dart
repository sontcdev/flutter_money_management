// path: lib/src/models/category.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

enum CategoryType { expense, income }

enum SyncStatus { pending, synced, error }

@freezed
class Category with _$Category {
  const factory Category({
    required String id, // Changed from int to String (UUID)
    required String name,
    required String iconName,
    required int colorValue,
    @Default(CategoryType.expense) CategoryType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    DateTime? syncedAt,
    String? lastSyncError,
    DateTime? deletedAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
