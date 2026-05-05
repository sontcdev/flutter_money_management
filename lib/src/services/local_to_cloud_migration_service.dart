// path: lib/src/services/local_to_cloud_migration_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/app_database.dart';

/// Service to migrate local v4 data to Supabase cloud
/// This is used for Option A: Phased Approach
class LocalToCloudMigrationService {
  final AppDatabase _localDb;
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  static const String _migrationCompleteKey = 'migration_to_cloud_complete';
  static const String _migrationWorkspaceIdKey = 'migration_workspace_id';

  LocalToCloudMigrationService({
    required AppDatabase localDb,
    required SupabaseClient supabase,
    required SharedPreferences prefs,
  })  : _localDb = localDb,
        _supabase = supabase,
        _prefs = prefs;

  /// Check if migration has already been completed
  bool isMigrationComplete() {
    return _prefs.getBool(_migrationCompleteKey) ?? false;
  }

  /// Get the workspace ID that was created during migration
  String? getMigrationWorkspaceId() {
    return _prefs.getString(_migrationWorkspaceIdKey);
  }

  /// Perform full migration from local v4 to Supabase
  /// Returns the workspace ID created for the user
  Future<String> migrateToCloud({
    required String userId,
    String workspaceName = 'My Workspace',
  }) async {
    if (isMigrationComplete()) {
      final workspaceId = getMigrationWorkspaceId();
      if (workspaceId != null) {
        return workspaceId;
      }
    }

    try {
      // Step 1: Create default workspace for user
      final workspaceId = await _createDefaultWorkspace(
        userId: userId,
        workspaceName: workspaceName,
      );

      // Step 2: Migrate categories
      final categoryIdMap = await _migrateCategories(
        workspaceId: workspaceId,
        userId: userId,
      );

      // Step 3: Migrate transactions
      await _migrateTransactions(
        workspaceId: workspaceId,
        userId: userId,
        categoryIdMap: categoryIdMap,
      );

      // Step 4: Migrate budgets
      await _migrateBudgets(
        workspaceId: workspaceId,
        userId: userId,
        categoryIdMap: categoryIdMap,
      );

      // Mark migration as complete
      await _prefs.setBool(_migrationCompleteKey, true);
      await _prefs.setString(_migrationWorkspaceIdKey, workspaceId);

      return workspaceId;
    } catch (e) {
      throw Exception('Migration failed: $e');
    }
  }

  /// Create default workspace for user
  Future<String> _createDefaultWorkspace({
    required String userId,
    required String workspaceName,
  }) async {
    // Debug: Check if we have an active session
    final session = _supabase.auth.currentSession;
    print('Migration: Creating workspace for user: $userId');
    print('Migration: Current session user: ${session?.user.id}');
    print('Migration: Session valid: ${session != null}');
    
    if (session == null) {
      throw Exception('No active session found. Please sign in again.');
    }
    
    if (session.user.id != userId) {
      throw Exception('Session user ID mismatch. Expected: $userId, Got: ${session.user.id}');
    }
    
    final response = await _supabase.from('workspaces').insert({
      'name': workspaceName,
      'type': 'personal',
      'owner_user_id': userId,
    }).select('id').single();

    return response['id'] as String;
  }

  /// Migrate categories from local to cloud
  /// Returns a map of old local ID -> new cloud UUID
  Future<Map<int, String>> _migrateCategories({
    required String workspaceId,
    required String userId,
  }) async {
    final categoryDao = _localDb.categoryDao;
    final localCategories = await categoryDao.getAllCategories();

    final categoryIdMap = <int, String>{};

    for (final category in localCategories) {
      try {
        final response = await _supabase.from('categories').insert({
          'workspace_id': workspaceId,
          'name': category.name,
          'icon': category.iconName,
          'color': category.colorValue.toString(),
          'type': category.type,
          'created_by': userId,
        }).select('id').single();

        final cloudId = response['id'] as String;
        categoryIdMap[category.id] = cloudId;
      } catch (e) {
        // Log error but continue with other categories
        print('Failed to migrate category ${category.id}: $e');
      }
    }

    return categoryIdMap;
  }

  /// Migrate transactions from local to cloud
  Future<void> _migrateTransactions({
    required String workspaceId,
    required String userId,
    required Map<int, String> categoryIdMap,
  }) async {
    final transactionDao = _localDb.transactionDao;
    final localTransactions = await transactionDao.getAllTransactions();

    for (final transaction in localTransactions) {
      try {
        // Map local category ID to cloud UUID
        final cloudCategoryId = categoryIdMap[transaction.categoryId];
        if (cloudCategoryId == null) {
          print('Skipping transaction ${transaction.id}: category not found');
          continue;
        }

        await _supabase.from('transactions').insert({
          'workspace_id': workspaceId,
          'amount_cents': transaction.amountCents,
          'currency': transaction.currency,
          'transaction_date': transaction.transactionDate.toIso8601String(),
          'category_id': cloudCategoryId,
          'type': transaction.type,
          'note': transaction.note,
          'created_by': userId,
        });
      } catch (e) {
        // Log error but continue with other transactions
        print('Failed to migrate transaction ${transaction.id}: $e');
      }
    }
  }

  /// Migrate budgets from local to cloud
  Future<void> _migrateBudgets({
    required String workspaceId,
    required String userId,
    required Map<int, String> categoryIdMap,
  }) async {
    final budgetDao = _localDb.budgetDao;
    final localBudgets = await budgetDao.getAllBudgets();

    for (final budget in localBudgets) {
      try {
        // Map local category ID to cloud UUID
        final cloudCategoryId = categoryIdMap[budget.categoryId];
        if (cloudCategoryId == null) {
          print('Skipping budget ${budget.id}: category not found');
          continue;
        }

        await _supabase.from('budgets').insert({
          'workspace_id': workspaceId,
          'category_id': cloudCategoryId,
          'amount_cents': budget.limitCents,
          'currency': 'VND', // Default currency, adjust as needed
          'period_start': budget.periodStart.toIso8601String(),
          'period_end': budget.periodEnd.toIso8601String(),
          'created_by': userId,
        });
      } catch (e) {
        // Log error but continue with other budgets
        print('Failed to migrate budget ${budget.id}: $e');
      }
    }
  }

  /// Reset migration state (for testing or re-migration)
  Future<void> resetMigrationState() async {
    await _prefs.remove(_migrationCompleteKey);
    await _prefs.remove(_migrationWorkspaceIdKey);
  }
}
