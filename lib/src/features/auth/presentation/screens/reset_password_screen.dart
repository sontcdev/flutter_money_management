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

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText =
        isDark ? AppColors.textLightSecondary : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.xl),
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
                enabled: !isLoading.value,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                enabled: !isLoading.value,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => handleSubmit(),
              ),
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
