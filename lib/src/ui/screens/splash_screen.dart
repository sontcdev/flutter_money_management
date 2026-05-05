// path: lib/src/ui/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/migration_providers.dart';
import '../../providers/workspace_providers.dart';

/// Splash screen that acts as the single route gate coordinator
/// Determines the correct route based on auth state, email verification, workspace, and migration status
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigation();
    });
  }

  Future<void> _handleNavigation() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // Wait for auth state to be available
      final authState = await ref.read(authStateProvider.future);

      if (!mounted) return;

      // Check if user needs email verification
      final needsEmailVerification = ref.read(needsEmailVerificationProvider);

      // Case 1: No session at all -> sign in
      if (authState.session == null) {
        Navigator.of(context).pushReplacementNamed('/sign-in');
        return;
      }

      // Case 2: Has user but email not confirmed -> should not happen in normal flow
      // but if it does, send back to sign in
      if (needsEmailVerification) {
        Navigator.of(context).pushReplacementNamed('/sign-in');
        return;
      }

      // Case 3: Valid session, check migration
      final needsMigration = ref.read(needsMigrationProvider);

      if (needsMigration) {
        await _performMigration();
        return;
      }

      // Case 4: Valid session, no migration needed, check workspaces
      final workspaces = await ref.read(workspaceListProvider.future);

      if (!mounted) return;

      if (workspaces.isEmpty) {
        // No workspaces, go to workspace selection
        Navigator.of(context).pushReplacementNamed('/workspace-selection');
      } else {
        // Has workspaces, set active workspace and go to home
        final activeWorkspaceId = ref.read(activeWorkspaceIdProvider);
        if (activeWorkspaceId == null) {
          // Set first workspace as active
          ref.read(activeWorkspaceIdProvider.notifier).state = workspaces.first.id;
        }
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      // On error, default to sign in
      Navigator.of(context).pushReplacementNamed('/sign-in');
    }
  }

  Future<void> _performMigration() async {
    try {
      // Show migration dialog
      if (!mounted) return;

      final shouldMigrate = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Migrate Local Data'),
          content: const Text(
            'We found local data on your device. Would you like to migrate it to the cloud?\n\n'
            'This will create a new workspace with all your existing categories, transactions, and budgets.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Migrate'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (shouldMigrate == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Migrating your data...'),
              ],
            ),
          ),
        );

        // Perform migration
        final workspaceId = await ref.read(
          performMigrationProvider('My Workspace').future,
        );

        if (!mounted) return;

        // Close loading dialog
        Navigator.of(context).pop();

        // Set active workspace
        ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Migration completed successfully!')),
        );

        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // User skipped migration, go to workspace selection
        Navigator.of(context).pushReplacementNamed('/workspace-selection');
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Migration Failed'),
          content: Text('Failed to migrate data: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/workspace-selection');
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
