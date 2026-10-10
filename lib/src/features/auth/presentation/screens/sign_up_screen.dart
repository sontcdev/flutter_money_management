import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/auth_error_code.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
import 'package:flutter_money_management/src/utils/email_validator.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final displayNameController = useTextEditingController();

    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);

    final authService = ref.read(supabaseAuthServiceProvider);

    Future<void> handleSignUp() async {
      // Validation
      if (displayNameController.text.trim().isEmpty) {
        errorMessage.value = l10n.enterUsername;
        return;
      }

      if (emailController.text.trim().isEmpty) {
        errorMessage.value = l10n.enterEmail;
        return;
      }

      if (!isValidEmail(emailController.text.trim())) {
        errorMessage.value = l10n.enterValidEmail;
        return;
      }

      if (passwordController.text.isEmpty) {
        errorMessage.value = l10n.enterPassword;
        return;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = l10n.passwordMinLength;
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = l10n.passwordsDoNotMatch;
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        AppLogger.info('Sign-up submitted', name: 'MM.UI');
        final response = await authService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          displayName: displayNameController.text.trim(),
        );

        if (response.user != null) {
          AppLogger.info('Sign-up succeeded', name: 'MM.Auth');

          final session = response.session;

          // Check if user has valid session (email already confirmed)
          if (session != null && session.user.emailConfirmedAt != null) {
            // Email verification is disabled -> user is already authenticated
            // Navigate to '/' to let SplashScreen handle routing
            if (context.mounted) {
              AppLogger.info('Auto-login after sign-up', name: 'MM.Auth');
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            }
          } else {
            // Email verification is enabled, user needs to verify email
            // This case should not happen since email verification is disabled
            // But keep it for compatibility if re-enabled later
            if (context.mounted) {
              AppLogger.info('Showing email verification dialog',
                  name: 'MM.UI');
              await _showAccountCreatedDialog(context, l10n);
            }
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Sign-up flow failed',
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
            action: 'sign_up',
            screen: 'sign_up_screen',
            extraContext: {
              'email_masked':
                  ErrorReportHelper.maskEmail(emailController.text.trim()),
              'has_display_name': true,
            },
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return _SignUpForm(
      displayNameController: displayNameController,
      emailController: emailController,
      passwordController: passwordController,
      confirmPasswordController: confirmPasswordController,
      isLoading: isLoading.value,
      errorMessage: errorMessage.value,
      obscurePassword: obscurePassword.value,
      obscureConfirmPassword: obscureConfirmPassword.value,
      onToggleObscurePassword: () {
        obscurePassword.value = !obscurePassword.value;
      },
      onToggleObscureConfirmPassword: () {
        obscureConfirmPassword.value = !obscureConfirmPassword.value;
      },
      onSignUp: handleSignUp,
    );
  }

  Future<void> _showAccountCreatedDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountCreatedTitle),
        content: Text(l10n.accountCreatedMessage),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to sign in
              Navigator.of(context).pop();
            },
            child: Text(l10n.goToSignIn),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(AppLocalizations l10n, Object exception) {
    switch (authErrorCode(exception)) {
      case 'user_already_exists':
      case 'email_exists':
        return l10n.emailAlreadyRegistered;
      case 'email_address_invalid':
        return l10n.enterValidEmailAddress;
      case 'weak_password':
        return l10n.weakPassword;
    }
    final lower = exception.toString().toLowerCase();
    if (lower.contains('tên người dùng') ||
        lower.contains('username') ||
        lower.contains('display_name')) {
      return l10n.usernameAlreadyRegistered;
    } else if (lower.contains('already registered') ||
        lower.contains('email này đã được đăng ký')) {
      return l10n.emailAlreadyRegistered;
    } else if (lower.contains('invalid email')) {
      return l10n.enterValidEmailAddress;
    } else if (lower.contains('weak password')) {
      return l10n.weakPassword;
    } else if (lower.contains('network')) {
      return l10n.networkErrorCheckConnection;
    }
    return l10n.genericTryAgainError;
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.errorMessage,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirmPassword,
    required this.onSignUp,
  });

  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final String? errorMessage;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirmPassword;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText =
        isDark ? AppColors.textLightSecondary : AppColors.textSecondary;

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
                const SizedBox(height: AppSpacing.sm),

                // Back button
                const _SignUpHeader(),

                const SizedBox(height: AppSpacing.xl),

                // Username Field
                Text(l10n.displayNameOptional, style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: displayNameController,
                  decoration: InputDecoration(
                    hintText: l10n.displayNameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  autofillHints: const [AutofillHints.newUsername],
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Email Field
                Text(l10n.email, style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: l10n.emailExample,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password Field
                _SignUpPasswordField(
                  label: l10n.password,
                  hintText: l10n.atLeastSixCharacters,
                  controller: passwordController,
                  obscureText: obscurePassword,
                  onToggleObscure: onToggleObscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Confirm Password Field
                _SignUpPasswordField(
                  label: l10n.confirmPassword,
                  hintText: l10n.reenterYourPassword,
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  onToggleObscure: onToggleObscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onSubmitted: (_) => onSignUp(),
                ),

                // Error Message
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SignUpErrorBanner(message: errorMessage!),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Sign Up Button
                AppButton.prominent(
                  text: l10n.createAccount,
                  isLoading: isLoading,
                  fullWidth: true,
                  icon: isLoading ? null : Icons.person_add_outlined,
                  onPressed: isLoading ? null : onSignUp,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign In Link
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: textTheme.bodyMedium?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.signIn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText =
        isDark ? AppColors.textLightSecondary : AppColors.textSecondary;
    final faintText = context.semanticColors.textFaint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconButton(
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            side: BorderSide(color: colorScheme.outline, width: 1.5),
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.createAccount,
          style: textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.createAccountToSync,
          style: textTheme.bodyMedium?.copyWith(color: secondaryText),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.verifyEmailBeforeSignInHint,
          style: textTheme.bodySmall?.copyWith(
            color: faintText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _SignUpPasswordField extends StatelessWidget {
  const _SignUpPasswordField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.obscureText,
    required this.onToggleObscure,
    required this.textInputAction,
    required this.enabled,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final TextInputAction textInputAction;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: obscureText ? l10n.showPassword : l10n.hidePassword,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          obscureText: obscureText,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: textInputAction,
          enabled: enabled,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}

class _SignUpErrorBanner extends StatelessWidget {
  const _SignUpErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.errorDark : AppColors.error)
            .withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
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
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.errorDark : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
