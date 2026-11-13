import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:flutter_money_management/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAuth extends Fake implements SupabaseAuthService {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation i) {
    calls++;
    return super.noSuchMethod(i);
  }
}

ThemeData _theme(Brightness b, Color primary) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: b)
          .copyWith(primary: primary),
      extensions: [
        b == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light,
      ],
    );

void main() {
  final cases = <String, ThemeData>{
    'light bright yellow': _theme(Brightness.light, const Color(0xFFFFEB3B)),
    'light pale': _theme(Brightness.light, const Color(0xFFE8F5E9)),
    'dark bright': _theme(Brightness.dark, const Color(0xFF00E5FF)),
    'dark deep': _theme(Brightness.dark, const Color(0xFF1A237E)),
  };
  cases.forEach((name, theme) {
    testWidgets('settings tile icons contrast their fills: $name',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      PackageInfo.setMockInitialValues(
        appName: 'My Money',
        packageName: 'com.sontc.mymoney',
        version: '1.2.0',
        buildNumber: '1',
        buildSignature: '',
      );
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
          themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
          themeColorProvider.overrideWith((ref) => ThemeColorNotifier(prefs)),
          fontScaleProvider.overrideWith((ref) => FontScaleNotifier(prefs)),
        ],
        child: MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      var checked = 0;
      for (final box in tester.widgetList<Container>(find.byType(Container))) {
        final d = box.decoration;
        if (d is! BoxDecoration || d.color == null) continue;
        final fill = d.color!;
        final icons = find.descendant(
            of: find.byWidget(box), matching: find.byType(Icon));
        if (icons.evaluate().length != 1) continue;
        final icon = tester.widget<Icon>(icons);
        if (icon.size != 18 || icon.color == null) continue;
        checked++;
        expect(AppSurfaceTokens.contrast(icon.color!, fill),
            greaterThanOrEqualTo(3.0),
            reason: 'icon ${icon.icon} on $fill');
      }
      expect(checked, greaterThan(5));
    });

    testWidgets('logout dialog confirm text contrasts error fill: $name',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      PackageInfo.setMockInitialValues(
        appName: 'My Money',
        packageName: 'com.sontc.mymoney',
        version: '1.2.0',
        buildNumber: '1',
        buildSignature: '',
      );
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = _RecordingAuth();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseAuthServiceProvider.overrideWithValue(auth),
          currentUserProvider.overrideWithValue(const User(
              id: 'u1',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: '2026-01-01T00:00:00Z',
              email: 'a@b.c')),
          sharedPreferencesProvider.overrideWithValue(prefs),
          localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
          themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
          themeColorProvider.overrideWith((ref) => ThemeColorNotifier(prefs)),
          fontScaleProvider.overrideWith((ref) => FontScaleNotifier(prefs)),
        ],
        child: MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      final tile = find.text(l10n.logout);
      await tester.scrollUntilVisible(tile, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 400));

      final button = find.byType(FilledButton);
      expect(button, findsOneWidget);
      final label =
          find.descendant(of: button, matching: find.text(l10n.signOutTitle));
      final style = tester
          .widget<DefaultTextStyle>(find
              .ancestor(of: label, matching: find.byType(DefaultTextStyle))
              .first)
          .style;
      final fg = style.color!;
      final material = tester.widget<Material>(find
          .descendant(of: button, matching: find.byType(Material))
          .first);
      final fill = material.color!;
      expect(fill, AppColors.error);
      expect(AppSurfaceTokens.contrast(fg, fill), greaterThanOrEqualTo(4.5),
          reason: 'logout fg $fg on $fill');
      expect(auth.calls, 0);
    });
  });
}
