// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      balanceCents: (json['balanceCents'] as num).toInt(),
      currency: json['currency'] as String,
      type: $enumDecode(_$AccountTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'balanceCents': instance.balanceCents,
      'currency': instance.currency,
      'type': _$AccountTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$AccountTypeEnumMap = {
  AccountType.cash: 'cash',
  AccountType.card: 'card',
  AccountType.bank: 'bank',
};
