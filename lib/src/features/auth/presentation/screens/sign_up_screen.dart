import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
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
          displayName: displayNameController.text.trim().isEmpty
              ? null
              : displayNameController.text.trim(),
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
              AppLogger.info('Showing email verification dialog', name: 'MM.UI');
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
              'has_display_name': displayNameController.text.trim().isNotEmpty,
            },
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createAccount),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // App Icon
              Center(
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 80,
                  height: 80,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                l10n.createAccountToSync,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                l10n.verifyEmailBeforeSignInHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Display Name Field
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: l10n.displayNameOptional,
                  hintText: l10n.displayNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                enabled: !isLoading.value,
              ),

              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  hintText: l10n.emailExample,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading.value,
              ),

              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  hintText: l10n.atLeastSixCharacters,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
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

              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  hintText: l10n.reenterYourPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
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

              const SizedBox(height: 24),

              // Error Message
              if (errorMessage.value != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.value!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              if (errorMessage.value != null) const SizedBox(height: 16),

              // Sign Up Button
              OutlinedButton.icon(
                onPressed: isLoading.value ? null : handleSignUp,
                icon: isLoading.value
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_outlined, size: 16),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Text(
                    l10n.createAccount,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.alreadyHaveAccount),
                  TextButton(
                    onPressed: isLoading.value
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.signIn),
                  ),
                ],
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
    if (error.contains('already registered')) {
      return l10n.emailAlreadyRegistered;
    } else if (error.contains('invalid email')) {
      return l10n.enterValidEmailAddress;
    } else if (error.contains('weak password')) {
      return l10n.weakPassword;
    } else if (error.contains('network')) {
      return l10n.networkErrorCheckConnection;
    }
    return l10n.genericTryAgainError;
  }
}
