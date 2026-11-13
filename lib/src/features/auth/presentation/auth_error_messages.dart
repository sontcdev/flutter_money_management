import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';

/// Auth operations whose failures are mapped to user-facing messages.
enum AuthOperation { signUp, sendReset, verifyReset, updatePassword }

enum AuthErrorKind { network, rateLimit, weakPassword, invalidEmail, other }

// Uniqueness pre-check messages thrown by SupabaseAuthService.
const _emailExistsMessage = 'Email này đã được đăng ký.';
const _usernameExistsMessage = 'Tên người dùng này đã tồn tại.';

const _rateLimitCodes = {
  'over_email_send_rate_limit',
  'over_request_rate_limit',
  'over_sms_send_rate_limit',
};

/// Classifies [error] after unwrapping [SupabaseOperationException.source].
AuthErrorKind classifyAuthError(Object error) {
  final raw = error is SupabaseOperationException
      ? (error.source ?? error)
      : error;

  if (raw is SocketException ||
      raw is TimeoutException ||
      raw is http.ClientException ||
      raw is AuthRetryableFetchException) {
    return AuthErrorKind.network;
  }
  if (raw is AuthException) {
    if (raw.statusCode == '429' || _rateLimitCodes.contains(raw.code)) {
      return AuthErrorKind.rateLimit;
    }
    if (raw is AuthWeakPasswordException || raw.code == 'weak_password') {
      return AuthErrorKind.weakPassword;
    }
    if (raw.code == 'email_address_invalid') {
      return AuthErrorKind.invalidEmail;
    }
  }
  return AuthErrorKind.other;
}

/// Returns the localized message for a failed [operation].
///
/// Reset-email errors never reveal whether an account exists.
String authErrorMessage(
  AppLocalizations l10n,
  AuthOperation operation,
  Object error,
) {
  if (operation == AuthOperation.signUp &&
      error is SupabaseOperationException &&
      error.source == null) {
    if (error.message == _emailExistsMessage) {
      return l10n.emailAlreadyRegistered;
    }
    if (error.message == _usernameExistsMessage) {
      return l10n.usernameAlreadyRegistered;
    }
  }

  final kind = classifyAuthError(error);
  if (kind == AuthErrorKind.network) return l10n.networkErrorCheckConnection;
  if (kind == AuthErrorKind.rateLimit) return l10n.tooManyAttempts;

  switch (operation) {
    case AuthOperation.signUp:
      if (kind == AuthErrorKind.weakPassword) return l10n.weakPassword;
      if (kind == AuthErrorKind.invalidEmail) return l10n.enterValidEmailAddress;
      return l10n.genericTryAgainError;
    case AuthOperation.sendReset:
      return l10n.failedToSendResetEmail;
    case AuthOperation.verifyReset:
      return l10n.resetCodeFailed;
    case AuthOperation.updatePassword:
      if (kind == AuthErrorKind.weakPassword) return l10n.weakPassword;
      return l10n.genericTryAgainError;
  }
}
