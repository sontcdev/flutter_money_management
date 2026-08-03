// path: lib/src/features/wallets/repositories/wallet_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart'
    as model;
import 'package:flutter_money_management/src/utils/category_color_codec.dart';

/// Thrown when a wallet still holds transactions and therefore can only be
/// archived, never deleted.
class WalletInUseException implements Exception {
  const WalletInUseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WalletRepository {
  final SupabaseClient _supabase;
  final String? Function() _getActiveWorkspaceId;
  final String? Function() _getCurrentUserId;
  final _uuid = const Uuid();

  WalletRepository(
    this._supabase,
    this._getActiveWorkspaceId,
    this._getCurrentUserId,
  );

  Future<List<model.Wallet>> getAllWallets({
    String? workspaceIdOverride,
    bool includeArchived = false,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    var query = _supabase
        .from('wallets')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final response = await query.order('sort_order').order('name');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(_mapWallet)
        .toList();
  }

  Future<model.Wallet?> getWalletById(
    String id, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    final response = await _supabase
        .from('wallets')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _mapWallet(response);
  }

  Future<model.Wallet> createWallet(
    model.Wallet wallet, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();
    final id = wallet.id.isEmpty ? _uuid.v4() : wallet.id;

    try {
      final response = await _supabase.rpc('create_wallet_rpc', params: {
        'p_workspace_id': workspaceId,
        'p_name': wallet.name.trim(),
        'p_wallet_type': wallet.walletType.dbValue,
        'p_icon_name': wallet.iconName,
        'p_color_value': encodeCategoryColor(wallet.colorValue),
        'p_opening_balance_minor': wallet.openingBalanceMinor,
        'p_currency_code': wallet.currencyCode,
        'p_is_default': wallet.isDefault,
        'p_sort_order': wallet.sortOrder,
        'p_id': id,
      });
      return _mapWallet(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> updateWallet(
    model.Wallet wallet, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();

    try {
      await _supabase.rpc('update_wallet_rpc', params: {
        'p_wallet_id': wallet.id,
        'p_workspace_id': workspaceId,
        'p_name': wallet.name.trim(),
        'p_wallet_type': wallet.walletType.dbValue,
        'p_icon_name': wallet.iconName,
        'p_color_value': encodeCategoryColor(wallet.colorValue),
        'p_opening_balance_minor': wallet.openingBalanceMinor,
        'p_currency_code': wallet.currencyCode,
        'p_is_default': wallet.isDefault,
        'p_is_archived': wallet.isArchived,
        'p_sort_order': wallet.sortOrder,
      });
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> setDefaultWallet(
    String id, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();

    try {
      await _supabase.rpc('set_default_wallet_rpc', params: {
        'p_wallet_id': id,
        'p_workspace_id': workspaceId,
      });
    } on PostgrestException catch (e) {
      throw mapSupabaseException(e);
    }
  }

  Future<void> archiveWallet(
    model.Wallet wallet, {
    bool archived = true,
    String? workspaceIdOverride,
  }) async {
    return updateWallet(
      wallet.copyWith(
        isArchived: archived,
        // An archived wallet must not stay the default one.
        isDefault: archived ? false : wallet.isDefault,
      ),
      workspaceIdOverride: workspaceIdOverride,
    );
  }

  Future<void> deleteWallet(
    String id, {
    String? workspaceIdOverride,
  }) async {
    final workspaceId = _requireWorkspaceId(workspaceIdOverride);
    _requireUserId();

    try {
      await _supabase.rpc('soft_delete_wallet_rpc', params: {
        'p_wallet_id': id,
        'p_workspace_id': workspaceId,
      });
    } on PostgrestException catch (e) {
      if (e.message.contains('WALLET_IN_USE')) {
        throw const WalletInUseException(
          'Wallet is in use and cannot be deleted',
        );
      }
      throw mapSupabaseException(e);
    }
  }

  model.Wallet _mapWallet(Map<String, dynamic> item) {
    return model.Wallet(
      id: item['id'] as String,
      workspaceId: item['workspace_id'] as String,
      name: item['name'] as String,
      walletType:
          model.WalletTypeCodec.fromDbValue(item['wallet_type'] as String?),
      iconName: item['icon_name'] as String,
      colorValue: decodeCategoryColor(item['color_value']),
      openingBalanceMinor: (item['opening_balance_minor'] as num?)?.toInt() ?? 0,
      currencyCode: item['currency_code'] as String? ?? 'VND',
      isDefault: item['is_default'] as bool? ?? false,
      isArchived: item['is_archived'] as bool? ?? false,
      sortOrder: (item['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(item['created_at'] as String),
      updatedAt: DateTime.parse(item['updated_at'] as String),
      deletedAt: item['deleted_at'] != null
          ? DateTime.parse(item['deleted_at'] as String)
          : null,
    );
  }

  String _requireWorkspaceId([String? workspaceIdOverride]) {
    final workspaceId = workspaceIdOverride ?? _getActiveWorkspaceId();
    if (workspaceId == null || workspaceId.isEmpty) {
      throw Exception('No active workspace selected');
    }
    return workspaceId;
  }

  String _requireUserId() {
    final userId = _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user');
    }
    return userId;
  }
}
