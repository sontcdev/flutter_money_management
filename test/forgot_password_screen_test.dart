import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/password_reset_code_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

class _MockAuthService extends Mock implements SupabaseAuthService {}

void main() {
  late _MockAuthService service;
  setUp(() => service = _MockAuthService());

  Future<void> showScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseAuthServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opening forgot password does not send an email', (tester) async {
    await showScreen(tester, const ForgotPasswordScreen());
    expect(find.byType(TextFormField), findsOneWidget);
    verifyNever(() => service.resetPassword(any()));
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    verifyNever(() => service.resetPassword(any()));
  });

  testWidgets(
      'successful email request opens OTP entry without password fields',
      (tester) async {
    when(() => service.resetPassword('test@example.com'))
        .thenAnswer((_) async {});
    await showScreen(tester, const ForgotPasswordScreen());
    await tester.enterText(find.byType(TextFormField), ' test@example.com ');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    verify(() => service.resetPassword('test@example.com')).called(1);
    expect(find.byType(PasswordResetCodeScreen), findsOneWidget);
    expect(find.byType(ResetPasswordScreen), findsNothing);
  });

  testWidgets('failed email request stays on email entry', (tester) async {
    when(() => service.resetPassword('test@example.com'))
        .thenThrow(Exception('unavailable'));
    await showScreen(
        tester, const ForgotPasswordScreen(initialEmail: 'test@example.com'));
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordResetCodeScreen), findsNothing);
    expect(find.text('Failed to send reset email. Please try again.'),
        findsOneWidget);
  });

  testWidgets('password confirmation must match before updating',
      (tester) async {
    await showScreen(tester, const ResetPasswordScreen());
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'example-password');
    await tester.enterText(fields.at(1), 'different-password');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(() => service.updatePassword(any()));
  });
}
