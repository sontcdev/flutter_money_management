import 'dart:async';

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
  static const _startupTimeout = Duration(seconds: 8);

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
      final authState =
          await ref.read(authStateProvider.future).timeout(_startupTimeout);

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
      final workspaces =
          await ref.read(workspaceListProvider.future).timeout(_startupTimeout);

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

      if (_isNetworkError(e)) {
        _isNavigating = false;
        final shouldRetry = await _showNetworkErrorDialog();
        if (!mounted) return;

        if (shouldRetry) {
          _handleNavigation();
        } else {
          Navigator.of(context).pushReplacementNamed('/sign-in');
        }
        return;
      }

      // On error, default to sign in
      Navigator.of(context).pushReplacementNamed('/sign-in');
    }
  }

  bool _isNetworkError(Object error) {
    if (error is TimeoutException) return true;

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('connection timed out') ||
        message.contains('authretryablefetchexception');
  }

  Future<bool> _showNetworkErrorDialog() async {
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Không có kết nối mạng'),
        content: const Text(
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng rồi thử lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Đăng nhập lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );

    return retry ?? false;
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
