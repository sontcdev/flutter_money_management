#!/bin/bash
# path: ios_build_all.sh
# Script to build and install iOS app on both physical devices AND simulators

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
APP_NAME="Money Wise"
BUNDLE_ID="com.sontc.financeappv1"
SCHEME="Runner"

echo ""
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                      ║${NC}"
echo -e "${MAGENTA}║    ${GREEN}Money Wise${MAGENTA} - iOS Build (Device + Simulator)   ║${NC}"
echo -e "${MAGENTA}║                                                      ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print step
print_step() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check Flutter installation
print_step "Checking Flutter installation"
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -1)
print_success "Flutter found: $FLUTTER_VERSION"

# Get all iOS devices and simulators
print_step "Detecting iOS targets"

FLUTTER_DEVICES=$(flutter devices 2>/dev/null)

# Physical devices
PHYSICAL_DEVICES=$(echo "$FLUTTER_DEVICES" | grep "iOS" | grep -v "Simulator" || true)
PHYSICAL_COUNT=$(echo "$PHYSICAL_DEVICES" | grep -c "iOS" || echo "0")

# Simulators
SIMULATORS=$(echo "$FLUTTER_DEVICES" | grep "Simulator" | grep "iOS" || true)
SIMULATOR_COUNT=$(echo "$SIMULATORS" | grep -c "Simulator" || echo "0")

echo ""
print_info "Found ${PHYSICAL_COUNT} physical device(s)"
if [ "$PHYSICAL_COUNT" -gt 0 ]; then
    echo "$PHYSICAL_DEVICES" | while IFS= read -r line; do
        echo -e "  ${GREEN}📱 $line${NC}"
    done
fi

echo ""
print_info "Found ${SIMULATOR_COUNT} simulator(s)"
if [ "$SIMULATOR_COUNT" -gt 0 ]; then
    echo "$SIMULATORS" | while IFS= read -r line; do
        echo -e "  ${CYAN}📲 $line${NC}"
    done
fi

if [ "$PHYSICAL_COUNT" -eq 0 ] && [ "$SIMULATOR_COUNT" -eq 0 ]; then
    print_error "No iOS devices or simulators found"
    echo ""
    print_warning "To use simulator:"
    echo "  1. Open Xcode"
    echo "  2. Window > Devices and Simulators"
    echo "  3. Create a new simulator or boot an existing one"
    echo ""
    print_warning "To use physical device:"
    echo "  1. Connect iPhone/iPad via USB"
    echo "  2. Unlock device and trust computer"
    echo "  3. Enable Developer Mode (iOS 16+)"
    exit 1
fi

# Ask user what to do
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}What would you like to build?${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""
echo "  [1] Physical devices only (${PHYSICAL_COUNT} found)"
echo "  [2] Simulators only (${SIMULATOR_COUNT} found)"
echo "  [3] Both devices and simulators"
echo "  [4] Select specific target"
echo ""
read -p "Your choice [1-4]: " choice

case $choice in
    1)
        if [ "$PHYSICAL_COUNT" -eq 0 ]; then
            print_error "No physical devices found"
            exit 1
        fi
        BUILD_TARGET="device"
        ;;
    2)
        if [ "$SIMULATOR_COUNT" -eq 0 ]; then
            print_error "No simulators found"
            exit 1
        fi
        BUILD_TARGET="simulator"
        ;;
    3)
        if [ "$PHYSICAL_COUNT" -eq 0 ] && [ "$SIMULATOR_COUNT" -eq 0 ]; then
            print_error "No devices or simulators found"
            exit 1
        fi
        BUILD_TARGET="both"
        ;;
    4)
        echo ""
        echo "Available targets:"
        flutter devices | grep -E "(iOS|Simulator)"
        echo ""
        read -p "Enter device ID: " DEVICE_ID
        BUILD_TARGET="specific"
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Clean previous builds
print_step "Cleaning previous builds"
flutter clean > /dev/null 2>&1
rm -rf ios/build
rm -rf build/ios
print_success "Clean complete"

# Get dependencies
print_step "Getting dependencies"
flutter pub get > /dev/null 2>&1
print_success "Dependencies updated"

# Generate localizations
print_step "Generating localizations"
flutter gen-l10n > /dev/null 2>&1
print_success "Localizations generated"

# Generate build_runner code (if needed)
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    print_step "Generating code with build_runner"
    flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1
    print_success "Code generation complete"
fi

# Function to build and install on device
build_for_device() {
    local device_id=$1
    local device_name=$2

    print_step "Building for device: $device_name"

    # Uninstall old version
    print_info "Removing old version..."
    flutter install --uninstall-only --device-id="$device_id" > /dev/null 2>&1 || print_warning "No previous version"

    # Build and install
    print_info "Building and installing..."
    flutter build ios --release --no-codesign > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        print_error "Build failed for $device_name"
        return 1
    fi

    # Install
    if command -v ios-deploy &> /dev/null; then
        APP_PATH="build/ios/iphoneos/Runner.app"
        ios-deploy --id "$device_id" --bundle "$APP_PATH" --no-wifi > /dev/null 2>&1
    else
        flutter install --device-id="$device_id" > /dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
        print_success "✓ Installed on $device_name"
        return 0
    else
        print_error "✗ Installation failed on $device_name"
        return 1
    fi
}

# Function to build and install on simulator
build_for_simulator() {
    local device_id=$1
    local device_name=$2

    print_step "Building for simulator: $device_name"

    # Uninstall old version
    print_info "Removing old version..."
    flutter install --uninstall-only --device-id="$device_id" > /dev/null 2>&1 || print_warning "No previous version"

    # Build and install for simulator (debug mode - only mode supported)
    print_info "Building and installing..."
    flutter build ios --debug --simulator > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        print_error "Build failed for $device_name"
        return 1
    fi

    # Install
    flutter install --device-id="$device_id" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        print_success "✓ Installed on $device_name"
        return 0
    else
        print_error "✗ Installation failed on $device_name"
        return 1
    fi
}

# Execute based on choice
case $BUILD_TARGET in
    device)
        print_step "Building for physical devices"
        success_count=0
        fail_count=0

        echo "$PHYSICAL_DEVICES" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                device_id=$(echo "$line" | awk '{print $5}' | sed 's/[()]//g')
                device_name=$(echo "$line" | awk '{print $1}')

                if build_for_device "$device_id" "$device_name"; then
                    ((success_count++))
                else
                    ((fail_count++))
                fi
            fi
        done
        ;;

    simulator)
        print_step "Building for simulators"
        success_count=0
        fail_count=0

        echo "$SIMULATORS" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                device_id=$(echo "$line" | awk '{print $4}' | sed 's/[()]//g')
                device_name=$(echo "$line" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)

                if build_for_simulator "$device_id" "$device_name"; then
                    ((success_count++))
                else
                    ((fail_count++))
                fi
            fi
        done
        ;;

    both)
        print_step "Building for all targets"

        # Build for simulators first (faster)
        if [ "$SIMULATOR_COUNT" -gt 0 ]; then
            print_info "Installing on simulators..."
            echo "$SIMULATORS" | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    device_id=$(echo "$line" | awk '{print $4}' | sed 's/[()]//g')
                    device_name=$(echo "$line" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)
                    build_for_simulator "$device_id" "$device_name"
                fi
            done
        fi

        # Build for physical devices
        if [ "$PHYSICAL_COUNT" -gt 0 ]; then
            print_info "Installing on physical devices..."
            echo "$PHYSICAL_DEVICES" | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    device_id=$(echo "$line" | awk '{print $5}' | sed 's/[()]//g')
                    device_name=$(echo "$line" | awk '{print $1}')
                    build_for_device "$device_id" "$device_name"
                fi
            done
        fi
        ;;

    specific)
        DEVICE_LINE=$(flutter devices | grep "$DEVICE_ID")
        if echo "$DEVICE_LINE" | grep -q "Simulator"; then
            device_name=$(echo "$DEVICE_LINE" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)
            build_for_simulator "$DEVICE_ID" "$device_name"
        else
            device_name=$(echo "$DEVICE_LINE" | awk '{print $1}')
            build_for_device "$DEVICE_ID" "$device_name"
        fi
        ;;
esac

# Summary
echo ""
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                      ║${NC}"
echo -e "${MAGENTA}║         ${GREEN}✨ Build & Install Complete! ✨${MAGENTA}              ║${NC}"
echo -e "${MAGENTA}║                                                      ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ App Name:${NC}      $APP_NAME"
echo -e "${GREEN}✓ Bundle ID:${NC}     $BUNDLE_ID"

if [ "$BUILD_TARGET" = "device" ] || [ "$BUILD_TARGET" = "both" ]; then
    echo -e "${GREEN}✓ Physical devices:${NC} $PHYSICAL_COUNT"
fi

if [ "$BUILD_TARGET" = "simulator" ] || [ "$BUILD_TARGET" = "both" ]; then
    echo -e "${GREEN}✓ Simulators:${NC}       $SIMULATOR_COUNT"
fi

echo ""
echo -e "${CYAN}📱 The app is now installed and ready to use!${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo -e "   • Physical devices: Launch from home screen"
echo -e "   • Simulators: App will auto-launch or check home screen"
echo -e "   • Simulator build is debug mode (only mode supported)"
echo -e "   • Device build is release mode (fully optimized)"
echo ""

