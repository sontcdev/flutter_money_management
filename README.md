# Money Wise

Money Wise is a Flutter personal finance app with budgeting, transaction tracking, reporting, and Supabase-backed cloud storage with multi-workspace support. An internet connection is required to read and write financial data; the app has no offline mode.

## Highlights

- Track income and expenses with categories, notes, and receipt attachments.
- Manage budgets with monthly, yearly, and custom periods.
- Review reports through dashboard, summaries, and calendar-based views.
- Support localized UI with `vi`, `en`, and `ja` resources.
- Store financial data directly in Supabase, scoped by workspace. There is no local financial database and no durable offline write queue.
- Data is refreshed from Supabase on app startup, on app resume, and on pull-to-refresh.

## Architecture

The app now follows a feature-first layout under `lib/src/features/`.

Important entrypoints:

- `lib/main.dart`
- `lib/src/app_bootstrap.dart`
- `lib/src/app.dart`
- `lib/src/app_router.dart`

Primary feature modules:

- `lib/src/features/auth/`
- `lib/src/features/workspace/`
- `lib/src/features/settings/`
- `lib/src/features/reports/`
- `lib/src/features/categories/`
- `lib/src/features/transactions/`
- `lib/src/features/budgets/`
- `lib/src/features/home/`

Shared and app-level code:

- `lib/src/app/`
- `lib/src/shared/`
- `lib/src/providers/providers.dart` as a compatibility barrel for moved providers

## Tech Stack

- Flutter
- Riverpod + Flutter Hooks
- Freezed + JSON Serializable for models
- Supabase for auth, workspace management, and cloud storage of financial data
- Shared Preferences for local settings

## Setup

### Requirements

- Flutter SDK 3.41.7 (with its bundled Dart SDK)
- Dart SDK included with Flutter
- Android Studio or VS Code with Flutter tooling
- Xcode on macOS for iOS builds
- JDK 17 for Android release builds

On macOS, configure Flutter to use JDK 17 and verify the toolchain before an
Android release build:

```bash
flutter config --jdk-dir="$(/usr/libexec/java_home -v 17)"
flutter doctor -v
```

If `java_home` is unavailable, pass the local JDK 17 installation directly:

```bash
flutter config --jdk-dir="/path/to/jdk-17"
```

### Initial bootstrap

Run the same core sequence used by the repo guidance:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage
```

If you want an opinionated helper script instead, use one of the scripts under `scripts/` after they are moved there.

## Daily Development

Typical commands:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Focused test example:

```bash
flutter test test/budget_service_test.dart
```

## Generated Code Rules

Do not manually edit generated files such as:

- `*.g.dart`
- `*.freezed.dart`

Run codegen after changing:

- feature models using Freezed or JSON serialization

Preferred command:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Verification Order

When validating larger changes, use this order:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage
flutter build apk --release
```

## Build Notes

### Android

Common commands:

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

For the Google Play release AAB, use JDK 17 and run the repository's full
release validation sequence:

```bash
flutter config --jdk-dir="$(/usr/libexec/java_home -v 17)"
flutter doctor -v
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage
flutter build appbundle --release
```

The upload artifact is generated at:

```text
build/app/outputs/bundle/release/app-release.aab
```

Release signing is configured locally through `android/key.properties` and a
keystore. Keep both files out of Git; `android/key.properties`, `*.jks`, and
`*.keystore` are ignored by this repository. A Play Store upload must use a
valid release keystore rather than the debug fallback.

### iOS

Common commands:

```bash
flutter build ios --debug --simulator
flutter build ios --release --no-codesign
```

## Scripts

Project helper scripts are organized under `scripts/`.

Available helpers:

- `scripts/build_play_store_aab.sh`
- `scripts/build_release_apk.sh`

Guidance:

- Use `build_play_store_aab.sh` to produce the signed release AAB for Google Play.
- Use `build_release_apk.sh` to produce the signed release APK.
- Configure JDK 17 and verify `flutter doctor -v` before running either Android
  release helper.

## Localization

ARB files live in `lib/l10n/`.

Generate localization output with:

```bash
flutter gen-l10n
```

Current localization audit status from the latest local report was clean with no findings.

## Import / Export

The app supports transaction import/export flows centered around CSV and JSON payloads.

Supported fields:

- `date`
- `type`
- `amount`
- `category`
- `note`

CSV header example:

```csv
date,type,amount,category,note
25/11/2024,expense,50000,Food,Breakfast
25/11/2024,income,15000000,Salary,November salary
```

JSON shape example:

```json
{
  "exportDate": "2024-11-25T10:00:00.000",
  "version": "1.0",
  "transactions": [
    {
      "date": "25/11/2024",
      "type": "expense",
      "amount": 50000,
      "category": "Food",
      "note": "Breakfast"
    }
  ]
}
```

Template assets remain under `templates/`.

## Sync and Workspace Notes

The app is **not offline-first**. Repositories under
`lib/src/features/*/repositories/` read from and write to Supabase directly.

Key expectations:

- Supabase auth and workspace state are feature-scoped under auth/workspace modules.
- An internet connection is required. Reads and writes fail when the device is offline.
- There is no durable offline write queue and no automatic replay of pending writes after reconnect.
- "Sync" means refetching from Supabase: on app startup, on app resume, and on
  pull-to-refresh (`syncCurrentWorkspaceData()` invalidates the Riverpod providers).
- `activeWorkspaceIdProvider` is required; repositories fail without an active workspace.

Known repository-specific details:

- There is no local financial database. The former Drift layer was removed.
- `workspace_id` is `not null` on workspace-scoped tables (see `supabase/01_create_schema.sql`).

## Supabase Setup

Typical Supabase setup flow:

1. Create a Supabase project.
2. Apply migrations from `supabase/migrations/`.
3. Copy project URL and anon key into `lib/src/config/supabase_config.dart`.
4. Verify tables, auth triggers, and RLS policies.
5. Test sign-up, sign-in, workspace creation, and sync flows.

Security note:

- Do not commit real private environment credentials to a public repository.

## Multi-User Direction

The repository contains groundwork for a multi-user workspace model:

- each user has a personal workspace
- group workspaces are owner-managed
- business tables are workspace-scoped
- cloud data uses UUID-based entities and soft-delete-friendly design

Roadmap ideas (not implemented, do not describe them as features):

- stronger workspace switching
- optional offline support with a write queue and conflict handling

## Troubleshooting

Common recovery flow:

```bash
flutter clean
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

If Gradle reports an unsupported Java version or Flutter selects JDK 25+, point
Flutter back to JDK 17 and verify again:

```bash
flutter config --jdk-dir="$(/usr/libexec/java_home -v 17)"
flutter doctor -v
```

If the AAB is not release-signed, check that `android/key.properties` exists
locally, points to the intended keystore, and contains all required signing
properties. Do not commit that file or the keystore.

Useful checks:

```bash
flutter doctor -v
flutter devices
adb devices
```

## Repository Notes

- Trust `pubspec.yaml`, source code, and CI commands over stale prose.
- `AGENTS.md` remains in the repo as tooling guidance.
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` is intentionally kept in place.
