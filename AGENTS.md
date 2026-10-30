# Repository Guidelines

## Project Structure & Module Organization
- `lib/main.dart` starts the app; `lib/src/app_bootstrap.dart`, `app.dart`, and `app_router.dart` handle initialization and navigation.
- Organize features under `lib/src/features/`, following nearby `models/`, `providers/`, `services/`, `repositories/`, and `presentation/` boundaries. State management uses Riverpod and Flutter Hooks.
- Shared providers live in `lib/src/shared/`; reusable styling lives in `lib/src/theme/`.
- Tests live in `test/`, with visual baselines in `test/goldens/`. Icons are in `assets/icon/`, import examples in `templates/`, and localization ARB files in `lib/l10n/`.
- Platform projects are in `android/` and `ios/`; release helpers are in `scripts/`.

## Build, Test, and Development Commands
Use Flutter 3.41.7 to match `.github/workflows/ci.yml`; Android release builds require JDK 17. See `README.md` for platform setup.

| Command | Purpose |
| --- | --- |
| `flutter pub get` | Resolve dependencies using `pubspec.lock`. |
| `flutter gen-l10n` | Regenerate localization output. |
| `dart run build_runner build --delete-conflicting-outputs` | Regenerate model serialization and Freezed code. |
| `flutter run` | Launch on a connected device or emulator. |
| `dart format lib test` | Format Dart sources and tests. |
| `flutter analyze` | Run static analysis and configured Flutter lints. |
| `flutter test test/budget_status_test.dart` | Run a focused test file. |
| `flutter test --coverage` | Run the suite and collect coverage. |
| `flutter build apk --release` | Build the Android release APK used by CI. |

## Coding Style & Naming Conventions
- Use Dart formatting with two-space indentation, `snake_case.dart` filenames, `UpperCamelCase` types, and `lowerCamelCase` members.
- Follow `analysis_options.yaml` and adjacent feature patterns.
- Regenerate `*.g.dart`, `*.freezed.dart`, and localization output instead of editing generated files. Keep English, Vietnamese, and Japanese ARB resources aligned.

## Testing Guidelines
- Use `flutter_test` for unit/widget tests and `mocktail` where mocks are needed. Name files `*_test.dart` and describe observable behavior in test names.
- Add regression coverage for behavior changes; use provider overrides to isolate widget dependencies.
- Review golden image changes deliberately. CI collects coverage but defines no numeric minimum.

## Commit & Pull Request Guidelines
- Follow history: `feat(transactions): ...`, `fix(android): ...`, `refactor(ui): ...`, or `test(ui): ...`.
- Include a concise change description, linked issues when applicable, and validation results. Include screenshots for visible UI changes.
- Keep signing credentials, keystores, and private configuration out of commits; consult `scripts/BUILD_GUIDE.md` for release procedures.
