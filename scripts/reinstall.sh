#!/bin/bash

set -euo pipefail

PACKAGE_NAME="${PACKAGE_NAME:-com.sontc.financeappv1}"
APK_PATH="${APK_PATH:-build/app/outputs/flutter-apk/app-release.apk}"
DEVICE_ID="${1:-}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required tool not found: $1" >&2
    exit 1
  fi
}

require_tool flutter
require_tool adb

flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found at $APK_PATH" >&2
  exit 1
fi

ADB_ARGS=()
if [[ -n "$DEVICE_ID" ]]; then
  ADB_ARGS=(-s "$DEVICE_ID")
fi

adb "${ADB_ARGS[@]}" uninstall "$PACKAGE_NAME" >/dev/null 2>&1 || true
adb "${ADB_ARGS[@]}" install -r "$APK_PATH"

echo "Android release reinstalled successfully."
