#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_PATH="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"

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

echo "MyMoney Android release APK build"
echo "Project root: $ROOT_DIR"
echo ""

run_step "Install dependencies" flutter pub get
run_step "Generate localizations" flutter gen-l10n
run_step "Generate code" dart run build_runner build --delete-conflicting-outputs
run_step "Analyze project" flutter analyze
run_step "Run tests" flutter test --coverage
run_step "Build release APK" flutter build apk --release

if [[ ! -f "$OUTPUT_PATH" ]]; then
  echo "APK output not found: $OUTPUT_PATH" >&2
  exit 1
fi

echo "Build completed successfully."
echo "APK: $OUTPUT_PATH"
