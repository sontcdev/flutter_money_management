// path: lib/src/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(locale == 'en' ? 'English' : 'Tiếng Việt'),
            trailing: DropdownButton<String>(
              value: locale,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              ],
              onChanged: (value) {
                if (value != null) {
                  localeNotifier.setLocale(value);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.logout),
            leading: const Icon(Icons.logout),
            onTap: () async {
              final prefs = await ref.read(sharedPreferencesProvider.future);
              await prefs.setBool('isLoggedIn', false);
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

