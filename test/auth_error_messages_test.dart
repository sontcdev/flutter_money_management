import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations_en.dart';
import 'package:flutter_money_management/l10n/app_localizations_ja.dart';
import 'package:flutter_money_management/l10n/app_localizations_vi.dart';
import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/auth/presentation/auth_error_messages.dart';

void main() {
  final l10n = AppLocalizationsEn();

  String msg(AuthOperation op, Object e) => authErrorMessage(l10n, op, e);
  SupabaseOperationException wrap(Object e) =>
      SupabaseOperationException('mapped', source: e);

  final networkErrors = <String, Object>{
    'SocketException': const SocketException('x'),
    'TimeoutException': TimeoutException('x'),
    'ClientException': http.ClientException('x'),
    'AuthRetryableFetchException': AuthRetryableFetchException(),
  };
  final rateErrors = <String, Object>{
    'status 429': const AuthException('x', statusCode: '429'),
    'email code': const AuthException('x', code: 'over_email_send_rate_limit'),
    'request code': const AuthException('x', code: 'over_request_rate_limit'),
  };

  group('network and rate limit for every operation', () {
    for (final op in AuthOperation.values) {
      networkErrors.forEach((name, e) {
        test('$op raw $name', () {
          expect(msg(op, e), l10n.networkErrorCheckConnection);
        });
        test('$op wrapped $name', () {
          expect(msg(op, wrap(e)), l10n.networkErrorCheckConnection);
        });
      });
      rateErrors.forEach((name, e) {
        test('$op raw $name', () {
          expect(msg(op, e), l10n.tooManyAttempts);
        });
        test('$op wrapped $name', () {
          expect(msg(op, wrap(e)), l10n.tooManyAttempts);
        });
      });
    }
  });

  group('signUp', () {
    test('weak password by type and code', () {
      final typed = AuthWeakPasswordException(
          message: 'x', statusCode: '422', reasons: const ['length']);
      expect(msg(AuthOperation.signUp, typed), l10n.weakPassword);
      expect(
          msg(AuthOperation.signUp,
              wrap(const AuthException('x', code: 'weak_password'))),
          l10n.weakPassword);
    });
    test('invalid email', () {
      expect(
          msg(AuthOperation.signUp,
              wrap(const AuthException('x', code: 'email_address_invalid'))),
          l10n.enterValidEmailAddress);
    });
    test('localizes uniqueness messages in en/vi/ja', () {
      for (final l in [
        AppLocalizationsEn(),
        AppLocalizationsVi(),
        AppLocalizationsJa(),
      ]) {
        expect(
            authErrorMessage(l, AuthOperation.signUp,
                const SupabaseOperationException('Email này đã được đăng ký.')),
            l.emailAlreadyRegistered);
        expect(
            authErrorMessage(
                l,
                AuthOperation.signUp,
                const SupabaseOperationException(
                    'Tên người dùng này đã tồn tại.')),
            l.usernameAlreadyRegistered);
      }
      expect(AppLocalizationsJa().emailAlreadyRegistered,
          isNot(AppLocalizationsEn().emailAlreadyRegistered));
    });
    test('near-miss precheck text is not matched', () {
      expect(
          msg(AuthOperation.signUp,
              const SupabaseOperationException('Email này đã được đăng ký')),
          l10n.genericTryAgainError);
      expect(
          msg(
              AuthOperation.signUp,
              const SupabaseOperationException('Email này đã được đăng ký.',
                  source: AuthException('x'))),
          l10n.genericTryAgainError);
      expect(
          msg(AuthOperation.sendReset,
              const SupabaseOperationException('Email này đã được đăng ký.')),
          l10n.failedToSendResetEmail);
    });
    test('unknown', () {
      expect(msg(AuthOperation.signUp, Exception('boom')),
          l10n.genericTryAgainError);
      expect(
          msg(AuthOperation.signUp,
              wrap(const AuthException('x', code: 'user_already_exists'))),
          l10n.genericTryAgainError);
    });
  });

  group('sendReset anti-enumeration', () {
    test('user-not-found style errors give the generic failure', () {
      for (final e in <Object>[
        const AuthException('User not found', statusCode: '404'),
        const AuthException('x', code: 'user_not_found'),
        const AuthException('x', code: 'email_address_invalid'),
        AuthWeakPasswordException(
            message: 'x', statusCode: '422', reasons: const []),
        Exception('boom'),
      ]) {
        expect(msg(AuthOperation.sendReset, e), l10n.failedToSendResetEmail);
        expect(
            msg(AuthOperation.sendReset, wrap(e)), l10n.failedToSendResetEmail);
      }
    });
  });

  group('verifyReset', () {
    test('other errors give resetCodeFailed', () {
      expect(
          msg(AuthOperation.verifyReset,
              const AuthException('Token expired', code: 'otp_expired')),
          l10n.resetCodeFailed);
      expect(
          msg(AuthOperation.verifyReset, Exception('x')), l10n.resetCodeFailed);
    });
  });

  group('updatePassword', () {
    test('weak password', () {
      expect(
          msg(AuthOperation.updatePassword,
              wrap(const AuthException('x', code: 'weak_password'))),
          l10n.weakPassword);
    });
    test('unknown', () {
      expect(msg(AuthOperation.updatePassword, Exception('x')),
          l10n.genericTryAgainError);
    });
  });
}
