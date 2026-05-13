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
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final packageInfo =
        useFuture(useMemoized(() => PackageInfo.fromPlatform()));
    final currentUser = ref.watch(currentUserProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final canLeaveWorkspace = ref.watch(canLeaveWorkspaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader(context, l10n.appearanceSection),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
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
                  ref.read(localeProvider.notifier).setLocale(Locale(value));
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: [
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
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
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(l10n.themeColor),
            subtitle: Text(l10n.selectThemeColor),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
            onTap: () => _showColorPicker(context, ref, themeColor, l10n),
          ),

          const Divider(height: 32),

          // Budget Section
          _buildSectionHeader(context, l10n.budgetSettings),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(l10n.monthStartDay),
            subtitle: Text(l10n.monthStartDayDesc(monthStartDay)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showMonthStartDayPicker(context, ref, monthStartDay, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart),
            title: Text(l10n.manageBudgets),
            subtitle: Text(l10n.manageBudgetsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/budgets'),
          ),

          const Divider(height: 32),

          // Data Section
          _buildSectionHeader(context, l10n.dataSection),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(l10n.manageCategories),
            subtitle: Text(l10n.manageCategoriesDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(l10n.manageTransactions),
            subtitle: Text(l10n.manageTransactionsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, '/transaction-management'),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.recurringTransactions),
            subtitle: Text(l10n.recurringTransactionsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, '/recurring-transactions'),
          ),
          const Divider(height: 32),

          // Account Section
          _buildSectionHeader(context, l10n.accountSection),
          if (currentUser != null) ...[
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(l10n.email),
              subtitle: Text(currentUser.email ?? l10n.notAvailable),
            ),
            if (activeWorkspace != null)
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.activeWorkspace),
                subtitle: Text(activeWorkspace.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/workspace-detail'),
              ),
            if (canLeaveWorkspace)
              ListTile(
                leading: Icon(Icons.logout, color: Colors.orange[700]),
                title: Text(
                  'Leave workspace',
                  style: TextStyle(color: Colors.orange[700]),
                ),
                subtitle: const Text('Leave the current shared workspace'),
                onTap: () => _handleLeaveWorkspace(
                  context,
                  ref,
                  activeWorkspace!.id,
                ),
              ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]),
              title: Text(
                l10n.logout,
                style: TextStyle(color: Colors.red[700]),
              ),
              subtitle: Text(l10n.logoutDesc),
              onTap: () => _handleLogout(context, ref),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: Text(l10n.signIn),
              subtitle: Text(l10n.signInDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/sign-in'),
            ),
          ],

          const Divider(height: 32),

          // About Section
          _buildSectionHeader(context, l10n.aboutSection),
          if (packageInfo.data != null)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(packageInfo.data!.appName),
              subtitle: Text(
                l10n.versionLabel(
                  packageInfo.data!.version,
                  packageInfo.data!.buildNumber,
                ),
              ),
            ),

          const SizedBox(height: 24),
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
              backgroundColor: Colors.red[700],
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                                ? Border.all(color: Colors.black, width: 3)
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
