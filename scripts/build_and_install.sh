#!/bin/bash

set -euo pipefail

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required tool not found: $1" >&2
    exit 1
  fi
}

run_prepare() {
  flutter pub get
  flutter gen-l10n
  dart run build_runner build --delete-conflicting-outputs
}

require_tool flutter

echo "==> Interactive build and install"
flutter devices
echo ""

read -r -p "Build mode [debug/profile/release] (default: debug): " MODE
MODE=${MODE:-debug}

case "$MODE" in
  debug|profile|release) ;;
  *)
    echo "Invalid mode: $MODE" >&2
    exit 1
    ;;
esac

read -r -p "Platform [android/ios] (default: android): " PLATFORM
PLATFORM=${PLATFORM:-android}

case "$PLATFORM" in
  android|ios) ;;
  *)
    echo "Invalid platform: $PLATFORM" >&2
    exit 1
    ;;
esac

read -r -p "Clean first? [y/N]: " CLEAN
if [[ "$CLEAN" =~ ^[Yy]$ ]]; then
  flutter clean
  rm -rf .dart_tool/build
fi

run_prepare
flutter analyze

read -r -p "Device id (leave empty for auto-detect): " DEVICE_ID

if [[ "$PLATFORM" == "android" ]]; then
  if [[ "$MODE" == "release" ]]; then
    flutter build apk --release
    if [[ -n "$DEVICE_ID" ]]; then
      flutter install --release -d "$DEVICE_ID"
    else
      flutter install --release
    fi
  else
    if [[ -n "$DEVICE_ID" ]]; then
      flutter run --"$MODE" -d "$DEVICE_ID"
    else
      flutter run --"$MODE"
    fi
  fi
  exit 0
fi

if [[ "$MODE" == "release" ]]; then
  flutter build ios --release --no-codesign
  echo "iOS release build completed. Sign and install from Xcode as needed."
  exit 0
fi

if [[ -n "$DEVICE_ID" ]]; then
  flutter run --"$MODE" -d "$DEVICE_ID"
else
  flutter run --"$MODE"
fi
