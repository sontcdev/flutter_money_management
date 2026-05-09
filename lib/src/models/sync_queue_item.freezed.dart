// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_queue_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SyncQueueItem _$SyncQueueItemFromJson(Map<String, dynamic> json) {
  return _SyncQueueItem.fromJson(json);
}

/// @nodoc
mixin _$SyncQueueItem {
  String get id => throw _privateConstructorUsedError;
  String get entityType =>
      throw _privateConstructorUsedError; // 'transaction', 'budget', 'category'
  String get entityId => throw _privateConstructorUsedError;
  SyncOperation get operation => throw _privateConstructorUsedError;
  SyncQueueStatus get status => throw _privateConstructorUsedError;
  int get retryCount => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get processedAt => throw _privateConstructorUsedError;

  /// Serializes this SyncQueueItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncQueueItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncQueueItemCopyWith<SyncQueueItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncQueueItemCopyWith<$Res> {
  factory $SyncQueueItemCopyWith(
          SyncQueueItem value, $Res Function(SyncQueueItem) then) =
      _$SyncQueueItemCopyWithImpl<$Res, SyncQueueItem>;
  @useResult
  $Res call(
      {String id,
      String entityType,
      String entityId,
      SyncOperation operation,
      SyncQueueStatus status,
      int retryCount,
      String? errorMessage,
      DateTime createdAt,
      DateTime? processedAt});
}

/// @nodoc
class _$SyncQueueItemCopyWithImpl<$Res, $Val extends SyncQueueItem>
    implements $SyncQueueItemCopyWith<$Res> {
  _$SyncQueueItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncQueueItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? operation = null,
    Object? status = null,
    Object? retryCount = null,
    Object? errorMessage = freezed,
    Object? createdAt = null,
    Object? processedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      operation: null == operation
          ? _value.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as SyncOperation,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncQueueStatus,
      retryCount: null == retryCount
          ? _value.retryCount
          : retryCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncQueueItemImplCopyWith<$Res>
    implements $SyncQueueItemCopyWith<$Res> {
  factory _$$SyncQueueItemImplCopyWith(
          _$SyncQueueItemImpl value, $Res Function(_$SyncQueueItemImpl) then) =
      __$$SyncQueueItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String entityType,
      String entityId,
      SyncOperation operation,
      SyncQueueStatus status,
      int retryCount,
      String? errorMessage,
      DateTime createdAt,
      DateTime? processedAt});
}

/// @nodoc
class __$$SyncQueueItemImplCopyWithImpl<$Res>
    extends _$SyncQueueItemCopyWithImpl<$Res, _$SyncQueueItemImpl>
    implements _$$SyncQueueItemImplCopyWith<$Res> {
  __$$SyncQueueItemImplCopyWithImpl(
      _$SyncQueueItemImpl _value, $Res Function(_$SyncQueueItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncQueueItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? operation = null,
    Object? status = null,
    Object? retryCount = null,
    Object? errorMessage = freezed,
    Object? createdAt = null,
    Object? processedAt = freezed,
  }) {
    return _then(_$SyncQueueItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      operation: null == operation
          ? _value.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as SyncOperation,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncQueueStatus,
      retryCount: null == retryCount
          ? _value.retryCount
          : retryCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncQueueItemImpl implements _SyncQueueItem {
  const _$SyncQueueItemImpl(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.status,
      required this.retryCount,
      this.errorMessage,
      required this.createdAt,
      this.processedAt});

  factory _$SyncQueueItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncQueueItemImplFromJson(json);

  @override
  final String id;
  @override
  final String entityType;
// 'transaction', 'budget', 'category'
  @override
  final String entityId;
  @override
  final SyncOperation operation;
  @override
  final SyncQueueStatus status;
  @override
  final int retryCount;
  @override
  final String? errorMessage;
  @override
  final DateTime createdAt;
  @override
  final DateTime? processedAt;

  @override
  String toString() {
    return 'SyncQueueItem(id: $id, entityType: $entityType, entityId: $entityId, operation: $operation, status: $status, retryCount: $retryCount, errorMessage: $errorMessage, createdAt: $createdAt, processedAt: $processedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncQueueItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.retryCount, retryCount) ||
                other.retryCount == retryCount) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, entityType, entityId,
      operation, status, retryCount, errorMessage, createdAt, processedAt);

  /// Create a copy of SyncQueueItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncQueueItemImplCopyWith<_$SyncQueueItemImpl> get copyWith =>
      __$$SyncQueueItemImplCopyWithImpl<_$SyncQueueItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncQueueItemImplToJson(
      this,
    );
  }
}

abstract class _SyncQueueItem implements SyncQueueItem {
  const factory _SyncQueueItem(
      {required final String id,
      required final String entityType,
      required final String entityId,
      required final SyncOperation operation,
      required final SyncQueueStatus status,
      required final int retryCount,
      final String? errorMessage,
      required final DateTime createdAt,
      final DateTime? processedAt}) = _$SyncQueueItemImpl;

  factory _SyncQueueItem.fromJson(Map<String, dynamic> json) =
      _$SyncQueueItemImpl.fromJson;

  @override
  String get id;
  @override
  String get entityType; // 'transaction', 'budget', 'category'
  @override
  String get entityId;
  @override
  SyncOperation get operation;
  @override
  SyncQueueStatus get status;
  @override
  int get retryCount;
  @override
  String? get errorMessage;
  @override
  DateTime get createdAt;
  @override
  DateTime? get processedAt;

  /// Create a copy of SyncQueueItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncQueueItemImplCopyWith<_$SyncQueueItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
