// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Budget _$BudgetFromJson(Map<String, dynamic> json) {
  return _Budget.fromJson(json);
}

/// @nodoc
mixin _$Budget {
  String get id => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  PeriodType get periodType => throw _privateConstructorUsedError;
  DateTime get periodStart => throw _privateConstructorUsedError;
  DateTime get periodEnd => throw _privateConstructorUsedError;
  int get limitCents => throw _privateConstructorUsedError;
  int get consumedCents => throw _privateConstructorUsedError;
  bool get allowOverdraft => throw _privateConstructorUsedError;
  int get overdraftCents => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Budget to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetCopyWith<Budget> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetCopyWith<$Res> {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) then) =
      _$BudgetCopyWithImpl<$Res, Budget>;
  @useResult
  $Res call({
    String id,
    String categoryId,
    PeriodType periodType,
    DateTime periodStart,
    DateTime periodEnd,
    int limitCents,
    int consumedCents,
    bool allowOverdraft,
    int overdraftCents,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$BudgetCopyWithImpl<$Res, $Val extends Budget>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? periodType = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? limitCents = null,
    Object? consumedCents = null,
    Object? allowOverdraft = null,
    Object? overdraftCents = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            periodType: null == periodType
                ? _value.periodType
                : periodType // ignore: cast_nullable_to_non_nullable
                      as PeriodType,
            periodStart: null == periodStart
                ? _value.periodStart
                : periodStart // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            periodEnd: null == periodEnd
                ? _value.periodEnd
                : periodEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            limitCents: null == limitCents
                ? _value.limitCents
                : limitCents // ignore: cast_nullable_to_non_nullable
                      as int,
            consumedCents: null == consumedCents
                ? _value.consumedCents
                : consumedCents // ignore: cast_nullable_to_non_nullable
                      as int,
            allowOverdraft: null == allowOverdraft
                ? _value.allowOverdraft
                : allowOverdraft // ignore: cast_nullable_to_non_nullable
                      as bool,
            overdraftCents: null == overdraftCents
                ? _value.overdraftCents
                : overdraftCents // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BudgetImplCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$$BudgetImplCopyWith(
    _$BudgetImpl value,
    $Res Function(_$BudgetImpl) then,
  ) = __$$BudgetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String categoryId,
    PeriodType periodType,
    DateTime periodStart,
    DateTime periodEnd,
    int limitCents,
    int consumedCents,
    bool allowOverdraft,
    int overdraftCents,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$BudgetImplCopyWithImpl<$Res>
    extends _$BudgetCopyWithImpl<$Res, _$BudgetImpl>
    implements _$$BudgetImplCopyWith<$Res> {
  __$$BudgetImplCopyWithImpl(
    _$BudgetImpl _value,
    $Res Function(_$BudgetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? periodType = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? limitCents = null,
    Object? consumedCents = null,
    Object? allowOverdraft = null,
    Object? overdraftCents = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$BudgetImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        periodType: null == periodType
            ? _value.periodType
            : periodType // ignore: cast_nullable_to_non_nullable
                  as PeriodType,
        periodStart: null == periodStart
            ? _value.periodStart
            : periodStart // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        periodEnd: null == periodEnd
            ? _value.periodEnd
            : periodEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        limitCents: null == limitCents
            ? _value.limitCents
            : limitCents // ignore: cast_nullable_to_non_nullable
                  as int,
        consumedCents: null == consumedCents
            ? _value.consumedCents
            : consumedCents // ignore: cast_nullable_to_non_nullable
                  as int,
        allowOverdraft: null == allowOverdraft
            ? _value.allowOverdraft
            : allowOverdraft // ignore: cast_nullable_to_non_nullable
                  as bool,
        overdraftCents: null == overdraftCents
            ? _value.overdraftCents
            : overdraftCents // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BudgetImpl implements _Budget {
  const _$BudgetImpl({
    required this.id,
    required this.categoryId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.limitCents,
    required this.consumedCents,
    required this.allowOverdraft,
    required this.overdraftCents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$BudgetImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetImplFromJson(json);

  @override
  final String id;
  @override
  final String categoryId;
  @override
  final PeriodType periodType;
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;
  @override
  final int limitCents;
  @override
  final int consumedCents;
  @override
  final bool allowOverdraft;
  @override
  final int overdraftCents;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Budget(id: $id, categoryId: $categoryId, periodType: $periodType, periodStart: $periodStart, periodEnd: $periodEnd, limitCents: $limitCents, consumedCents: $consumedCents, allowOverdraft: $allowOverdraft, overdraftCents: $overdraftCents, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.periodType, periodType) ||
                other.periodType == periodType) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd) &&
            (identical(other.limitCents, limitCents) ||
                other.limitCents == limitCents) &&
            (identical(other.consumedCents, consumedCents) ||
                other.consumedCents == consumedCents) &&
            (identical(other.allowOverdraft, allowOverdraft) ||
                other.allowOverdraft == allowOverdraft) &&
            (identical(other.overdraftCents, overdraftCents) ||
                other.overdraftCents == overdraftCents) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    categoryId,
    periodType,
    periodStart,
    periodEnd,
    limitCents,
    consumedCents,
    allowOverdraft,
    overdraftCents,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      __$$BudgetImplCopyWithImpl<_$BudgetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetImplToJson(this);
  }
}

abstract class _Budget implements Budget {
  const factory _Budget({
    required final String id,
    required final String categoryId,
    required final PeriodType periodType,
    required final DateTime periodStart,
    required final DateTime periodEnd,
    required final int limitCents,
    required final int consumedCents,
    required final bool allowOverdraft,
    required final int overdraftCents,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$BudgetImpl;

  factory _Budget.fromJson(Map<String, dynamic> json) = _$BudgetImpl.fromJson;

  @override
  String get id;
  @override
  String get categoryId;
  @override
  PeriodType get periodType;
  @override
  DateTime get periodStart;
  @override
  DateTime get periodEnd;
  @override
  int get limitCents;
  @override
  int get consumedCents;
  @override
  bool get allowOverdraft;
  @override
  int get overdraftCents;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
