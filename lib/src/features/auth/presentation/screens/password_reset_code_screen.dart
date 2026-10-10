import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';

class PasswordResetCodeScreen extends HookConsumerWidget {
  const PasswordResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final codeController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final authService = ref.read(supabaseAuthServiceProvider);

    Future<void> verifyCode() async {
      if (isLoading.value || !formKey.currentState!.validate()) return;
      isLoading.value = true;
      errorMessage.value = null;
      try {
        await authService.verifyPasswordResetCode(
          email: email,
          code: codeController.text,
        );
      } catch (_) {
        if (context.mounted) errorMessage.value = l10n.resetCodeFailed;
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    Future<void> resendCode() async {
      if (isLoading.value) return;
      isLoading.value = true;
      errorMessage.value = null;
      try {
        await authService.resetPassword(email);
        if (!context.mounted) return;
        codeController.clear();
        showAppSnackBar(
          context,
          l10n.passwordResetEmailSent,
          type: AppSnackBarType.success,
        );
      } catch (_) {
        if (context.mounted) errorMessage.value = l10n.failedToSendResetEmail;
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetCodeTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.resetCodeInstructions),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: codeController,
                  decoration: InputDecoration(labelText: l10n.resetCodeLabel),
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !isLoading.value,
                  textInputAction: TextInputAction.done,
                  validator: (value) => value == null || value.length < 6
                      ? l10n.resetCodeInvalid
                      : null,
                  onFieldSubmitted: (_) => verifyCode(),
                ),
                if (errorMessage.value != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage.value!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton.prominent(
                  text: l10n.resetCodeVerify,
                  isLoading: isLoading.value,
                  fullWidth: true,
                  onPressed: isLoading.value ? null : verifyCode,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: isLoading.value ? null : resendCode,
                  child: Text(l10n.resetCodeResend),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
