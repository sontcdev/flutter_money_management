// path: lib/src/features/wallets/models/wallet.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet.freezed.dart';
part 'wallet.g.dart';

enum WalletType { cash, bank, ewallet, creditCard, savings, other }

/// Maps the Dart enum to the `wallet_type` check constraint values in Postgres.
extension WalletTypeCodec on WalletType {
  String get dbValue {
    switch (this) {
      case WalletType.cash:
        return 'cash';
      case WalletType.bank:
        return 'bank';
      case WalletType.ewallet:
        return 'ewallet';
      case WalletType.creditCard:
        return 'credit_card';
      case WalletType.savings:
        return 'savings';
      case WalletType.other:
        return 'other';
    }
  }

  static WalletType fromDbValue(String? raw) {
    switch (raw) {
      case 'bank':
        return WalletType.bank;
      case 'ewallet':
        return WalletType.ewallet;
      case 'credit_card':
        return WalletType.creditCard;
      case 'savings':
        return WalletType.savings;
      case 'other':
        return WalletType.other;
      case 'cash':
      default:
        return WalletType.cash;
    }
  }
}

@freezed
class Wallet with _$Wallet {
  const factory Wallet({
    required String id,
    required String workspaceId,
    required String name,
    @Default(WalletType.cash) WalletType walletType,
    required String iconName,
    required int colorValue,
    // Signed: credit cards start with a negative opening balance.
    @Default(0) int openingBalanceMinor,
    @Default('VND') String currencyCode,
    @Default(false) bool isDefault,
    @Default(false) bool isArchived,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Wallet;

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
}
