import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';
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

      if (!_isValidEmail(emailController.text.trim())) {
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
              await showDialog(
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
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Sign-up flow failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = _getErrorMessage(l10n, e.toString());

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

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText =
        isDark ? AppColors.textLightSecondary : AppColors.textSecondary;
    final faintText = isDark ? AppColors.textLightFaint : AppColors.textFaint;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Back button
              IconButton(
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
                textInputAction: TextInputAction.next,
                enabled: !isLoading.value,
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
                textInputAction: TextInputAction.next,
                enabled: !isLoading.value,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Password Field
              Text(l10n.password, style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: l10n.atLeastSixCharacters,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
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
                textInputAction: TextInputAction.next,
                enabled: !isLoading.value,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Confirm Password Field
              Text(l10n.confirmPassword, style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  hintText: l10n.reenterYourPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      obscureConfirmPassword.value =
                          !obscureConfirmPassword.value;
                    },
                  ),
                ),
                obscureText: obscureConfirmPassword.value,
                textInputAction: TextInputAction.done,
                enabled: !isLoading.value,
                onSubmitted: (_) => handleSignUp(),
              ),

              // Error Message
              if (errorMessage.value != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.errorDark : AppColors.error)
                        .withValues(alpha: isDark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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

              const SizedBox(height: AppSpacing.xl),

              // Sign Up Button
              AppButton.prominent(
                text: l10n.createAccount,
                isLoading: isLoading.value,
                fullWidth: true,
                icon: isLoading.value ? null : Icons.person_add_outlined,
                onPressed: isLoading.value ? null : handleSignUp,
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
                      onPressed: isLoading.value
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
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getErrorMessage(AppLocalizations l10n, String error) {
    final lower = error.toLowerCase();
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
