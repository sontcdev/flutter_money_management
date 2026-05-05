#!/bin/bash
# Auto build and install Flutter app to connected device
# Works for both Android and iOS devices

set -e  # Exit on error

echo "=================================="
echo "Flutter Auto Build & Install"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check for connected devices
print_info "Checking for connected devices..."
DEVICES=$(flutter devices --machine | grep -o '"id"' | wc -l)

if [ "$DEVICES" -eq 0 ]; then
    print_error "No devices connected. Please connect a device or start an emulator/simulator."
    exit 1
fi

print_info "Found $DEVICES device(s)"
flutter devices

echo ""
read -p "Select build mode (1=Debug, 2=Profile, 3=Release) [1]: " BUILD_MODE
BUILD_MODE=${BUILD_MODE:-1}

case $BUILD_MODE in
    1)
        MODE="debug"
        print_info "Building in DEBUG mode"
        ;;
    2)
        MODE="profile"
        print_info "Building in PROFILE mode"
        ;;
    3)
        MODE="release"
        print_info "Building in RELEASE mode"
        ;;
    *)
        print_error "Invalid selection"
        exit 1
        ;;
esac

echo ""
read -p "Select target platform (1=Android, 2=iOS, 3=Auto-detect) [3]: " PLATFORM
PLATFORM=${PLATFORM:-3}

# Step 1: Clean previous builds (optional)
read -p "Clean previous builds? (y/N): " CLEAN
if [[ $CLEAN =~ ^[Yy]$ ]]; then
    print_info "Cleaning previous builds..."
    flutter clean
    rm -rf .dart_tool/build
fi

# Step 2: Get dependencies
print_info "Getting dependencies..."
flutter pub get

# Step 3: Generate localization
print_info "Generating localization files..."
flutter gen-l10n

# Step 4: Run code generation
print_info "Running code generation..."
dart run build_runner build --delete-conflicting-outputs

# Step 5: Analyze code
print_info "Analyzing code..."
if ! flutter analyze; then
    print_warning "Code analysis found issues. Continue anyway? (y/N): "
    read CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 6: Build and install based on platform
case $PLATFORM in
    1)
        # Android
        print_info "Building and installing for Android..."
        if [ "$MODE" = "release" ]; then
            flutter build apk --release
            print_info "Installing APK..."
            flutter install --release
        else
            flutter run --$MODE
        fi
        ;;
    2)
        # iOS
        print_info "Building and installing for iOS..."
        if [ "$MODE" = "release" ]; then
            flutter build ios --release --no-codesign
            print_warning "Release build completed. Please use Xcode to sign and install."
        else
            flutter run --$MODE
        fi
        ;;
    3)
        # Auto-detect
        print_info "Auto-detecting platform and installing..."
        if [ "$MODE" = "release" ]; then
            flutter build apk --release 2>/dev/null || flutter build ios --release --no-codesign
            flutter install --release
        else
            flutter run --$MODE
        fi
        ;;
    *)
        print_error "Invalid platform selection"
        exit 1
        ;;
esac

print_info "Build and install completed successfully!"
echo ""
print_info "App is now running on your device."
