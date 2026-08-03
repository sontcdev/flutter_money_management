import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';

final _now = DateTime(2026, 1, 15);

Wallet _wallet(String id, {int opening = 0}) => Wallet(
      id: id,
      workspaceId: 'ws-1',
      name: 'Wallet $id',
      iconName: 'wallet',
      colorValue: 0xFF000000,
      openingBalanceMinor: opening,
      createdAt: _now,
      updatedAt: _now,
    );

Transaction _txn({
  required String id,
  required TransactionType type,
  required int amountCents,
  String? walletId,
  String? toWalletId,
}) =>
    Transaction(
      id: id,
      amountCents: amountCents,
      currency: 'VND',
      dateTime: _now,
      type: type,
      walletId: walletId,
      toWalletId: toWalletId,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  group('computeWalletBalances', () {
    test('starts every wallet at its opening balance', () {
      final balances = computeWalletBalances(
        [_wallet('a', opening: 500), _wallet('b')],
        const [],
      );

      expect(balances, {'a': 500, 'b': 0});
    });

    test('adds income and subtracts expense on the source wallet', () {
      final balances = computeWalletBalances(
        [_wallet('a', opening: 1000)],
        [
          _txn(
              id: 't1',
              type: TransactionType.income,
              amountCents: 300,
              walletId: 'a'),
          _txn(
              id: 't2',
              type: TransactionType.expense,
              amountCents: 500,
              walletId: 'a'),
        ],
      );

      expect(balances['a'], 800);
    });

    test('moves money between wallets on a transfer without changing the sum',
        () {
      final wallets = [_wallet('a', opening: 1000), _wallet('b', opening: 200)];
      final balances = computeWalletBalances(
        wallets,
        [
          _txn(
            id: 't1',
            type: TransactionType.transfer,
            amountCents: 400,
            walletId: 'a',
            toWalletId: 'b',
          ),
        ],
      );

      expect(balances['a'], 600);
      expect(balances['b'], 600);
      expect(balances.values.fold<int>(0, (sum, v) => sum + v), 1200);
    });

    test('supports a negative opening balance such as a credit card', () {
      final balances = computeWalletBalances(
        [_wallet('card', opening: -1000)],
        [
          _txn(
              id: 't1',
              type: TransactionType.expense,
              amountCents: 500,
              walletId: 'card'),
          _txn(
              id: 't2',
              type: TransactionType.income,
              amountCents: 200,
              walletId: 'card'),
        ],
      );

      expect(balances['card'], -1300);
    });

    test('ignores transactions pointing at an unknown wallet', () {
      final balances = computeWalletBalances(
        [_wallet('a', opening: 100)],
        [
          _txn(
              id: 't1',
              type: TransactionType.expense,
              amountCents: 50,
              walletId: 'missing'),
          _txn(id: 't2', type: TransactionType.expense, amountCents: 50),
        ],
      );

      expect(balances['a'], 100);
    });
  });
}
