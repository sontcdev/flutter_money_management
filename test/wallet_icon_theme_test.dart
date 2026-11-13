import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/screens/wallet_edit_screen.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/screens/wallets_screen.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_picker.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_money_management/src/utils/category_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _icon = 'account_balance';
const _colors = <String, int>{
  'amber': 0xFFFFC107,
  'paleYellow': 0xFFFFF59D,
  'lightCyan': 0xFFB2EBF2,
  'dark': 0xFF0D1B4F,
};

Wallet _wallet(int color) => Wallet(
      id: 'wl1',
      workspaceId: 'w1',
      name: 'Main',
      walletType: WalletType.bank,
      iconName: _icon,
      colorValue: color,
      openingBalanceMinor: 150000,
      currencyCode: 'VND',
      isDefault: false,
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

ThemeData _theme(Brightness b) => b == Brightness.light
    ? AppTheme.lightTheme(primaryColor: const Color(0xFF00884B))
    : AppTheme.darkTheme(primaryColor: const Color(0xFF00884B));

Widget _app(Brightness b, Widget home, List<Override> overrides) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: _theme(b),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

List<Override> _overrides(Wallet w) => [
      walletsProvider.overrideWith((ref) async => [w]),
      walletsForWorkspaceProvider.overrideWith((ref, id) async => [w]),
      walletBalancesProvider
          .overrideWith((ref) async => {w.id: w.openingBalanceMinor}),
      canManageWorkspaceContentProvider.overrideWithValue(false),
    ];

/// Worst contrast of [fg] against the tint composite on surface and scaffold.
double _worst(WidgetTester tester, Color fg, Color tint, ThemeData theme,
    {bool includeHighest = false}) {
  var worst = 100.0;
  for (final bg in {
    theme.colorScheme.surface,
    theme.scaffoldBackgroundColor,
    if (includeHighest) theme.colorScheme.surfaceContainerHighest,
  }) {
    final composite = Color.alphaBlend(tint.withValues(alpha: 0.15), bg);
    final r = AppSurfaceTokens.contrast(fg, composite);
    if (r < worst) worst = r;
  }
  return worst;
}

void _checkIcons(
  WidgetTester tester,
  Color tint,
  ThemeData theme,
  String label,
) {
  final icons = tester
      .widgetList<Icon>(find.byIcon(CategoryIcons.getIcon(_icon)))
      .toList();
  expect(icons, isNotEmpty);
  for (final icon in icons) {
    final raw = _worst(tester, tint, tint, theme);
    final ratio = _worst(tester, icon.color!, tint, theme);
    // ignore: avoid_print
    print('RATIO $label before=${raw.toStringAsFixed(2)} '
        'after=${ratio.toStringAsFixed(2)}');
    expect(ratio, greaterThanOrEqualTo(3), reason: label);
  }
  // Selected chip (edit screen only) must also hold over surfaceContainerHighest.
  if (label.startsWith('edit')) {
    final chip = icons.firstWhere((i) => i.size == AppSpacing.iconSize);
    final r = _worst(tester, chip.color!, tint, theme, includeHighest: true);
    // ignore: avoid_print
    print('CHIP $label ratio=${r.toStringAsFixed(2)}');
    expect(r, greaterThanOrEqualTo(3), reason: '$label chip');
  }
  // Tint fill and stored color are untouched.
  final tinted = tester.widgetList<Container>(find.byType(Container)).where(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color ==
                tint.withValues(alpha: 0.15),
      );
  expect(tinted, isNotEmpty, reason: '$label tint fill unchanged');
}

void main() {
  for (final brightness in Brightness.values) {
    for (final entry in _colors.entries) {
      final tint = Color(entry.value);
      final label = '${entry.key}/${brightness.name}';
      final theme = _theme(brightness);

      testWidgets('wallets list icon contrast $label', (tester) async {
        final w = _wallet(entry.value);
        await tester.pumpWidget(
            _app(brightness, const WalletsScreen(), _overrides(w)));
        await tester.pumpAndSettle();
        _checkIcons(tester, tint, theme, 'list $label');
        expect(w.colorValue, entry.value);
      });

      testWidgets('wallet picker icon contrast $label', (tester) async {
        final w = _wallet(entry.value);
        await tester.pumpWidget(_app(
          brightness,
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showWalletPicker(context, title: 'Pick'),
                child: const Text('open'),
              ),
            ),
          ),
          _overrides(w),
        ));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        _checkIcons(tester, tint, theme, 'picker $label');
      });

      testWidgets('wallet edit icon contrast $label', (tester) async {
        final w = _wallet(entry.value);
        await tester.pumpWidget(_app(
          brightness,
          WalletEditScreen(wallet: w, workspaceId: 'w1'),
          _overrides(w),
        ));
        await tester.pumpAndSettle();
        _checkIcons(tester, tint, theme, 'edit $label');
      });
    }
  }
}
