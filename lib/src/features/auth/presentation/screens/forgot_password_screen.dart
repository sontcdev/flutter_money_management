import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/password_reset_code_screen.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = useTextEditingController(text: initialEmail);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> sendCode() async {
      if (isLoading.value || !formKey.currentState!.validate()) return;
      final email = emailController.text.trim();
      isLoading.value = true;
      errorMessage.value = null;
      try {
        await ref.read(supabaseAuthServiceProvider).resetPassword(email);
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PasswordResetCodeScreen(email: email),
          ),
        );
      } catch (_) {
        if (context.mounted) errorMessage.value = l10n.failedToSendResetEmail;
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.resetEmailInstructions),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l10n.email),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enabled: !isLoading.value,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return l10n.enterEmail;
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(email)) {
                      return l10n.enterValidEmailAddress;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => sendCode(),
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
                  text: l10n.sendResetCode,
                  isLoading: isLoading.value,
                  fullWidth: true,
                  onPressed: isLoading.value ? null : sendCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
