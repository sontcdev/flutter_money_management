// path: lib/src/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import '../../../l10n/app_localizations.dart';

// Budget period provider
final budgetPeriodProvider = StateNotifierProvider<BudgetPeriodNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BudgetPeriodNotifier(prefs);
});

class BudgetPeriodNotifier extends StateNotifier<String> {
  static const String _periodKey = 'budget_period';
  final SharedPreferences _prefs;

  BudgetPeriodNotifier(this._prefs) : super('monthly') {
    _loadPeriod();
  }

  void _loadPeriod() {
    final period = _prefs.getString(_periodKey);
    if (period != null) {
      state = period;
    }
  }

  Future<void> setPeriod(String period) async {
    await _prefs.setString(_periodKey, period);
    state = period;
  }
}

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final budgetPeriod = ref.watch(budgetPeriodProvider);
    final themeColor = ref.watch(themeColorProvider);
    final packageInfo = useFuture(useMemoized(() => PackageInfo.fromPlatform()));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // Language Section
          _buildSectionHeader(context, l10n.languageDisplay),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              items: const [
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
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          
          // Theme Color Section
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

          const Divider(),
          
          // Budget Period Section
          _buildSectionHeader(context, l10n.budgetSettings),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(l10n.defaultBudgetPeriod),
            subtitle: Text(_getPeriodLabel(budgetPeriod, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPeriodPicker(context, ref, budgetPeriod, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart),
            title: Text(l10n.manageBudgets),
            subtitle: Text(l10n.manageBudgetsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/budgets'),
          ),

          const Divider(),
          
          // Data Section
          _buildSectionHeader(context, l10n.dataSection),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: Text(l10n.importExport),
            subtitle: Text(l10n.importExportDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/import-export');
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(l10n.manageCategories),
            subtitle: Text(l10n.manageCategoriesDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          
          const Divider(),

          // About Section
          _buildSectionHeader(context, l10n.aboutSection),
          if (packageInfo.data != null)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(packageInfo.data!.appName),
              subtitle: Text(
                'Version ${packageInfo.data!.version} (${packageInfo.data!.buildNumber})',
              ),
            ),
        ],
      ),
    );
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

  String _getPeriodLabel(String period, AppLocalizations l10n) {
    switch (period) {
      case 'weekly':
        return l10n.weekly;
      case 'monthly':
        return l10n.monthly;
      case 'quarterly':
        return l10n.quarterly;
      case 'yearly':
        return l10n.yearly;
      default:
        return l10n.monthly;
    }
  }

  void _showPeriodPicker(BuildContext context, WidgetRef ref, String currentPeriod, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.selectBudgetPeriod,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildPeriodOption(context, ref, 'weekly', l10n.weekly, currentPeriod),
            _buildPeriodOption(context, ref, 'monthly', l10n.monthly, currentPeriod),
            _buildPeriodOption(context, ref, 'quarterly', l10n.quarterly, currentPeriod),
            _buildPeriodOption(context, ref, 'yearly', l10n.yearly, currentPeriod),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(BuildContext context, WidgetRef ref, String value, String label, String current) {
    return ListTile(
      leading: Icon(
        value == current ? Icons.radio_button_checked : Icons.radio_button_off,
        color: value == current ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      onTap: () {
        ref.read(budgetPeriodProvider.notifier).setPeriod(value);
        Navigator.pop(context);
      },
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, Color currentColor, AppLocalizations l10n) {
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
                children: ThemeColorNotifier.availableColors.entries.map((entry) {
                  final color = entry.value;
                  final name = _getColorName(entry.key, l10n);
                  final isSelected = color.value == currentColor.value;
                  
                  return GestureDetector(
                    onTap: () {
                      ref.read(themeColorProvider.notifier).setThemeColor(color);
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
                                color: color.withOpacity(0.4),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
