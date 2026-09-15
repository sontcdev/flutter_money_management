# Money Wise

Money Wise is a Flutter personal finance app with offline-first local storage, budgeting, transaction tracking, reporting, and an in-progress Supabase-backed multi-workspace sync model.

## Highlights

- Track income and expenses with categories, notes, and receipt attachments.
- Manage budgets with monthly, yearly, and custom periods.
- Review reports through dashboard, summaries, and calendar-based views.
- Support localized UI with `vi`, `en`, and `ja` resources.
- Run primarily from local Drift-backed state, with cloud auth and workspace sync support layered on top.

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
- Drift for local persistence
- Freezed + JSON Serializable for models
- Supabase for auth and workspace/cloud sync flows
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
- Drift schema, tables, or DAOs

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

The repo contains an offline-first sync design where local data is the primary source for UI reads, and cloud state is hydrated into the local DB.

Key expectations:

- Supabase auth and workspace state are feature-scoped under auth/workspace modules.
- Cloud data must be hydrated into the local database to appear in the app.
- Sync-related work should verify both local-to-remote and remote-to-local paths.
- `activeWorkspaceIdProvider` is required for workspace-aware sync behavior.

Known repository-specific details:

- Local schema version is `6` in `lib/src/data/local/app_database.dart`.
- `categories`, `transactions`, and `budgets` include nullable `workspace_id` in the local schema.
- Drift date handling must remain compatible with integer-backed storage because of `build.yaml` settings.

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
- cloud sync uses UUID-based entities and soft-delete-friendly design

The broader roadmap includes:

- auth guard routing
- stronger workspace switching
- migration from legacy local-only data
- more complete sync queue processing and conflict handling

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
