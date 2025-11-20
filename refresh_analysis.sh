#!/bin/bash
# Script to refresh Dart analysis and rebuild generated files

echo "🔄 Refreshing Dart analysis and rebuilding generated files..."

# Step 1: Clean build artifacts
echo "1️⃣ Cleaning build artifacts..."
flutter clean

# Step 2: Get dependencies
echo "2️⃣ Getting dependencies..."
flutter pub get

# Step 3: Rebuild generated files
echo "3️⃣ Rebuilding generated files..."
flutter pub run build_runner build --delete-conflicting-outputs

# Step 4: Run analysis
echo "4️⃣ Running Flutter analyze..."
flutter analyze

echo "✅ Done! If your IDE still shows errors, please restart it."
echo ""
echo "For VS Code: Press Cmd+Shift+P and run 'Dart: Restart Analysis Server'"
echo "For IntelliJ/Android Studio: File > Invalidate Caches and Restart"

