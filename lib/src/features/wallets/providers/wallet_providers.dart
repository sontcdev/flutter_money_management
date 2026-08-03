import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/repositories/wallet_repository.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return WalletRepository(
    supabase,
    () => ref.read(activeWorkspaceIdProvider),
    () => ref.read(currentUserProvider)?.id,
  );
});

final walletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getAllWallets();
});

final allWalletsIncludingArchivedProvider =
    FutureProvider<List<Wallet>>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getAllWallets(includeArchived: true);
});

final walletsForWorkspaceProvider =
    FutureProvider.family<List<Wallet>, String>((ref, workspaceId) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getAllWallets(workspaceIdOverride: workspaceId);
});

final walletProvider =
    FutureProvider.family<Wallet?, String>((ref, walletId) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletById(walletId);
});

/// The wallet pre-selected in the transaction form. Falls back to the first
/// wallet when no wallet is explicitly flagged as default.
final defaultWalletProvider = FutureProvider<Wallet?>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  if (wallets.isEmpty) {
    return null;
  }
  for (final wallet in wallets) {
    if (wallet.isDefault) {
      return wallet;
    }
  }
  return wallets.first;
});

/// Current balance of every wallet, keyed by wallet id.
///
/// Computed client-side to stay consistent with the rest of the app, which has
/// no SQL aggregates:
///   balance = opening balance
///           + income(wallet)   - expense(wallet)
///           + transfer in(wallet) - transfer out(wallet)
final walletBalancesProvider = FutureProvider<Map<String, int>>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  return computeWalletBalances(wallets, transactions);
});

/// Pure helper so the balance formula stays unit-testable without Riverpod.
Map<String, int> computeWalletBalances(
  List<Wallet> wallets,
  List<Transaction> transactions,
) {
  final balances = <String, int>{
    for (final wallet in wallets) wallet.id: wallet.openingBalanceMinor,
  };

  for (final transaction in transactions) {
    if (transaction.deletedAt != null) {
      continue;
    }

    final walletId = transaction.walletId;
    switch (transaction.type) {
      case TransactionType.income:
        if (walletId != null && balances.containsKey(walletId)) {
          balances[walletId] = balances[walletId]! + transaction.amountCents;
        }
        break;
      case TransactionType.expense:
        if (walletId != null && balances.containsKey(walletId)) {
          balances[walletId] = balances[walletId]! - transaction.amountCents;
        }
        break;
      case TransactionType.transfer:
        if (walletId != null && balances.containsKey(walletId)) {
          balances[walletId] = balances[walletId]! - transaction.amountCents;
        }
        final toWalletId = transaction.toWalletId;
        if (toWalletId != null && balances.containsKey(toWalletId)) {
          balances[toWalletId] =
              balances[toWalletId]! + transaction.amountCents;
        }
        break;
    }
  }

  return balances;
}

/// Sum of every wallet balance — the "total net worth" figure.
final totalWalletBalanceProvider = FutureProvider<int>((ref) async {
  final balances = await ref.watch(walletBalancesProvider.future);
  return balances.values.fold<int>(0, (sum, value) => sum + value);
});
