#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_PATH="$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab"

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

echo "MyMoney Play Store AAB build"
echo "Project root: $ROOT_DIR"
echo ""

run_step "Install dependencies" flutter pub get
run_step "Generate localizations" flutter gen-l10n
run_step "Generate code" dart run build_runner build --delete-conflicting-outputs
run_step "Analyze project" flutter analyze
run_step "Run tests" flutter test --coverage
run_step "Build Android App Bundle" flutter build appbundle --release

if [[ ! -f "$OUTPUT_PATH" ]]; then
  echo "AAB output not found: $OUTPUT_PATH" >&2
  exit 1
fi

echo "Build completed successfully."
echo "AAB: $OUTPUT_PATH"
