import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/screens/wallet_edit_screen.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';

/// Bottom sheet listing the active wallets. Returns the picked [Wallet], or
/// null when dismissed. Shared by the add and edit transaction screens.
Future<Wallet?> showWalletPicker(
  BuildContext context, {
  required String title,
  String? selectedWalletId,
  /// Hidden from the list so a transfer cannot pick the same wallet twice.
  String? excludeWalletId,
  /// Lists another workspace's wallets; defaults to the active workspace.
  String? workspaceId,
}) {
  return showModalBottomSheet<Wallet>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _WalletPickerSheet(
      title: title,
      selectedWalletId: selectedWalletId,
      excludeWalletId: excludeWalletId,
      workspaceId: workspaceId,
    ),
  );
}

class _WalletPickerSheet extends ConsumerWidget {
  const _WalletPickerSheet({
    required this.title,
    this.selectedWalletId,
    this.excludeWalletId,
    this.workspaceId,
  });

  final String title;
  final String? selectedWalletId;
  final String? excludeWalletId;
  final String? workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final walletsAsync = workspaceId == null
        ? ref.watch(walletsProvider)
        : ref.watch(walletsForWorkspaceProvider(workspaceId!));
    final balances = ref.watch(walletBalancesProvider).valueOrNull ??
        const <String, int>{};
    final canAddWallet =
        workspaceId == null && ref.watch(canManageWorkspaceContentProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: walletsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: InlineLoadErrorState(
                    onRetry: () {
                      if (workspaceId == null) {
                        ref.invalidate(walletsProvider);
                      } else {
                        ref.invalidate(
                          walletsForWorkspaceProvider(workspaceId!),
                        );
                      }
                    },
                  ),
                ),
                data: (wallets) {
                  final visible = wallets
                      .where((w) => w.id != excludeWalletId)
                      .toList();
                  if (visible.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: l10n.noWallets,
                        message: l10n.noWalletsMessage,
                        actionLabel: canAddWallet ? l10n.addWallet : null,
                        onAction: canAddWallet
                            ? () => _openWalletEditor(context, ref)
                            : null,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final wallet = visible[index];
                      final color = Color(wallet.colorValue);
                      final balance =
                          balances[wallet.id] ?? wallet.openingBalanceMinor;

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(wallet),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusCard),
                          ),
                          child: Icon(
                            CategoryIcons.getIcon(wallet.iconName),
                            size: AppSpacing.iconSizeSm,
                            color: color,
                          ),
                        ),
                        title: Text(wallet.name),
                        subtitle: Text(
                          walletTypeLabel(l10n, wallet.walletType),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyFormatter.formatVNDFromCents(
                                balance,
                                locale: l10n.localeName,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: balance < 0
                                    ? theme.colorScheme.error
                                    : null,
                              ),
                            ),
                            if (wallet.id == selectedWalletId) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Icon(Icons.check,
                                  size: 18, color: theme.colorScheme.primary),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWalletEditor(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.pushNamed(context, '/wallet-edit');
    if (result == true) {
      ref.invalidate(walletsProvider);
      ref.invalidate(walletBalancesProvider);
    }
  }
}
