// path: lib/src/ui/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authService = ref.watch(authServiceProvider);
    final pinController = useTextEditingController();
    final isLoading = useState(false);
    final hasPin = authService.hasPin();

    Future<void> handleLogin() async {
      if (pinController.text.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must be at least 4 digits')),
        );
        return;
      }

      isLoading.value = true;

      try {
        if (hasPin) {
          // Verify PIN
          final isValid = await authService.verifyPin(pinController.text);
          if (isValid) {
            await authService.login(pinController.text);
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid PIN')),
              );
            }
          }
        } else {
          // Create new PIN
          await authService.login(pinController.text);
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 48),
              AppInput(
                label: l10n.pin,
                hint: hasPin ? 'Enter your PIN' : 'Create a PIN',
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: l10n.login,
                  onPressed: handleLogin,
                  isLoading: isLoading.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

