import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/utils/app_logger.dart';

/// Supabase cloud authentication service
/// Handles user signup, login, logout, and session management
class SupabaseAuthService {
  final SupabaseClient _client;

  SupabaseAuthService(this._client);

  static const _logName = 'MM.Auth';

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final maskedEmail = _maskEmail(email);
    AppLogger.info('Sign up started for $maskedEmail', name: _logName);

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      AppLogger.info('Sign up succeeded for $maskedEmail', name: _logName);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Sign up failed for $maskedEmail',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final maskedEmail = _maskEmail(email);
    AppLogger.info('Sign in started for $maskedEmail', name: _logName);

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLogger.info('Sign in succeeded for $maskedEmail', name: _logName);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Sign in failed for $maskedEmail',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    AppLogger.info('Sign out started', name: _logName);
    try {
      await _client.auth.signOut();
      AppLogger.info('Sign out succeeded', name: _logName);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Sign out failed',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    final maskedEmail = _maskEmail(email);
    AppLogger.info('Password reset started for $maskedEmail', name: _logName);
    try {
      await _client.auth.resetPasswordForEmail(email);
      AppLogger.info('Password reset request succeeded for $maskedEmail',
          name: _logName);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Password reset failed for $maskedEmail',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update user profile
  Future<UserResponse> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    AppLogger.info('Profile update started', name: _logName);
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );
      AppLogger.info('Profile update succeeded', name: _logName);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Profile update failed',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    AppLogger.info('Session refresh started', name: _logName);
    try {
      final response = await _client.auth.refreshSession();
      AppLogger.info('Session refresh succeeded', name: _logName);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Session refresh failed',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) {
      return 'masked-email';
    }

    final localPart = parts.first;
    final domain = parts.last;
    if (localPart.isEmpty) {
      return '***@$domain';
    }

    final maskedLocal = localPart.length == 1
        ? '${localPart[0]}***'
        : '${localPart[0]}***${localPart[localPart.length - 1]}';
    return '$maskedLocal@$domain';
  }
}
