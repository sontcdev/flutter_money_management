// path: lib/src/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/app_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              items: [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(value));
                }
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.category),
            title: Text(l10n.categories),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.categories);
            },
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet),
            title: Text(l10n.accounts),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to accounts screen
            },
          ),
          Divider(),
          if (isLoggedIn)
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(l10n.logout, style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(isLoggedInProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppRouter.login);
                }
              },
            ),
        ],
      ),
    );
  }
}

