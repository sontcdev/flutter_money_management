import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/vnd_input_formatter.dart';

/// Localized label for a wallet type.
String walletTypeLabel(AppLocalizations l10n, WalletType type) {
  switch (type) {
    case WalletType.cash:
      return l10n.walletTypeCash;
    case WalletType.bank:
      return l10n.walletTypeBank;
    case WalletType.ewallet:
      return l10n.walletTypeEwallet;
    case WalletType.creditCard:
      return l10n.walletTypeCreditCard;
    case WalletType.savings:
      return l10n.walletTypeSavings;
    case WalletType.other:
      return l10n.walletTypeOther;
  }
}

/// Icon suggested for a wallet type, used as the default when creating one.
String defaultIconForWalletType(WalletType type) {
  switch (type) {
    case WalletType.cash:
      return 'wallet';
    case WalletType.bank:
      return 'account_balance';
    case WalletType.ewallet:
      return 'account_balance_wallet';
    case WalletType.creditCard:
      return 'credit_card';
    case WalletType.savings:
      return 'savings';
    case WalletType.other:
      return 'wallet';
  }
}

class WalletEditScreen extends HookConsumerWidget {
  final Wallet? wallet;
  final String? workspaceId;

  const WalletEditScreen({
    super.key,
    this.wallet,
    this.workspaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController(text: wallet?.name ?? '');
    final balanceController = useTextEditingController(
      text: wallet == null
          ? ''
          : CurrencyFormatter.formatInputVND(
              wallet!.openingBalanceMinor.abs().toString(),
            ),
    );
    final selectedType = useState(wallet?.walletType ?? WalletType.cash);
    final selectedIcon = useState(wallet?.iconName ?? 'wallet');
    final selectedColor = useState(wallet?.colorValue ?? 0xFF00A86B);
    final isDefault = useState(wallet?.isDefault ?? false);
    // Credit cards typically start owing money, so the opening balance can be
    // negative.
    final isNegativeBalance = useState((wallet?.openingBalanceMinor ?? 0) < 0);
    final isLoading = useState(false);

    final iconKeys = [
      'wallet',
      'account_balance',
      'account_balance_wallet',
      'credit_card',
      'savings',
      'payments',
      'money',
      'attach_money',
      'card_giftcard',
      'phone_android',
    ].where(CategoryIcons.isValidIconName).toList();

    final colors = [
      0xFF00A86B,
      0xFF0077FF,
      0xFF7F3DFF,
      0xFFFD3C4A,
      0xFFFCAC12,
      0xFFFF7EB3,
      0xFF009688,
      0xFF607D8B,
      0xFF795548,
      0xFF9E9E9E,
    ];

    Future<void> save() async {
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.categoryNameRequiredError)),
        );
        return;
      }

      isLoading.value = true;

      try {
        final parsedBalance =
            CurrencyFormatter.parseVND(balanceController.text) ?? 0;
        final balanceMinor = CurrencyFormatter.toCents(parsedBalance);

        final repository = ref.read(walletRepositoryProvider);
        final edited = Wallet(
          id: wallet?.id ?? '',
          workspaceId: wallet?.workspaceId ?? workspaceId ?? '',
          name: nameController.text.trim(),
          walletType: selectedType.value,
          iconName: selectedIcon.value,
          colorValue: selectedColor.value,
          openingBalanceMinor:
              isNegativeBalance.value ? -balanceMinor : balanceMinor,
          currencyCode: wallet?.currencyCode ?? 'VND',
          isDefault: isDefault.value,
          isArchived: wallet?.isArchived ?? false,
          sortOrder: wallet?.sortOrder ?? 0,
          createdAt: wallet?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (wallet == null) {
          await repository.createWallet(
            edited,
            workspaceIdOverride: workspaceId,
          );
        } else {
          await repository.updateWallet(
            edited,
            workspaceIdOverride: workspaceId,
          );
        }

        ref.invalidate(walletsProvider);
        ref.invalidate(allWalletsIncludingArchivedProvider);
        if (workspaceId != null && workspaceId!.isNotEmpty) {
          ref.invalidate(walletsForWorkspaceProvider(workspaceId!));
        }

        if (context.mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.success)),
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
            action: wallet == null ? 'create_wallet' : 'update_wallet',
            screen: 'wallet_edit_screen',
            extraContext: {
              if (wallet != null) 'wallet_id': wallet!.id,
              'wallet_type': selectedType.value.name,
            },
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    final theme = Theme.of(context);
    final sectionLabelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final previewColor = Color(selectedColor.value);

    return Scaffold(
      appBar: AppBar(
        title: Text(wallet == null ? l10n.addWallet : l10n.editWallet),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: previewColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                CategoryIcons.getIcon(selectedIcon.value),
                size: 32,
                color: previewColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppInput(
              label: l10n.walletName,
              controller: nameController,
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.walletType, style: sectionLabelStyle),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: WalletType.values.map((type) {
                return ChoiceChip(
                  label: Text(walletTypeLabel(l10n, type)),
                  selected: selectedType.value == type,
                  onSelected: (_) {
                    selectedType.value = type;
                    // Only steer the icon while creating, so an explicit pick
                    // on an existing wallet is never overwritten.
                    if (wallet == null) {
                      selectedIcon.value = defaultIconForWalletType(type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppInput(
              label: l10n.openingBalance,
              controller: balanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                VNDInputFormatter(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.negativeOpeningBalance),
                    value: isNegativeBalance.value,
                    onChanged: (value) => isNegativeBalance.value = value,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.setAsDefaultWallet),
                    value: isDefault.value,
                    onChanged: (value) => isDefault.value = value,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.walletIcon, style: sectionLabelStyle),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: iconKeys.map((iconKey) {
                final isSelected = selectedIcon.value == iconKey;
                return GestureDetector(
                  onTap: () => selectedIcon.value = iconKey,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? previewColor.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? previewColor
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      CategoryIcons.getIcon(iconKey),
                      size: 24,
                      color: isSelected
                          ? previewColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.walletColor, style: sectionLabelStyle),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: colors.map((color) {
                final isSelected = selectedColor.value == color;
                return GestureDetector(
                  onTap: () => selectedColor.value = color,
                  child: Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Color(color), width: 2)
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: l10n.save,
              onPressed: save,
              isLoading: isLoading.value,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
