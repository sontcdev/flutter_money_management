// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletImpl _$$WalletImplFromJson(Map<String, dynamic> json) => _$WalletImpl(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      name: json['name'] as String,
      walletType:
          $enumDecodeNullable(_$WalletTypeEnumMap, json['walletType']) ??
              WalletType.cash,
      iconName: json['iconName'] as String,
      colorValue: (json['colorValue'] as num).toInt(),
      openingBalanceMinor: (json['openingBalanceMinor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currencyCode'] as String? ?? 'VND',
      isDefault: json['isDefault'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$$WalletImplToJson(_$WalletImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workspaceId': instance.workspaceId,
      'name': instance.name,
      'walletType': _$WalletTypeEnumMap[instance.walletType]!,
      'iconName': instance.iconName,
      'colorValue': instance.colorValue,
      'openingBalanceMinor': instance.openingBalanceMinor,
      'currencyCode': instance.currencyCode,
      'isDefault': instance.isDefault,
      'isArchived': instance.isArchived,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

const _$WalletTypeEnumMap = {
  WalletType.cash: 'cash',
  WalletType.bank: 'bank',
  WalletType.ewallet: 'ewallet',
  WalletType.creditCard: 'creditCard',
  WalletType.savings: 'savings',
  WalletType.other: 'other',
};
