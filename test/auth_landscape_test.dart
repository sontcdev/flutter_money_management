import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';
import 'package:flutter_money_management/src/services/email_persistence_service.dart';
import 'package:flutter_money_management/src/shared/providers/app_service_providers.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';

class _MockAuthService extends Mock implements SupabaseAuthService {}

class _MockEmailPersistence extends Mock implements EmailPersistenceService {}

void main() {
  for (final locale in ['en', 'vi', 'ja']) {
    for (final size in [const Size(844, 390), const Size(1366, 1024)]) {
      for (final screen in const [
        SignInScreen(),
        SignUpScreen(),
        ResetPasswordScreen(),
      ]) {
        testWidgets('${screen.runtimeType} fits $locale landscape $size',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
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
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: screen,
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byType(TextField).last);
          await tester.pumpAndSettle();
          expect(find.byType(TextField).last.hitTestable(), findsOneWidget);
          await tester.ensureVisible(find.byType(AppButton));
          await tester.pumpAndSettle();
          expect(find.byType(AppButton).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
