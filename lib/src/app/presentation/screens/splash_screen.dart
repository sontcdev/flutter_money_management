import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';

/// Splash screen that acts as the single route gate coordinator
/// Determines the correct route based on auth state, email verification, and workspace state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigation();
    });
  }

  Future<void> _handleNavigation() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // Wait for auth state to be available
      final authState = await ref.read(authStateProvider.future);

      if (!mounted) return;

      // Check if user needs email verification
      final needsEmailVerification = ref.read(needsEmailVerificationProvider);

      // Case 1: No session at all -> sign in
      if (authState.session == null) {
        Navigator.of(context).pushReplacementNamed('/sign-in');
        return;
      }

      // Case 2: Has user but email not confirmed -> should not happen in normal flow
      // but if it does, send back to sign in
      if (needsEmailVerification) {
        Navigator.of(context).pushReplacementNamed('/sign-in');
        return;
      }

      // Case 3: Valid session, check workspaces.
      ref.invalidate(workspaceListProvider);
      final workspaces = await ref.read(workspaceListProvider.future);

      if (!mounted) return;

      if (workspaces.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/workspace-selection');
      } else {
        final activeWorkspaceId = ref.read(activeWorkspaceIdProvider);
        final workspaceId = activeWorkspaceId ?? workspaces.first.id;

        ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      // On error, default to sign in
      Navigator.of(context).pushReplacementNamed('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
