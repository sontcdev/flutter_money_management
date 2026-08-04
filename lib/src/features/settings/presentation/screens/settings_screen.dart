import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;
    final warningColor = isDark ? AppColors.warningDark : AppColors.warning;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Profile summary
          if (currentUser != null) ...[
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _InitialsAvatar(
                    text: currentUser.email ?? '?',
                    size: 56,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.email ?? l10n.notAvailable,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.accountSection,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textFaint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
              _SettingsListCard(
                children: [
                  _SettingsRow(
                    icon: Icons.logout,
                    iconColor: warningColor,
                    title: l10n.leaveWorkspace,
                    titleColor: warningColor,
                    subtitle: 'Leave the current shared workspace',
                    trailing: const SizedBox.shrink(),
                    onTap: () => _handleLeaveWorkspace(
                      context,
                      ref,
                      activeWorkspace.id,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],

          // Appearance
          _SectionCaption(title: l10n.appearanceSection),
          _SettingsListCard(
            children: [
              _SettingsRow(
                icon: Icons.language,
                title: l10n.language,
                trailing: DropdownButton<String>(
                  value: locale.languageCode,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                        value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(
                        value: 'ja', child: Text(l10n.languageJapanese)),
                    DropdownMenuItem(
                        value: 'vi', child: Text(l10n.languageVietnamese)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(value));
                    }
                  },
                ),
              ),
              _SettingsRow(
                icon: Icons.brightness_6_outlined,
                title: l10n.theme,
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text(l10n.light)),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text(l10n.dark)),
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text(l10n.system)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value);
                    }
                  },
                ),
              ),
              _SettingsRow(
                icon: Icons.palette_outlined,
                title: l10n.themeColor,
                subtitle: l10n.selectThemeColor,
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                onTap: () => _showColorPicker(context, ref, themeColor, l10n),
              ),
              _SettingsRow(
                icon: Icons.text_fields_outlined,
                title: l10n.fontSize,
                subtitle: _fontScaleLabel(fontScale, l10n),
                onTap: () => _showFontScalePicker(context, ref, fontScale, l10n),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Budget
          _SectionCaption(title: l10n.budgetSettings),
          _SettingsListCard(
            children: [
              _SettingsRow(
                icon: Icons.calendar_month_outlined,
                title: l10n.monthStartDay,
                subtitle: l10n.monthStartDayDesc(monthStartDay),
                onTap: () => _showMonthStartDayPicker(
                    context, ref, monthStartDay, l10n),
              ),
              _SettingsRow(
                icon: Icons.pie_chart_outline,
                title: l10n.manageBudgets,
                subtitle: l10n.manageBudgetsDesc,
                onTap: () => Navigator.pushNamed(context, '/budgets'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data
          _SectionCaption(title: l10n.dataSection),
          _SettingsListCard(
            children: [
              _SettingsRow(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.manageWallets,
                subtitle: l10n.manageWalletsSubtitle,
                onTap: () => Navigator.pushNamed(context, '/wallets'),
              ),
              _SettingsRow(
                icon: Icons.category_outlined,
                title: l10n.manageCategories,
                subtitle: l10n.manageCategoriesDesc,
                onTap: () => Navigator.pushNamed(context, '/categories'),
              ),
              _SettingsRow(
                icon: Icons.receipt_long_outlined,
                title: l10n.manageTransactions,
                subtitle: l10n.manageTransactionsDesc,
                onTap: () =>
                    Navigator.pushNamed(context, '/transaction-management'),
              ),
              _SettingsRow(
                icon: Icons.schedule_outlined,
                title: l10n.recurringTransactions,
                subtitle: l10n.recurringTransactionsDesc,
                onTap: () =>
                    Navigator.pushNamed(context, '/recurring-transactions'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Account / About
          if (currentUser == null) ...[
            _SectionCaption(title: l10n.accountSection),
            _SettingsListCard(
              children: [
                _SettingsRow(
                  icon: Icons.login,
                  title: l10n.signIn,
                  subtitle: l10n.signInDesc,
                  onTap: () => Navigator.pushNamed(context, '/sign-in'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          if (packageInfo.data != null) ...[
            _SectionCaption(title: l10n.aboutSection),
            _SettingsListCard(
              children: [
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: packageInfo.data!.appName,
                  subtitle: l10n.versionLabel(
                    packageInfo.data!.version,
                    packageInfo.data!.buildNumber,
                  ),
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          if (currentUser != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorColor,
                  side: BorderSide(color: errorColor),
                ),
                onPressed: () => _handleLogout(context, ref),
                child: Text(l10n.logout),
              ),
            ),
        ],
      ),
    );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave workspace'),
        content: const Text('Are you sure you want to leave this workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
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
                  return GestureDetector(
                    onTap: () {
                      ref.read(monthStartDayProvider.notifier).setStartDay(day);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

                  return GestureDetector(
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
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
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

/// Small uppercase caption used above a group of settings rows,
/// matching the mockup's section labels.
class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textFaint,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

/// Card that hosts a tight vertical list of [_SettingsRow]s, separated by
/// hairline dividers, matching the mockup's grouped-row cards.
class _SettingsListCard extends StatelessWidget {
  const _SettingsListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Theme.of(context).dividerColor,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single settings row: optional leading icon/badge, title, optional
/// subtitle, and a trailing widget (defaults to a chevron when [onTap] is
/// set).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (icon != null)
            Icon(icon, size: 20, color: iconColor),
          if (leading != null || icon != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textFaint,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              (onTap != null
                  ? const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textFaint,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: row,
    );
  }
}

/// Circular avatar showing the first letter of [text].
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.text, this.size = 44});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = text.trim().isNotEmpty ? text.trim()[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppColors.primaryStrongDark
                  : AppColors.primaryStrong,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

/// Rounded-square badge with the first 1-2 letters of a workspace name,
/// used to represent a workspace in list rows.
class _SquareBadge extends StatelessWidget {
  const _SquareBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final label = text.trim().isNotEmpty ? text.trim()[0].toUpperCase() : '?';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
