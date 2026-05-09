#!/bin/bash

set -euo pipefail

if [[ "$OSTYPE" != darwin* ]]; then
  echo "This script is intended for macOS only." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not in PATH." >&2
  exit 1
fi

echo "==> iOS build helper"
flutter devices
echo ""
echo "1. Build debug for simulator"
echo "2. Build release for device"
echo "3. Run on a selected device"
read -r -p "Choose [1-3]: " CHOICE

flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

case "$CHOICE" in
  1)
    flutter build ios --debug --simulator
    ;;
  2)
    flutter build ios --release --no-codesign
    echo "Release build completed. Use Xcode for signing and installation."
    ;;
  3)
    read -r -p "Device id: " DEVICE_ID
    if [[ -z "$DEVICE_ID" ]]; then
      echo "Device id is required." >&2
      exit 1
    fi
    flutter run -d "$DEVICE_ID"
    ;;
  *)
    echo "Invalid choice." >&2
    exit 1
    ;;
esac
