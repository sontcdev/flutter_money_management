// path: lib/src/providers/migration_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/local_to_cloud_migration_service.dart';
import 'auth_providers.dart';
import 'providers.dart';

/// Provider for migration service
final migrationServiceProvider = Provider<LocalToCloudMigrationService>((ref) {
  final localDb = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return LocalToCloudMigrationService(
    localDb: localDb,
    supabase: supabase,
    prefs: prefs,
  );
});

/// Provider to check if migration is needed
/// Only returns true when user has a valid authenticated session (email confirmed)
/// and hasn't completed migration yet
final needsMigrationProvider = Provider<bool>((ref) {
  final migrationService = ref.watch(migrationServiceProvider);
  final hasValidSession = ref.watch(hasValidSessionProvider);

  // Only need migration if user has valid session and hasn't migrated yet
  // This prevents migration prompt during sign-up-but-not-confirmed flow
  return hasValidSession && !migrationService.isMigrationComplete();
});

/// Provider to perform migration
final performMigrationProvider = FutureProvider.family<String, String>(
  (ref, workspaceName) async {
    final migrationService = ref.watch(migrationServiceProvider);
    final session = ref.watch(currentSessionProvider);

    if (session == null) {
      throw Exception('User must be authenticated to perform migration');
    }

    return await migrationService.migrateToCloud(
      userId: session.user.id,
      workspaceName: workspaceName,
    );
  },
);
