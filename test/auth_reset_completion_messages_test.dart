import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations_en.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/password_reset_code_screen.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';
import 'package:flutter_money_management/src/services/error_report_service.dart';
import 'package:flutter_money_management/src/shared/providers/app_service_providers.dart';

class _MockAuthService extends Mock implements SupabaseAuthService {}

class _MockErrorReportService extends Mock implements ErrorReportService {}

// Fake, non-secret values.
const _email = 'reviewer@example.com';
const _password = 'not-a-real-password';

const _rateLimit = AuthException(
  'rate limit raw text',
  statusCode: '429',
  code: 'over_request_rate_limit',
);

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

  group('verify reset code', () {
    Future<void> submit(WidgetTester tester, Object error) async {
      when(() => service.verifyPasswordResetCode(
            email: any(named: 'email'),
            code: any(named: 'code'),
          )).thenAnswer((_) async => throw error);
      await show(tester, const PasswordResetCodeScreen(email: _email));
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text(l10n.resetCodeVerify));
      await tester.pumpAndSettle();
    }

    testWidgets('network error shows connection message', (tester) async {
      await submit(tester, const SocketException('offline-host-xyz'));
      expect(find.text(l10n.networkErrorCheckConnection), findsOneWidget);
      expect(find.textContaining('offline-host-xyz'), findsNothing);
      expect(find.textContaining('SocketException'), findsNothing);
    });

    testWidgets('rate limit shows too-many-attempts message', (tester) async {
      await submit(tester, _rateLimit);
      expect(find.text(l10n.tooManyAttempts), findsOneWidget);
      expect(find.textContaining('rate limit raw text'), findsNothing);
    });

    testWidgets('unknown error shows generic reset code failure',
        (tester) async {
      await submit(tester, StateError('secret-internal-detail'));
      expect(find.text(l10n.resetCodeFailed), findsOneWidget);
      expect(find.textContaining('secret-internal-detail'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });
  });

  group('resend reset code', () {
    Future<void> resend(WidgetTester tester, Object error) async {
      when(() => service.resetPassword(_email))
          .thenAnswer((_) async => throw error);
      await show(tester, const PasswordResetCodeScreen(email: _email));
      await tester.tap(find.text(l10n.resetCodeResend));
      await tester.pumpAndSettle();
    }

    testWidgets('network error shows connection message', (tester) async {
      await resend(tester, const SocketException('offline-host-xyz'));
      expect(find.text(l10n.networkErrorCheckConnection), findsOneWidget);
      expect(find.textContaining('offline-host-xyz'), findsNothing);
    });

    testWidgets('rate limit shows too-many-attempts message', (tester) async {
      await resend(tester, _rateLimit);
      expect(find.text(l10n.tooManyAttempts), findsOneWidget);
      expect(find.textContaining('rate limit raw text'), findsNothing);
    });

    testWidgets(
        'unknown and user-not-found errors share one generic message '
        '(no account enumeration)', (tester) async {
      await resend(tester, StateError('secret-internal-detail'));
      expect(find.text(l10n.failedToSendResetEmail), findsOneWidget);
      expect(find.textContaining('secret-internal-detail'), findsNothing);

      when(() => service.resetPassword(_email)).thenAnswer((_) async =>
          throw const AuthException('User not found',
              statusCode: '400', code: 'user_not_found'));
      await tester.tap(find.text(l10n.resetCodeResend));
      await tester.pumpAndSettle();
      expect(find.text(l10n.failedToSendResetEmail), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
    });
  });

  group('update password', () {
    Future<void> submit(WidgetTester tester, Object error) async {
      when(() => service.updatePassword(any()))
          .thenAnswer((_) async => throw error);
      await show(tester, const ResetPasswordScreen());
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), _password);
      await tester.enterText(fields.at(1), _password);
      await tester.tap(find.text(l10n.resetPasswordAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await dismissDialogIfAny(tester);
    }

    testWidgets('network error shows connection message', (tester) async {
      await submit(tester, const SocketException('offline-host-xyz'));
      expect(find.text(l10n.networkErrorCheckConnection), findsOneWidget);
      expect(find.textContaining('offline-host-xyz'), findsNothing);
    });

    testWidgets('rate limit shows too-many-attempts message', (tester) async {
      await submit(tester, _rateLimit);
      expect(find.text(l10n.tooManyAttempts), findsOneWidget);
      expect(find.textContaining('rate limit raw text'), findsNothing);
    });

    testWidgets('weak password shows weak password message', (tester) async {
      await submit(
        tester,
        const AuthException('weak raw text',
            statusCode: '422', code: 'weak_password'),
      );
      expect(find.text(l10n.passwordMinLength), findsOneWidget);
      expect(find.textContaining('weak raw text'), findsNothing);
    });

    testWidgets('unknown error shows generic message, no raw error',
        (tester) async {
      await submit(tester, StateError('secret-internal-detail'));
      expect(find.text(l10n.genericTryAgainError), findsOneWidget);
      expect(find.textContaining('secret-internal-detail'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });
  });
}
