#!/bin/bash

# Define package name
PACKAGE_NAME="com.sontc.financeappv1"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo "🚀 Starting build process..."

# 1. Build Release APK
echo "📦 Building Flutter APK (Release)..."
flutter build apk --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# 2. Uninstall Old App
echo "🗑️  Uninstalling old version ($PACKAGE_NAME)..."
adb uninstall $PACKAGE_NAME

# 3. Install New App
echo "📲 Installing new version..."
adb install $APK_PATH

if [ $? -ne 0 ]; then
    echo "❌ Installation failed! key Check if device is connected."
    exit 1
fi

echo "✨ Done! App installed and ready."
