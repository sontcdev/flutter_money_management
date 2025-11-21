// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetImpl _$$BudgetImplFromJson(Map<String, dynamic> json) => _$BudgetImpl(
  id: json['id'] as String,
  name: json['name'] as String?,
  categoryId: json['categoryId'] as String,
  periodType: $enumDecode(_$PeriodTypeEnumMap, json['periodType']),
  periodStart: DateTime.parse(json['periodStart'] as String),
  periodEnd: DateTime.parse(json['periodEnd'] as String),
  limitCents: (json['limitCents'] as num).toInt(),
  consumedCents: (json['consumedCents'] as num).toInt(),
  allowOverdraft: json['allowOverdraft'] as bool,
  overdraftCents: (json['overdraftCents'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$BudgetImplToJson(_$BudgetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'periodType': _$PeriodTypeEnumMap[instance.periodType]!,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'limitCents': instance.limitCents,
      'consumedCents': instance.consumedCents,
      'allowOverdraft': instance.allowOverdraft,
      'overdraftCents': instance.overdraftCents,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$PeriodTypeEnumMap = {
  PeriodType.monthly: 'monthly',
  PeriodType.yearly: 'yearly',
  PeriodType.custom: 'custom',
};
