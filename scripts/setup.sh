#!/bin/bash

set -euo pipefail

echo "==> Money Wise setup"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not in PATH." >&2
  exit 1
fi

flutter clean
rm -rf .dart_tool/build

flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test

echo ""
echo "Setup complete."
