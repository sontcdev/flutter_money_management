# AGENTS.md

Agent guidance for `flutter_money_management` - a Flutter money management app using Drift, Riverpod, and Freezed.

## Tech Stack

**Framework:**
- Flutter 3.27+ / Dart 3.0+
- Material Design 3

**State Management:**
- Riverpod 2.4.9 (hooks_riverpod)
- Flutter Hooks 0.20.3

**Database:**
- Drift 2.14.1 (type-safe SQLite wrapper)
- sqlite3_flutter_libs 0.5.18

**Code Generation:**
- build_runner 2.4.7
- freezed 2.4.5 + freezed_annotation 2.4.1 (immutable models)
- json_serializable 6.7.1 + json_annotation 4.9.0
- drift_dev 2.14.1

**Localization:**
- flutter_localizations (SDK)
- intl 0.20.2

**UI/UX:**
- fl_chart 0.65.0 (charts)
- flutter_slidable 4.0.3
- image_picker 1.0.4
- file_picker 8.0.0

**Utilities:**
- path_provider 2.1.1
- shared_preferences 2.2.2
- package_info_plus 8.0.0
- share_plus 10.1.4
- flutter_local_notifications 18.0.1

**Testing:**
- flutter_test (SDK)
- mocktail 1.0.1

**Dev Tools:**
- flutter_lints 3.0.0
- flutter_launcher_icons 0.13.1

## Recommended Skills

Install agent skills to enhance development workflow. Use `npx skills add <owner/repo@skill>` to install.

**Flutter Core Skills** (Official Flutter skills):
- `flutter/skills@flutter-architecting-apps` (10.4K installs) - App architecture patterns
- `flutter/skills@flutter-managing-state` (9.6K installs) - State management best practices
- `flutter/skills@flutter-working-with-databases` (8.4K installs) - Database integration patterns
- `flutter/skills@flutter-building-layouts` (10.6K installs) - Layout design patterns
- `flutter/skills@flutter-theming-apps` (9.5K installs) - Theme and styling guidance

**Dart Skills**:
- `affaan-m/everything-claude-code@flutter-dart-code-review` (2.4K installs) - Code review patterns
- `affaan-m/everything-claude-code@dart-flutter-patterns` (1.6K installs) - Common patterns
- `dart-lang/skills@dart-add-unit-test` (225 installs) - Unit testing guidance
- `dart-lang/skills@dart-fix-static-analysis-errors` (229 installs) - Fix analyzer issues

**Mobile Development**:
- `sleekdotdesign/agent-skills@sleek-design-mobile-apps` (78.1K installs) - Mobile UI/UX design
- `wshobson/agents@mobile-ios-design` (14K installs) - iOS-specific design patterns
- `wshobson/agents@mobile-android-design` (13.4K installs) - Android-specific design patterns

**Database & State Management**:
- `flutter/skills@flutter-state-management` (1.1K installs) - Flutter state management
- `supercent-io/skills-template@database-schema-design` (12.1K installs) - Schema design patterns
- `wshobson/agents@database-migration` (10.8K installs) - Migration strategies

**Testing**:
- `supercent-io/skills-template@testing-strategies` (11.2K installs) - Testing best practices

Browse more at: https://skills.sh/

## Critical: Code Generation Required

**Always run code generation after modifying models, database tables, or DAOs:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or use watch mode during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

**Files that trigger codegen:**
- `lib/src/models/*.dart` (Freezed models with `@freezed` annotation)
- `lib/src/data/local/app_database.dart` (Drift database)
- `lib/src/data/local/tables/*.dart` (Drift tables)
- `lib/src/data/local/daos/*.dart` (Drift DAOs)

Generated files have `.g.dart` or `.freezed.dart` extensions. Never edit these directly.

## Command Sequence

**Setup (first time or after clean):**
```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

**Verification order:**
```bash
flutter analyze
flutter test
```

**Clean build (when things break):**
```bash
flutter clean
rm -rf .dart_tool/build
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

**Database layer (Drift):**
- `lib/src/data/local/app_database.dart` - Main database class, schema version 4
- `lib/src/data/local/tables/` - Table definitions
- `lib/src/data/local/daos/` - Data access objects
- Database uses `store_date_time_values_as_text: false` (see `build.yaml`)
- Test constructor available: `AppDatabase.withQueryExecutor(executor)`

**State management:**
- Riverpod 2.4.9 with Flutter Hooks
- Providers in `lib/src/providers/`

**Models:**
- Freezed models in `lib/src/models/`
- JSON serialization enabled via `build.yaml`

**Localization:**
- ARB files in `lib/l10n/` (not `lib/src/i18n/`)
- Config: `lib/src/i18n/l10n.yaml`
- Generate with: `flutter gen-l10n`
- Supported: Vietnamese (vi), English (en)

## Testing

**Run tests:**
```bash
flutter test                    # All tests
flutter test test/budget_service_test.dart  # Single test
flutter test --coverage         # With coverage
```

**Test files use:**
- `mocktail` for mocking
- In-memory database via `AppDatabase.withQueryExecutor()`

## iOS Build

**Quick build script (recommended):**
```bash
./ios_build_all.sh
```

Interactive menu builds release for physical devices and debug for simulators (simulator release builds not supported by Flutter).

**Manual build:**
```bash
flutter build ios --release --no-codesign  # Physical device
flutter build ios --debug --simulator      # Simulator only
```

## CI/CD

**CI workflow** (`.github/workflows/ci.yml`):
1. `flutter pub get`
2. `flutter gen-l10n`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter analyze`
5. `flutter test --coverage`
6. `flutter build apk --release`

Match this order locally to catch CI failures early.

## Common Gotchas

**Drift schema changes:**
- Increment `schemaVersion` in `app_database.dart` (currently 4)
- Add migration logic in `onUpgrade` if needed
- Drift doesn't support dropping columns directly - recreate table instead

**Build failures:**
- Missing `.g.dart` files → run build_runner
- Localization errors → run `flutter gen-l10n`
- Stale generated code → use `--delete-conflicting-outputs`

**Package info:**
- Bundle ID: `com.sontc.financeapp` (Android/iOS general)
- iOS specific: `com.sontc.financeappv1` (see `ios_build_all.sh:18`)
- App name: "Money Wise"
