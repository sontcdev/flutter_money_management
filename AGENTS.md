# AGENTS.md

High-signal guidance for working in `flutter_money_management`.

## Core Commands

- Install deps: `flutter pub get`
- Generate localizations: `flutter gen-l10n`
- Generate code after changing freezed/JSON models: `dart run build_runner build --delete-conflicting-outputs`
- Verify in the same order as CI (`.github/workflows/ci.yml`, pinned to Flutter `3.32.7`):
  1. `flutter pub get`
  2. `flutter gen-l10n`
  3. `dart run build_runner build --delete-conflicting-outputs`
  4. `flutter analyze`
  5. `flutter test --coverage`
  6. `flutter build apk --release`

## Generated Code

- Do not edit generated files: `*.g.dart`, `*.freezed.dart`.
- Codegen applies repo-wide to any file with freezed/json_serializable `part` directives, not just `lib/src/models/`. Most models now live per-feature: `lib/src/features/*/models/*.dart` (e.g. `budgets/models/budget.dart`, `transactions/models/transaction.dart`, `workspace/models/workspace.dart`, `recurring/models/*.dart`, `notifications/models/user_notification.dart`, `categories/models/category.dart`).
- Localization config lives in `lib/src/i18n/l10n.yaml`, but ARB files are in `lib/l10n/`.
- `build.yaml` still has a leftover `drift_dev` builder block (`store_date_time_values_as_text: false`); this is vestigial — there is no Drift dependency or database in the project anymore.

## Architecture Notes

- **No local database.** Drift/local DB was fully removed (see commit `2a44951`). The app reads and writes directly to Supabase, scoped by `workspace_id`. `lib/src/data/local/tables/` and `lib/src/data/local/daos/` are empty leftover directories.
- App entrypoint: `lib/main.dart` -> `lib/src/app_bootstrap.dart` -> `lib/src/app.dart`. Routing lives in `lib/src/app_router.dart`.
- App-level resume sync is wired through `lib/src/ui/widgets/app_lifecycle_sync_coordinator.dart`.
- Feature-first layout under `lib/src/features/` (auth, budgets, categories, home, notifications, recurring, reports, settings, transactions, workspace), each typically with `models/`, `presentation/screens|widgets/`, `providers/`, `repositories/`, `services/`.
- `lib/src/providers/providers.dart` is now just a compatibility barrel re-exporting from `shared/providers/app_service_providers.dart`, `shared/providers/preferences_provider.dart`, and per-feature provider files.
- Auth/workspace state lives in:
  - `lib/src/features/auth/providers/auth_providers.dart`
  - `lib/src/features/workspace/providers/workspace_providers.dart` (`activeWorkspaceIdProvider` is a `StateProvider<String?>`)
- Shared sync helper: `lib/src/features/workspace/services/workspace_sync_helper.dart`. `syncCurrentWorkspaceData()` resolves the active workspace and calls `invalidateCoreDataProviders(ref)`, which invalidates `categoriesProvider`, `transactionsProvider`, `budgetsProvider`, `budgetsWithConsumedProvider`, `recurringTransactionsProvider`, `upcomingRecurringOccurrencesProvider` — these refetch straight from Supabase.
- Reports providers: `lib/src/features/reports/providers/report_providers.dart`.
- Centralized Supabase error handling: `lib/src/data/repositories/supabase_error_mapper.dart` (`mapSupabaseException`), plus user-facing error reporting via `lib/src/models/error_report.dart`, `lib/src/services/error_report_service.dart`, `lib/src/ui/widgets/error_report_dialog.dart`.
- Notable features added recently:
  - Notifications: `lib/src/features/notifications/` backed by the Supabase `user_notifications` table, using `flutter_local_notifications` + `timezone`.
  - Recurring transactions: `lib/src/features/recurring/` (`recurring_transaction_repository.dart`, `recurring_schedule_calculator.dart`, `recurring_reminder_service.dart`), backed by `recurring_transactions` and `recurring_transaction_occurrences` tables; this feature has the most test coverage.
  - Workspace management: `lib/src/features/workspace/services/workspace_management_service.dart`, `providers/workspace_management_providers.dart`, tabbed workspace detail UI with activity log and a "leave workspace" danger zone.

## Data / Schema Gotchas

- Schema now lives purely in Supabase Postgres, not in a Dart file. Source of truth: `supabase/00_reset_database.sql` and `supabase/01_create_schema.sql`.
- `workspace_id` is `not null` (not nullable) on `categories`, `transactions`, `budgets`, `transaction_attachments`, `activity_logs`, `recurring_transactions`, `recurring_transaction_occurrences`, `user_workspace_preferences`, `workspace_members`. All CRUD is workspace-scoped via `.eq('workspace_id', workspaceId)` in Supabase-backed repositories.
- Usernames (`display_name`) are enforced unique case-insensitively: `unique index profiles_display_name_unique_idx on public.profiles(lower(display_name))`, checked at sign-up via the `check_signup_uniqueness(p_email, p_display_name)` RPC in `supabase_auth_service.dart`.

## Supabase / Sync Gotchas

- The app is **not offline-first**: repositories under `lib/src/features/*/repositories/*_repository.dart` query Supabase directly, there is no local cache to hydrate.
- Repositories require a non-null `activeWorkspaceIdProvider` value to build queries (`_requireWorkspaceId` pattern); if it's null, calls fail.
- Pull-to-refresh on data screens calls `syncCurrentWorkspaceData()` / `invalidateCoreDataProviders`, not just a bare provider invalidate.

## Tests and Focused Verification

- Current test files live in `test/`: `category_color_codec_test.dart`, `recurring_reminder_service_test.dart`, `recurring_schedule_calculator_test.dart`, `recurring_transaction_edit_screen_test.dart`, `recurring_transaction_service_test.dart`, `recurring_transactions_screen_test.dart`, `report_calendar_widget_test.dart`.
- Run one test file: `flutter test test/recurring_transaction_service_test.dart`
- If you touch reports/calendar refresh logic, also verify `lib/src/features/reports/providers/report_providers.dart` because it has its own invalidation flow.

## iOS Build

- Manual builds:
  - Device: `flutter build ios --release --no-codesign`
  - Simulator: `flutter build ios --debug --simulator`

## Known Repo-Specific Mismatches To Watch

- `README.md` is significantly out of date: it still describes "offline-first local storage," a "Drift-backed" local state, and `lib/src/data/local/` paths, none of which reflect the current Supabase-direct architecture. Trust the code over the README.
- `pubspec.yaml` and CI workflows have no `drift`/`sqflite` dependency; trust them over any doc still mentioning Drift.
- If docs conflict with code around sync behavior or schema, trust the Supabase SQL files in `supabase/`, repository code under `lib/src/features/*/repositories/`, and CI commands.
