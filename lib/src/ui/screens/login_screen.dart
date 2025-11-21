// path: lib/src/ui/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setBool('isLoggedIn', true);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet, size: 80),
                const SizedBox(height: 32),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 48),
                AppInput(
                  label: l10n.loginPin,
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.required;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: l10n.loginButton,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

