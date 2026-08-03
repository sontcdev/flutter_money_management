// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      amountCents: (json['amountCents'] as num).toInt(),
      currency: json['currency'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      categoryId: json['categoryId'] as String?,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      walletId: json['walletId'] as String?,
      toWalletId: json['toWalletId'] as String?,
      note: json['note'] as String?,
      receiptPath: json['receiptPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
              SyncStatus.pending,
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
      lastSyncError: json['lastSyncError'] as String?,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amountCents': instance.amountCents,
      'currency': instance.currency,
      'dateTime': instance.dateTime.toIso8601String(),
      'categoryId': instance.categoryId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'walletId': instance.walletId,
      'toWalletId': instance.toWalletId,
      'note': instance.note,
      'receiptPath': instance.receiptPath,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'syncedAt': instance.syncedAt?.toIso8601String(),
      'lastSyncError': instance.lastSyncError,
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.income: 'income',
  TransactionType.transfer: 'transfer',
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.error: 'error',
};
