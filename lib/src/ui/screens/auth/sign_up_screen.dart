// path: lib/src/ui/screens/auth/sign_up_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../providers/auth_providers.dart';
import '../../../utils/app_logger.dart';

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        errorMessage.value = 'Please enter your email';
        return;
      }
      
      if (!_isValidEmail(emailController.text.trim())) {
        errorMessage.value = 'Please enter a valid email';
        return;
      }

      if (passwordController.text.isEmpty) {
        errorMessage.value = 'Please enter a password';
        return;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = 'Passwords do not match';
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
          // Account created successfully
          // Since email confirmation is enabled, user needs to verify email before signing in
          if (context.mounted) {
            AppLogger.info('Showing email verification dialog', name: 'MM.UI');
            // Show success dialog with clear instructions
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Account Created!'),
                content: const Text(
                  'Your account has been created successfully.\n\n'
                  'Please check your email and click the verification link to activate your account.\n\n'
                  'After verification, you can sign in to start using the app.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate back to sign in
                      Navigator.of(context).pop();
                    },
                    child: const Text('Go to Sign In'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Sign-up flow failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = _getErrorMessage(e.toString());
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
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
                'Money Wise',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Create your account to sync across devices',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'You will need to verify your email before signing in',
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
                decoration: const InputDecoration(
                  labelText: 'Display Name (Optional)',
                  hintText: 'How should we call you?',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                enabled: !isLoading.value,
              ),
              
              const SizedBox(height: 16),
              
              // Email Field
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
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
                  labelText: 'Password',
                  hintText: 'At least 6 characters',
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
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword.value 
                        ? Icons.visibility_outlined 
                        : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      obscureConfirmPassword.value = !obscureConfirmPassword.value;
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
              OutlinedButton(
                onPressed: isLoading.value ? null : handleSignUp,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: isLoading.value 
                      ? null 
                      : () => Navigator.of(context).pop(),
                    child: const Text('Sign In'),
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

  String _getErrorMessage(String error) {
    if (error.contains('already registered')) {
      return 'This email is already registered';
    } else if (error.contains('invalid email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection';
    }
    return 'An error occurred. Please try again';
  }
}
