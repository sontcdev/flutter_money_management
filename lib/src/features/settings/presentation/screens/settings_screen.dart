import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_money_management/src/features/auth/models/account_deletion_blocker.dart';
import 'package:flutter_money_management/src/features/auth/models/account_deletion_exception.dart';
import 'package:flutter_money_management/src/features/auth/presentation/widgets/account_deletion_dialog.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/confirm_delete_dialog.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

part 'settings_screen_sections.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final packageInfo =
        useFuture(useMemoized(() => PackageInfo.fromPlatform()));
    final currentUser = ref.watch(currentUserProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final canLeaveWorkspace = ref.watch(canLeaveWorkspaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Profile summary
          if (currentUser != null) ...[
            _ProfileSummaryCard(email: currentUser.email),
            const SizedBox(height: 20),
          ],

          // Workspace section
          if (activeWorkspace != null) ...[
            _SectionCaption(title: l10n.activeWorkspace),
            _SettingsListCard(
              children: [
                _SettingsRow(
                  leading: _SquareBadge(text: activeWorkspace.name),
                  title: activeWorkspace.name,
                  subtitle: l10n.roleValue(activeWorkspace.role),
                  onTap: () =>
                      Navigator.pushNamed(context, '/workspace-detail'),
                ),
              ],
            ),
            if (canLeaveWorkspace) ...[
              const SizedBox(height: 12),
              _LeaveWorkspaceCard(
                onTap: () => _handleLeaveWorkspace(
                  context,
                  ref,
                  activeWorkspace.id,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],

          // Appearance
          _SectionCaption(title: l10n.appearanceSection),
          _AppearanceSettingsCard(
            locale: locale,
            themeMode: themeMode,
            themeColor: themeColor,
            fontScaleLabel: _fontScaleLabel(fontScale, l10n),
            onThemeColorTap: () =>
                _showColorPicker(context, ref, themeColor, l10n),
            onFontScaleTap: () =>
                _showFontScalePicker(context, ref, fontScale, l10n),
          ),
          const SizedBox(height: 20),

          // Budget
          _SectionCaption(title: l10n.budgetSettings),
          _BudgetSettingsCard(
            monthStartDay: monthStartDay,
            onMonthStartDayTap: () => _showMonthStartDayPicker(
                context, ref, monthStartDay, l10n),
          ),
          const SizedBox(height: 20),

          // Data
          _SectionCaption(title: l10n.dataSection),
          const _DataSettingsCard(),
          const SizedBox(height: 20),

          // Account / About
          if (currentUser == null) ...[
            _SectionCaption(title: l10n.accountSection),
            _SettingsListCard(
              children: [
                _SettingsRow(
                  icon: Icons.login,
                  tint: AppColors.primary,
                  title: l10n.signIn,
                  subtitle: l10n.signInDesc,
                  onTap: () => Navigator.pushNamed(context, '/sign-in'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          _SettingsListCard(
            children: [
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                tint: AppColors.primary,
                title: l10n.privacyPolicy,
                subtitle: l10n.privacyPolicySubtitle,
                onTap: () => _handlePrivacyPolicy(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (packageInfo.data != null) ...[
            _SectionCaption(title: l10n.aboutSection),
            _AboutSettingsCard(packageInfo: packageInfo.data!),
            const SizedBox(height: 24),
          ],

          if (currentUser != null) ...[
            _DeleteAccountCard(
              onTap: () => _handleDeleteAccount(context, ref),
            ),
            const SizedBox(height: 24),
          ],

          if (currentUser != null)
            _LogoutButton(onPressed: () => _handleLogout(context, ref)),
        ],
      ),
    );
  }

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://sontcdev.github.io/flutter_money_management/',
  );

  Future<void> _handlePrivacyPolicy(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        _privacyPolicyUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.privacyPolicyOpenFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  static final Uri _deleteAccountUrl = Uri.parse(
    'https://sontcdev.github.io/flutter_money_management/delete-account.html',
  );

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(supabaseAuthServiceProvider);
    try {
      final blockers = await authService.getAccountDeletionBlockers();
      if (!context.mounted) return;
      if (blockers.isNotEmpty) {
        await _showAccountDeletionBlockers(context, blockers);
        return;
      }
      final result = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AccountDeletionDialog(
          onDelete: authService.deleteAccount,
          onWebRequest: () => _openDeletionWebRequest(context),
        ),
      );
      if (!context.mounted) return;
      if (result is SharedWorkspaceMembershipException) {
        await _showAccountDeletionBlockers(context, result.workspaces);
        return;
      }
      if (result != true) return;
      await authService.clearDeletedAccountSession();
      clearActiveWorkspace(ref);
      ref.invalidate(authStateProvider);
      ref.invalidate(workspaceListProvider);
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/sign-in',
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'settings',
          action: 'delete_account',
          screen: 'settings_screen',
        );
      }
    }
  }

  Future<void> _showAccountDeletionBlockers(
    BuildContext context,
    List<AccountDeletionBlocker> blockers,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final workspaceId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountSharedWorkspaces),
            const SizedBox(height: AppSpacing.lg),
            for (final workspace in blockers)
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(workspace.workspaceId),
                child: Text(workspace.workspaceName),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (workspaceId != null && context.mounted) {
      await Navigator.of(context).pushNamed(
        '/workspace-detail',
        arguments: workspaceId,
      );
    }
  }

  Future<void> _openDeletionWebRequest(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final opened = await launchUrl(
      _deleteAccountUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showAppSnackBar(
        context,
        l10n.deleteAccountOpenFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.signOutTitle),
        content: Text(AppLocalizations.of(context)!.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(AppLocalizations.of(context)!.signOutTitle),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Sign out from Supabase
        final authService = ref.read(supabaseAuthServiceProvider);
        await authService.signOut();

        // Clear active workspace
        clearActiveWorkspace(ref);

        // Invalidate auth-related providers
        ref.invalidate(authStateProvider);
        ref.invalidate(workspaceListProvider);

        if (context.mounted) {
          // Navigate to sign in
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/sign-in',
            (route) => false,
          );
        }
      } catch (e, stackTrace) {
        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'settings',
            action: 'sign_out',
            screen: 'settings_screen',
          );
        }
      }
    }
  }

  Future<void> _handleLeaveWorkspace(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: l10n.leaveWorkspace,
      message: l10n.leaveWorkspaceConfirm,
      consequence: l10n.leaveWorkspaceDesc,
      confirmLabel: l10n.leave,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(workspaceManagementServiceProvider)
          .leaveWorkspace(workspaceId);
      clearActiveWorkspace(ref);
      ref.invalidate(workspaceListProvider);
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/workspace-selection',
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'workspace',
          action: 'leave_workspace_settings',
          screen: 'settings_screen',
        );
      }
    }
  }

  void _showMonthStartDayPicker(BuildContext context, WidgetRef ref,
      int currentDay, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.selectMonthStartDay,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 200,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 31,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isSelected = day == currentDay;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    inMutuallyExclusiveGroup: true,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(monthStartDayProvider.notifier).setStartDay(day);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFontScalePicker(BuildContext context, WidgetRef ref,
      FontScale currentScale, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.selectFontSize,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...FontScale.values.map((scale) {
              final isSelected = scale == currentScale;
              return ListTile(
                title: Text(
                  _fontScaleLabel(scale, l10n),
                  style: TextStyle(fontSize: 16 * scale.multiplier),
                ),
                trailing: isSelected
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(fontScaleProvider.notifier).setFontScale(scale);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fontScaleLabel(FontScale scale, AppLocalizations l10n) {
    switch (scale) {
      case FontScale.small:
        return l10n.fontSizeSmall;
      case FontScale.medium:
        return l10n.fontSizeMedium;
      case FontScale.large:
        return l10n.fontSizeLarge;
      case FontScale.extraLarge:
        return l10n.fontSizeExtraLarge;
    }
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, Color currentColor,
      AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.selectThemeColor,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    ThemeColorNotifier.availableColors.entries.map((entry) {
                  final color = entry.value;
                  final name = _getColorName(entry.key, l10n);
                  final isSelected =
                      color.toARGB32() == currentColor.toARGB32();

                  return Semantics(
                    button: true,
                    selected: isSelected,
                    inMutuallyExclusiveGroup: true,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(themeColorProvider.notifier)
                            .setThemeColor(color);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: _onColor(color),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _onColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? AppColors.textLight
        : AppColors.textDark;
  }

  String _getColorName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'blue':
        return l10n.colorBlue;
      case 'green':
        return l10n.colorGreen;
      case 'purple':
        return l10n.colorPurple;
      case 'orange':
        return l10n.colorOrange;
      case 'teal':
        return l10n.colorTeal;
      case 'pink':
        return l10n.colorPink;
      case 'indigo':
        return l10n.colorIndigo;
      case 'red':
        return l10n.colorRed;
      default:
        return key;
    }
  }
}
