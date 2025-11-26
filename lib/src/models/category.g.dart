// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      iconName: json['iconName'] as String,
      colorValue: (json['colorValue'] as num).toInt(),
      type: $enumDecodeNullable(_$CategoryTypeEnumMap, json['type']) ??
          CategoryType.expense,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconName': instance.iconName,
      'colorValue': instance.colorValue,
      'type': _$CategoryTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$CategoryTypeEnumMap = {
  CategoryType.expense: 'expense',
  CategoryType.income: 'income',
};
