// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: (json['id'] as num).toInt(),
      amountCents: (json['amountCents'] as num).toInt(),
      currency: json['currency'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      categoryId: (json['categoryId'] as num).toInt(),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      note: json['note'] as String?,
      receiptPath: json['receiptPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amountCents': instance.amountCents,
      'currency': instance.currency,
      'dateTime': instance.dateTime.toIso8601String(),
      'categoryId': instance.categoryId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'note': instance.note,
      'receiptPath': instance.receiptPath,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.income: 'income',
};
