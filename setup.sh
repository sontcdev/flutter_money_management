#!/bin/bash
# path: setup.sh

# Flutter Money Management App Setup Script

set -e

echo "🚀 Setting up Flutter Money Management App..."
echo ""

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter SDK 3.32.7"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
rm -rf .dart_tool/build

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate localizations
echo "🌐 Generating localizations..."
flutter gen-l10n

# Generate code with build_runner
echo "⚙️  Generating code (this may take a few minutes)..."
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze --no-fatal-infos --no-fatal-warnings

# Run tests
echo "🧪 Running tests..."
flutter test

echo ""
echo "✅ Setup complete! You can now run:"
echo "   flutter run"
echo ""
echo "📱 Available run configurations:"
echo "   - flutter run                  # Run on connected device"
echo "   - flutter run -d chrome        # Run on Chrome browser"
echo "   - flutter run -d macos         # Run on macOS"
echo ""
echo "🧪 Testing commands:"
echo "   - flutter test                 # Run all tests"
echo "   - flutter test --coverage      # Run tests with coverage"
echo ""
echo "🔨 Build commands:"
echo "   - flutter build apk            # Build Android APK"
echo "   - flutter build ios            # Build iOS (requires macOS)"
echo "   - flutter build web            # Build web app"
echo ""

