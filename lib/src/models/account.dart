// path: lib/src/models/account.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String name,
    required int balanceCents,
    required String currency,
    required AccountType type,
    required DateTime createdAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

enum AccountType {
  @JsonValue('cash')
  cash,
  @JsonValue('card')
  card,
}

