import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_money_management/src/config/supabase_config.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!SupabaseConfig.isConfigured) {
    throw Exception('Supabase is not configured');
  }
  return Supabase.instance.client;
});

/// Supabase auth service provider
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthService(client);
});

/// Suppresses callback-specific UX during manual sign-in.
final suppressAuthCallbackFeedbackProvider =
    StateProvider<bool>((ref) => false);

/// Auth state stream provider
/// Emits auth state changes (signed in, signed out, etc.)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Current user provider
/// Returns the currently authenticated user, or null if not authenticated
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Current session provider
final currentSessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Check if user has a valid authenticated session
/// This is more strict than isAuthenticatedProvider - it checks for actual session
final hasValidSessionProvider = Provider<bool>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session != null && session.user.emailConfirmedAt != null;
});

/// Check if user needs email verification
/// True when user exists but email is not confirmed
final needsEmailVerificationProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.emailConfirmedAt == null;
});
