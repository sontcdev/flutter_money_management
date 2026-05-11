import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';

class AuthCallbackFeedbackListener extends ConsumerStatefulWidget {
  final Widget child;

  const AuthCallbackFeedbackListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AuthCallbackFeedbackListener> createState() =>
      _AuthCallbackFeedbackListenerState();
}

class _AuthCallbackFeedbackListenerState
    extends ConsumerState<AuthCallbackFeedbackListener> {
  String? _lastHandledRecoveryToken;
  String? _lastHandledVerifiedToken;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenData((authState) {
        final session = authState.session;
        final token = session?.accessToken;

        switch (authState.event) {
          case AuthChangeEvent.passwordRecovery:
            if (token == null || token == _lastHandledRecoveryToken) {
              return;
            }

            _lastHandledRecoveryToken = token;
            AppLogger.info('Password recovery callback received',
                name: 'MM.Auth');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/reset-password',
                (_) => false,
              );
            });
            return;
          case AuthChangeEvent.signedIn:
            final suppressed = ref.read(suppressAuthCallbackFeedbackProvider);
            final isConfirmed = session?.user.emailConfirmedAt != null;
            if (suppressed || !isConfirmed || token == null) {
              return;
            }

            if (token == _lastHandledVerifiedToken) {
              return;
            }

            _lastHandledVerifiedToken = token;
            AppLogger.info('Email verification callback received',
                name: 'MM.Auth');

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;

              final l10n = AppLocalizations.of(context)!;
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.emailVerifiedTitle),
                  content: Text(l10n.emailVerifiedMessage),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.done),
                    ),
                  ],
                ),
              );
            });
            return;
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.signedOut:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.userUpdated:
          case AuthChangeEvent.mfaChallengeVerified:
            return;
          default:
            return;
        }
      });
    });

    return widget.child;
  }
}
