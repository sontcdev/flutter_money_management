#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_PATH="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
PACKAGE_NAME="com.sontc.financeappv1"

cd "$ROOT_DIR"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required tool not found: $1" >&2
    exit 1
  fi
}

run_step() {
  local label="$1"
  shift
  echo "==> $label"
  "$@"
  echo ""
}

require_tool flutter
require_tool dart

install_device_tools() {
  if command -v adb >/dev/null 2>&1; then
    return 0
  fi

  echo "ADB not found; skipping device uninstall/install step."
  return 1
}

reinstall_apk() {
  local device_id
  device_id="$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"

  if [[ -z "$device_id" ]]; then
    echo "No connected Android device/emulator found; skipping reinstall step."
    return 0
  fi

  echo "==> Reinstall on device: $device_id"
  adb -s "$device_id" uninstall "$PACKAGE_NAME" || true
  adb -s "$device_id" install -r "$OUTPUT_PATH"
  echo ""
}

echo "MyMoney Android release APK build"
echo "Project root: $ROOT_DIR"
echo ""

run_step "Install dependencies" flutter pub get
run_step "Generate localizations" flutter gen-l10n
run_step "Generate code" dart run build_runner build --delete-conflicting-outputs
run_step "Analyze project" flutter analyze
run_step "Run tests" flutter test --coverage
run_step "Build release APK" flutter build apk --release --dart-define=ENABLE_RELEASE_NETWORK_LOGGING=true

if [[ ! -f "$OUTPUT_PATH" ]]; then
  echo "APK output not found: $OUTPUT_PATH" >&2
  exit 1
fi

echo "Build completed successfully."
echo "APK: $OUTPUT_PATH"

if install_device_tools; then
  reinstall_apk
fi
