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

class ResetPasswordScreen extends HookConsumerWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);
    final authService = ref.read(supabaseAuthServiceProvider);

    Future<void> handleSubmit() async {
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
        await authService.updatePassword(passwordController.text);

        if (!context.mounted) return;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.passwordResetCompleteTitle),
            content: Text(l10n.passwordResetCompleteMessage),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.done),
              ),
            ],
          ),
        );

        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      } catch (e, stackTrace) {
        AppLogger.error(
          'Reset password flow failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = l10n.genericTryAgainError;

        if (context.mounted) {
          await ErrorReportHelper.handleApiError(
            context: context,
            ref: ref,
            error: e,
            stackTrace: stackTrace,
            feature: 'auth',
            action: 'reset_password_update',
            screen: 'reset_password_screen',
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const _ResetPasswordHeader(),
              const SizedBox(height: AppSpacing.xl),
              _ResetPasswordField(
                label: l10n.password,
                hintText: l10n.atLeastSixCharacters,
                controller: passwordController,
                obscureText: obscurePassword.value,
                onToggleObscure: () {
                  obscurePassword.value = !obscurePassword.value;
                },
                enabled: !isLoading.value,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ResetPasswordField(
                label: l10n.confirmPassword,
                hintText: l10n.reenterYourPassword,
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword.value,
                onToggleObscure: () {
                  obscureConfirmPassword.value =
                      !obscureConfirmPassword.value;
                },
                enabled: !isLoading.value,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => handleSubmit(),
              ),
              if (errorMessage.value != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ResetPasswordErrorBanner(message: errorMessage.value!),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton.prominent(
                text: l10n.resetPasswordAction,
                isLoading: isLoading.value,
                fullWidth: true,
                icon: isLoading.value ? null : Icons.check_circle_outline,
                onPressed: isLoading.value ? null : handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordHeader extends StatelessWidget {
  const _ResetPasswordHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText =
        isDark ? AppColors.textLightSecondary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_outlined,
              size: 36,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.resetPasswordTitle,
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.resetPasswordCallbackMessage,
          style: textTheme.bodyMedium?.copyWith(color: secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ResetPasswordField extends StatelessWidget {
  const _ResetPasswordField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.obscureText,
    required this.onToggleObscure,
    required this.enabled,
    required this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final TextInputAction textInputAction;
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
          enabled: enabled,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}

class _ResetPasswordErrorBanner extends StatelessWidget {
  const _ResetPasswordErrorBanner({required this.message});

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
