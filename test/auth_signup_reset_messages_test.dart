import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations_en.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/password_reset_code_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';
import 'package:flutter_money_management/src/services/error_report_service.dart';
import 'package:flutter_money_management/src/shared/providers/app_service_providers.dart';

class _MockAuthService extends Mock implements SupabaseAuthService {}

class _MockErrorReportService extends Mock implements ErrorReportService {}

// Fake, non-secret values.
const _email = 'reviewer@example.com';
const _password = 'not-a-real-password';

void main() {
  final l10n = AppLocalizationsEn();
  late _MockAuthService service;

  setUp(() => service = _MockAuthService());

  Future<void> show(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseAuthServiceProvider.overrideWithValue(service),
          errorReportServiceProvider
              .overrideWithValue(_MockErrorReportService()),
        ],
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

  // API-like errors open the optional error report dialog; dismiss it.
  Future<void> dismissDialogIfAny(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> submitSignUp(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'reviewer');
    await tester.enterText(fields.at(1), _email);
    await tester.enterText(fields.at(2), _password);
    await tester.enterText(fields.at(3), _password);
    final button = find.text(l10n.createAccount).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await dismissDialogIfAny(tester);
  }

  void stubSignUpError(Object error) {
    when(() => service.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => throw error);
  }

  group('sign up', () {
    testWidgets('network error shows connection message, no raw error',
        (tester) async {
      stubSignUpError(const SocketException('offline-host-xyz'));
      await show(tester, const SignUpScreen());
      await submitSignUp(tester);

      expect(find.text(l10n.networkErrorCheckConnection), findsOneWidget);
      expect(find.textContaining('offline-host-xyz'), findsNothing);
      expect(find.textContaining('SocketException'), findsNothing);
    });

    testWidgets('rate limit shows too-many-attempts message', (tester) async {
      stubSignUpError(const AuthException(
        'rate limit raw text',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      ));
      await show(tester, const SignUpScreen());
      await submitSignUp(tester);

      expect(find.text(l10n.tooManyAttempts), findsOneWidget);
      expect(find.textContaining('rate limit raw text'), findsNothing);
      expect(find.textContaining('AuthException'), findsNothing);
    });

    testWidgets('unknown error shows generic message, no raw error',
        (tester) async {
      stubSignUpError(StateError('secret-internal-detail'));
      await show(tester, const SignUpScreen());
      await submitSignUp(tester);

      expect(find.text(l10n.genericTryAgainError), findsOneWidget);
      expect(find.textContaining('secret-internal-detail'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });
  });

  group('forgot password', () {
    Future<void> submitReset(WidgetTester tester) async {
      await show(tester, const ForgotPasswordScreen(initialEmail: _email));
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
    }

    void stubResetError(Object error) {
      when(() => service.resetPassword(_email))
          .thenAnswer((_) async => throw error);
    }

    testWidgets('network error shows connection message', (tester) async {
      stubResetError(const SocketException('offline-host-xyz'));
      await submitReset(tester);

      expect(find.text(l10n.networkErrorCheckConnection), findsOneWidget);
      expect(find.textContaining('offline-host-xyz'), findsNothing);
      expect(find.byType(PasswordResetCodeScreen), findsNothing);
    });

    testWidgets('rate limit shows too-many-attempts message', (tester) async {
      stubResetError(const AuthException(
        'rate limit raw text',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      ));
      await submitReset(tester);

      expect(find.text(l10n.tooManyAttempts), findsOneWidget);
      expect(find.textContaining('rate limit raw text'), findsNothing);
      expect(find.byType(PasswordResetCodeScreen), findsNothing);
    });

    testWidgets(
        'unknown and user-not-found errors share one generic message '
        '(no account enumeration)', (tester) async {
      stubResetError(StateError('secret-internal-detail'));
      await submitReset(tester);
      expect(find.text(l10n.failedToSendResetEmail), findsOneWidget);
      expect(find.textContaining('secret-internal-detail'), findsNothing);

      stubResetError(const AuthException(
        'User not found',
        statusCode: '400',
        code: 'user_not_found',
      ));
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.failedToSendResetEmail), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
      expect(find.byType(PasswordResetCodeScreen), findsNothing);
    });
  });
}
