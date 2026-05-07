// path: lib/src/ui/screens/auth/sign_in_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/workspace_providers.dart';
import '../../../utils/app_logger.dart';
import 'sign_up_screen.dart';

class SignInScreen extends HookConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final emailPersistence = ref.read(emailPersistenceServiceProvider);
    
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final obscurePassword = useState(true);

    // Load saved email on mount
    useEffect(() {
      final savedEmail = emailPersistence.getSavedEmail();
      if (savedEmail != null) {
        emailController.text = savedEmail;
      }
      return null;
    }, []);

    final authService = ref.read(supabaseAuthServiceProvider);

    Future<void> handlePostLoginFlow() async {
      if (!context.mounted) return;

      try {
        AppLogger.info('Post-login workspace resolution started', name: 'MM.Auth');

        // Invalidate workspace list to force refresh with new session
        ref.invalidate(workspaceListProvider);
        
        // Fetch user's workspaces
        final workspaces = await ref.read(workspaceListProvider.future);
        AppLogger.info(
          'Workspace resolution completed: ${workspaces.length} workspaces',
          name: 'MM.Workspace',
        );

        if (!context.mounted) return;

        if (workspaces.isNotEmpty) {
          final activeWorkspaceId = ref.read(activeWorkspaceIdProvider);
          final workspaceId = activeWorkspaceId ?? workspaces.first.id;

          ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;
          AppLogger.info('Navigating to home after sign in', name: 'MM.UI');

          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          AppLogger.info('Navigating to workspace selection after sign in', name: 'MM.UI');
          Navigator.of(context).pushReplacementNamed('/workspace-selection');
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Post-login workspace resolution failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = 'Failed to load workspaces: $e';
      }
    }

    Future<void> handleSignIn() async {
      final email = emailController.text.trim();
      final password = passwordController.text;

      // Validation
      if (email.isEmpty) {
        errorMessage.value = 'Please enter your email';
        return;
      }

      if (!_isValidEmail(email)) {
        errorMessage.value = 'Please enter a valid email address';
        return;
      }

      if (password.isEmpty) {
        errorMessage.value = 'Please enter your password';
        return;
      }

      if (password.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        AppLogger.info('Sign-in submitted', name: 'MM.UI');
        final response = await authService.signIn(
          email: email,
          password: password,
        );

        if (response.user != null && context.mounted) {
          AppLogger.info('Sign-in succeeded, preparing post-login flow', name: 'MM.Auth');
          // Save email for next time
          await emailPersistence.saveEmail(email);
          
          // Sign in successful, now resolve post-login flow
          await handlePostLoginFlow();
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Sign-in flow failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = _getErrorMessage(e.toString());
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleForgotPassword() async {
      if (emailController.text.trim().isEmpty) {
        errorMessage.value = 'Please enter your email to reset password';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        AppLogger.info('Forgot password submitted', name: 'MM.UI');
        await authService.resetPassword(emailController.text.trim());
        AppLogger.info('Forgot password request succeeded', name: 'MM.Auth');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent! Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Forgot password request failed',
          name: 'MM.Auth',
          error: e,
          stackTrace: stackTrace,
        );
        errorMessage.value = 'Failed to send reset email. Please try again.';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
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
                'Sign in to sync your data across devices',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Email Field
              ValueListenableBuilder(
                valueListenable: emailController,
                builder: (context, value, child) {
                  return TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'your@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              emailController.clear();
                              emailPersistence.clearEmail();
                            },
                          )
                        : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading.value,
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Password Field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
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
                textInputAction: TextInputAction.done,
                enabled: !isLoading.value,
                onSubmitted: (_) => handleSignIn(),
              ),
              
              const SizedBox(height: 8),
              
              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading.value ? null : handleForgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              
              const SizedBox(height: 16),
              
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
              
              // Sign In Button
              FilledButton(
                onPressed: isLoading.value ? null : handleSignIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign In'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Sign Up Link
              OutlinedButton.icon(
                onPressed: isLoading.value 
                  ? null 
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: Text(
                     'Create New Account',
                     style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
              
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Please verify your email before signing in';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection';
    } else if (error.contains('too many requests')) {
      return 'Too many attempts. Please try again later';
    }
    return 'Sign in failed. Please try again';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
