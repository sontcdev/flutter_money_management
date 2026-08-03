import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/screens/wallet_edit_screen.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/wallets/repositories/wallet_repository.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_metric_card.dart';
import 'package:flutter_money_management/src/ui/widgets/confirm_delete_dialog.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final walletsAsync = ref.watch(walletsProvider);
    final balancesAsync = ref.watch(walletBalancesProvider);
    final canManageContent = ref.watch(canManageWorkspaceContentProvider);

    Future<void> openEditor([Wallet? wallet]) async {
      final result = await Navigator.pushNamed(
        context,
        '/wallet-edit',
        arguments: wallet,
      );
      if (result == true) {
        ref.invalidate(walletsProvider);
        ref.invalidate(walletBalancesProvider);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wallets),
        actions: [
          if (canManageContent)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: openEditor,
            ),
        ],
      ),
      body: walletsAsync.when(
        loading: () => ListView.builder(
          itemCount: 4,
          itemBuilder: (context, index) => const ShimmerListItem(),
        ),
        error: (error, stack) =>
            Center(child: Text(l10n.errorWithMessage('$error'))),
        data: (wallets) {
          if (wallets.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => syncCurrentWorkspaceData(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.noWallets,
                      message: l10n.noWalletsMessage,
                      actionLabel: canManageContent ? l10n.addWallet : null,
                      onAction: canManageContent ? openEditor : null,
                    ),
                  ),
                ],
              ),
            );
          }

          final balances = balancesAsync.valueOrNull ?? const <String, int>{};
          final total = wallets.fold<int>(
            0,
            (sum, wallet) =>
                sum + (balances[wallet.id] ?? wallet.openingBalanceMinor),
          );

          return RefreshIndicator(
            onRefresh: () => syncCurrentWorkspaceData(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                AppMetricCard.hero(
                  label: l10n.totalBalance,
                  value: CurrencyFormatter.formatVNDFromCents(total),
                  tone: total < 0
                      ? MetricCardTone.danger
                      : MetricCardTone.neutral,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < wallets.length; i++) ...[
                        _WalletRow(
                          wallet: wallets[i],
                          balance: balances[wallets[i].id] ??
                              wallets[i].openingBalanceMinor,
                          onTap: canManageContent
                              ? () => openEditor(wallets[i])
                              : null,
                          onDelete: canManageContent
                              ? () => _deleteWallet(
                                    context: context,
                                    ref: ref,
                                    l10n: l10n,
                                    wallet: wallets[i],
                                  )
                              : null,
                        ),
                        if (i != wallets.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.6),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteWallet({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required Wallet wallet,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        title: l10n.deleteWallet,
        message: l10n.deleteWalletConfirm,
      ),
    );
    if (confirm != true) {
      return;
    }

    try {
      await ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
      ref.invalidate(walletsProvider);
      ref.invalidate(walletBalancesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.success)),
        );
      }
    } on WalletInUseException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.walletInUse)),
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'wallet',
          action: 'delete_wallet',
          screen: 'wallets_screen',
          extraContext: {'wallet_id': wallet.id},
        );
      }
    }
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.wallet,
    required this.balance,
    this.onTap,
    this.onDelete,
  });

  final Wallet wallet;
  final int balance;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = Color(wallet.colorValue);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(CategoryIcons.getIcon(wallet.iconName),
            size: 20, color: color),
      ),
      title: Row(
        children: [
          Flexible(child: Text(wallet.name, overflow: TextOverflow.ellipsis)),
          if (wallet.isDefault) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.star, size: 14, color: theme.colorScheme.primary),
          ],
        ],
      ),
      subtitle: Text(walletTypeLabel(l10n, wallet.walletType)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.formatVNDFromCents(balance),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: balance < 0 ? theme.colorScheme.error : null,
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
