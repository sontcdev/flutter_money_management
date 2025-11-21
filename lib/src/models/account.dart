// path: lib/src/models/account.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

enum AccountType {
  cash,
  card,
  bank,
}

@freezed
class Account with _$Account {
  const factory Account({
    required int id,
    required String name,
    required int balanceCents,
    required String currency,
    required AccountType type,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

