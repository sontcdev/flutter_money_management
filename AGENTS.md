# AGENTS.md

High-signal guidance for working in `flutter_money_management`.

## Core Commands

- Install deps: `flutter pub get`
- Generate localizations: `flutter gen-l10n`
- Generate code after changing models, Drift schema, or DAOs: `dart run build_runner build --delete-conflicting-outputs`
- Verify in the same order as CI:
  1. `flutter pub get`
  2. `flutter gen-l10n`
  3. `dart run build_runner build --delete-conflicting-outputs`
  4. `flutter analyze`
  5. `flutter test --coverage`
  6. `flutter build apk --release`

## Generated Code

- Do not edit generated files: `*.g.dart`, `*.freezed.dart`.
- Codegen is required after edits to:
  - `lib/src/models/*.dart`
  - `lib/src/data/local/app_database.dart`
  - `lib/src/data/local/tables/*.dart`
  - `lib/src/data/local/daos/*.dart`
- Localization config lives in `lib/src/i18n/l10n.yaml`, but ARB files are in `lib/l10n/`.

## Architecture Notes

- App entrypoint: `lib/main.dart` -> `lib/src/app_bootstrap.dart` -> `lib/src/app.dart`.
- App-level resume sync is wired through `lib/src/ui/widgets/app_lifecycle_sync_coordinator.dart`.
- UI reads app data from local Drift providers in `lib/src/providers/providers.dart`; cloud data must be hydrated into local DB to appear in the app.
- Supabase auth/workspace state lives in:
  - `lib/src/providers/auth_providers.dart`
  - `lib/src/providers/workspace_providers.dart`
- Shared sync helper for remote -> local refresh: `lib/src/services/workspace_sync_helper.dart`.

## Drift / Data Gotchas

- `build.yaml` sets `store_date_time_values_as_text: false`; keep Drift date handling compatible with integer-backed storage.
- Current local DB schema version is `6` in `lib/src/data/local/app_database.dart`.
- If you change Drift schema, update `schemaVersion` and `onUpgrade` together.
- Local tables for `categories`, `transactions`, and `budgets` now include nullable `workspace_id`; preserve that when changing repositories or sync code.

## Supabase / Sync Gotchas

- The app is offline-first: create/update/delete usually hits local DB first, then syncs to Supabase.
- For sync-related work, verify both directions:
  - local -> remote in `lib/src/data/repositories/*_repository.dart` and `lib/src/services/sync/supabase_sync_service.dart`
  - remote -> local in `lib/src/services/cloud_to_local_sync_service.dart`
- Supabase hydration and push logic depend on `activeWorkspaceIdProvider`; if that is null, sync will fail or no-op.
- Pull-to-refresh on data screens is expected to call shared workspace sync, not just invalidate providers.

## Tests and Focused Verification

- Run one test file: `flutter test test/budget_service_test.dart`
- Use `AppDatabase.withQueryExecutor(...)` for in-memory DB tests.
- If you touch reports/calendar refresh logic, also verify `lib/src/providers/report_providers.dart` because it has its own invalidation flow.

## iOS Build

- Manual builds:
  - Device: `flutter build ios --release --no-codesign`
  - Simulator: `flutter build ios --debug --simulator`

## Known Repo-Specific Mismatches To Watch

- `README.md` and current code/config do not fully match on package versions; trust `pubspec.yaml` and CI workflows over prose.
- If docs conflict with code around sync behavior or schema, trust `app_database.dart`, repository code, and CI commands.
