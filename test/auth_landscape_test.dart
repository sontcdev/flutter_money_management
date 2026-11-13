import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/password_reset_code_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';
import 'package:flutter_money_management/src/services/email_persistence_service.dart';
import 'package:flutter_money_management/src/shared/providers/app_service_providers.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';

class _MockAuthService extends Mock implements SupabaseAuthService {}

class _MockEmailPersistence extends Mock implements EmailPersistenceService {}

typedef _Scenario = ({
  String name,
  Size size,
  double scale,
  double keyboard,
  Brightness brightness,
});

const List<_Scenario> _scenarios = [
  (
    name: 'portrait',
    size: Size(390, 844),
    scale: 1.0,
    keyboard: 180,
    brightness: Brightness.light,
  ),
  (
    name: 'landscape',
    size: Size(844, 390),
    scale: 1.3,
    keyboard: 180,
    brightness: Brightness.dark,
  ),
  (
    name: 'wide',
    size: Size(1366, 1024),
    scale: 1.3,
    keyboard: 0,
    brightness: Brightness.light,
  ),
];

void main() {
  final screens = <(String, Widget, bool)>[
    ('SignIn', const SignInScreen(), true),
    ('SignUp', const SignUpScreen(), true),
    ('Forgot', const ForgotPasswordScreen(), true),
    ('Code', const PasswordResetCodeScreen(email: 'a@b.co'), true),
    ('Reset', const ResetPasswordScreen(), true),
  ];
  for (final locale in ['en', 'vi', 'ja']) {
    for (final sc in _scenarios) {
      for (final (name, screen, bounded) in screens) {
        testWidgets('$name fits $locale ${sc.name}', (tester) async {
          tester.view.physicalSize = sc.size;
          tester.view.devicePixelRatio = 1;
          tester.view.viewInsets = FakeViewPadding(bottom: sc.keyboard);
          addTearDown(tester.view.reset);
          final emailPersistence = _MockEmailPersistence();
          when(emailPersistence.getSavedEmail).thenReturn(null);
          await tester.pumpWidget(ProviderScope(
            overrides: [
              supabaseAuthServiceProvider.overrideWithValue(_MockAuthService()),
              emailPersistenceServiceProvider
                  .overrideWithValue(emailPersistence),
            ],
            child: MaterialApp(
              theme: ThemeData(brightness: sc.brightness),
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(sc.scale)),
                child: child!,
              ),
              home: screen,
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (bounded) {
            final column = find
                .descendant(
                  of: find.byType(AuthLayout),
                  matching: find.byType(Column),
                )
                .first;
            expect(tester.getSize(column).width,
                lessThanOrEqualTo(AuthLayout.maxWidth));
          }
          await tester.ensureVisible(find.byType(TextField).last);
          await tester.pumpAndSettle();
          expect(find.byType(TextField).last.hitTestable(), findsOneWidget);
          await tester.ensureVisible(find.byType(AppButton).first);
          await tester.pumpAndSettle();
          expect(find.byType(AppButton).first.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
