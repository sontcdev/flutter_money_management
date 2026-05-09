#!/bin/bash

echo "========================================"
echo "  MyMoney - Build AAB Release Script"
echo "========================================"
echo ""

# Exit on error
set -e

# Step 1: Increment version
echo "[1/7] Incrementing version..."
bash scripts/increment_version.sh
echo ""

# Step 2: Flutter pub get
echo "[2/7] Running flutter pub get..."
flutter pub get
echo ""

# Step 3: Generate localizations
echo "[3/7] Generating localizations..."
flutter gen-l10n
echo ""

# Step 4: Build runner
echo "[4/7] Running build_runner..."
dart run build_runner build --delete-conflicting-outputs
echo ""

# Step 5: Analyze code
echo "[5/7] Analyzing code..."
flutter analyze || echo "WARNING: Code analysis found issues. Continuing with build..."
echo ""

# Step 6: Build AAB
echo "[6/7] Building AAB (release)..."
flutter build appbundle --release
echo ""

# Step 7: Show results
echo "[7/7] Build completed successfully!"
echo ""
echo "========================================"
echo "  BUILD SUMMARY"
echo "========================================"

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo "Version: $VERSION"

# Get file size
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    SIZE=$(stat -f%z "$AAB_PATH" 2>/dev/null || stat -c%s "$AAB_PATH" 2>/dev/null)
    SIZE_MB=$((SIZE / 1048576))
    echo "File size: ${SIZE_MB} MB"
    echo ""
    echo "Output file:"
    echo "$(pwd)/$AAB_PATH"
    echo ""
    echo "Ready to upload to Google Play Console!"
else
    echo "ERROR: AAB file not found at expected location"
    exit 1
fi

echo "========================================"
