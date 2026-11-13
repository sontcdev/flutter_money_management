import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/screens/wallets_screen.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _names = {
  'vi':
      'Ví tiết kiệm dài hạn cho kế hoạch mua nhà và đầu tư gia đình năm 2030 rất dài',
  'en':
      'Long term savings wallet for the house purchase and family investments in 2030 very long',
  'ja': '住宅購入と家族の投資のための長期貯蓄用ウォレットで非常に長い名前の例です二〇三〇年',
};

Wallet _w(String name) => Wallet(
      id: 'wl1',
      workspaceId: 'w1',
      name: name,
      walletType: WalletType.bank,
      iconName: 'account_balance',
      colorValue: 0xFF2196F3,
      openingBalanceMinor: -123456789,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _app(String lang, Brightness b, double scale, Wallet w, bool manage,
    Map<String, Object?> routes) {
  final theme = b == Brightness.light
      ? AppTheme.lightTheme(primaryColor: const Color(0xFF00884B))
      : AppTheme.darkTheme(primaryColor: const Color(0xFF00884B));
  return ProviderScope(
    overrides: [
      walletsProvider.overrideWith((ref) async => [w]),
      walletBalancesProvider.overrideWith((ref) async => {w.id: -123456789}),
      canManageWorkspaceContentProvider.overrideWithValue(manage),
    ],
    child: MaterialApp(
      theme: theme,
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      onGenerateRoute: (s) {
        if (s.name == '/wallet-edit') {
          routes['edit'] = s.arguments;
          return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('EDITOR')));
        }
        return MaterialPageRoute(builder: (_) => const WalletsScreen());
      },
      home: const WalletsScreen(),
    ),
  );
}

final _menu = find.byWidgetPredicate((w) => w is PopupMenuButton);

void main() {
  for (final lang in _names.keys) {
    for (final b in Brightness.values) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('long name no overflow $lang ${b.name} x$scale',
            (tester) async {
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester
              .pumpWidget(_app(lang, b, scale, _w(_names[lang]!), true, {}));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final name = tester.widget<Text>(find.text(_names[lang]!));
          expect(name.maxLines, 2);
          expect(_menu, findsOneWidget);
          expect(find.byIcon(Icons.delete_outline), findsNothing);
        });
      }
    }
  }

  testWidgets('row tap opens editor with wallet', (tester) async {
    final routes = <String, Object?>{};
    final w = _w('Main');
    await tester.pumpWidget(_app('en', Brightness.light, 1, w, true, routes));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(find.text('EDITOR'), findsOneWidget);
    expect((routes['edit'] as Wallet).id, 'wl1');
  });

  testWidgets('menu edit opens editor; delete shows confirmation',
      (tester) async {
    final routes = <String, Object?>{};
    await tester
        .pumpWidget(_app('en', Brightness.light, 1, _w('Main'), true, routes));
    await tester.pumpAndSettle();
    await tester.tap(_menu.first);
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete wallet'), findsWidgets);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(_menu.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('EDITOR'), findsOneWidget);
  });

  testWidgets('member without permission has no tap or menu', (tester) async {
    final routes = <String, Object?>{};
    await tester
        .pumpWidget(_app('en', Brightness.light, 1, _w('Main'), false, routes));
    await tester.pumpAndSettle();
    expect(_menu, findsNothing);
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(find.text('EDITOR'), findsNothing);
    expect(routes, isEmpty);
  });
}
