import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/auth_error_code.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
import 'package:flutter_money_management/src/utils/email_validator.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends HookConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final emailPersistence = ref.read(emailPersistenceServiceProvider);

    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final obscurePassword = useState(true);

    // Load saved email on mount
    useEffect(() {
      final savedEmail = emailPersistence.getSavedEmail();
      if (savedEmail != null) {
        emailController.text = savedEmail;
      }
      return null;
    }, []);

    final authService = ref.read(supabaseAuthServiceProvider);

    Future<void> handlePostLoginFlow() async {
      if (!context.mounted) return;

      try {
        AppLogger.info('Post-login workspace resolution started',
            name: 'MM.Auth');

        // Invalidate workspace list to force refresh with new session
        ref.invalidate(workspaceListProvider);

        // Fetch user's workspaces
        final workspaces = await ref.read(workspaceListProvider.future);
        AppLogger.info(
          'Workspace resolution completed: ${workspaces.length} workspaces',
          name: 'MM.Workspace',
        );

        if (!context.mounted) return;

        if (workspaces.isNotEmpty) {
          final activeWorkspaceId = ref.read(activeWorkspaceIdProvider);
          final workspaceId = activeWorkspaceId ?? workspaces.first.id;

          ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;
          AppLogger.info('Navigating to home after sign in', name: 'MM.UI');

          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          AppLogger.info('Navigating to workspace selection after sign in',
              name: 'MM.UI');
          Navigator.of(context).pushReplacementNamed('/workspace-selection');
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Post-login workspace resolution failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = l10n.failedToLoadWorkspaces('$e');

        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'auth',
            action: 'post_login_workspace_resolution',
            screen: 'sign_in_screen',
            extraContext: {
              'source': 'workspaceListProvider.future',
            },
          );
        }
      }
    }

    Future<void> handleSignIn() async {
      final email = emailController.text.trim();
      final password = passwordController.text;

      // Validation
      if (email.isEmpty) {
        errorMessage.value = l10n.enterEmail;
        return;
      }

      if (!isValidEmail(email)) {
        errorMessage.value = l10n.enterValidEmailAddress;
        return;
      }

      if (password.isEmpty) {
        errorMessage.value = l10n.enterPassword;
        return;
      }

      if (password.length < 6) {
        errorMessage.value = l10n.passwordMinLength;
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      ref.read(suppressAuthCallbackFeedbackProvider.notifier).state = true;

      try {
        AppLogger.info('Sign-in submitted', name: 'MM.UI');
        final response = await authService.signIn(
          email: email,
          password: password,
        );

        if (response.user != null && context.mounted) {
          AppLogger.info('Sign-in succeeded, preparing post-login flow',
              name: 'MM.Auth');
          TextInput.finishAutofillContext();
          // Save email for next time
          await emailPersistence.saveEmail(email);

          // Sign in successful, now resolve post-login flow
          await handlePostLoginFlow();
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Sign-in flow failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = _getErrorMessage(l10n, e);

        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'auth',
            action: 'sign_in',
            screen: 'sign_in_screen',
            extraContext: {
              'email_masked': ErrorReportHelper.maskEmail(email),
            },
          );
        }
      } finally {
        ref.read(suppressAuthCallbackFeedbackProvider.notifier).state = false;
        isLoading.value = false;
      }
    }

    void handleForgotPassword() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordScreen(
            initialEmail: emailController.text.trim(),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Brand icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: colorScheme.onPrimary,
                    size: 26,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                Text(
                  l10n.welcomeBack,
                  style: textTheme.headlineLarge,
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  l10n.signInToSyncAcrossDevices,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textLightSecondary
                        : AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Email Field
                Text(l10n.email, style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                ValueListenableBuilder(
                  valueListenable: emailController,
                  builder: (context, value, child) {
                    return TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: l10n.emailExample,
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                tooltip: l10n.clear,
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  emailController.clear();
                                  emailPersistence.clearEmail();
                                },
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading.value,
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password Field
                Text(l10n.password, style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    hintText: l10n.enterYourPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: obscurePassword.value
                          ? l10n.showPassword
                          : l10n.hidePassword,
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        obscurePassword.value = !obscurePassword.value;
                      },
                    ),
                  ),
                  obscureText: obscurePassword.value,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading.value,
                  onSubmitted: (_) => handleSignIn(),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading.value ? null : handleForgotPassword,
                    child: Text(l10n.forgotPassword),
                  ),
                ),

                // Error Message
                if (errorMessage.value != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.errorDark : AppColors.error)
                          .withValues(alpha: isDark ? 0.18 : 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: isDark ? AppColors.errorDark : AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            errorMessage.value!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.errorDark
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Sign In Button
                AppButton.prominent(
                  text: l10n.signIn,
                  isLoading: isLoading.value,
                  fullWidth: true,
                  onPressed: isLoading.value ? null : handleSignIn,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign Up Link
                Center(
                  child: TextButton.icon(
                    onPressed: isLoading.value
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                    icon: const Icon(
                      Icons.person_add_outlined,
                      size: AppSpacing.iconSizeXs,
                    ),
                    label: Text(l10n.createNewAccount),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(AppLocalizations l10n, Object exception) {
    switch (authErrorCode(exception)) {
      case 'invalid_credentials':
        return l10n.invalidEmailOrPassword;
      case 'email_not_confirmed':
        return l10n.verifyEmailBeforeSignIn;
      case 'over_request_rate_limit':
        return l10n.tooManyAttempts;
    }
    final error = exception.toString();
    if (error.contains('Invalid login credentials')) {
      return l10n.invalidEmailOrPassword;
    } else if (error.contains('Email not confirmed')) {
      return l10n.verifyEmailBeforeSignIn;
    } else if (error.contains('network')) {
      return l10n.networkErrorCheckConnection;
    } else if (error.contains('too many requests')) {
      return l10n.tooManyAttempts;
    }
    return l10n.signInFailed;
  }
}
