# Auto build and install Flutter app to connected device
# Works for both Android and iOS devices on Windows

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Flutter Auto Build & Install" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Function to print colored output
function Print-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Check if Flutter is installed
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Print-Error "Flutter is not installed or not in PATH"
    exit 1
}

# Check for connected devices
Print-Info "Checking for connected devices..."
$devicesOutput = flutter devices --machine | ConvertFrom-Json
$deviceCount = $devicesOutput.Count

if ($deviceCount -eq 0) {
    Print-Error "No devices connected. Please connect a device or start an emulator/simulator."
    exit 1
}

Print-Info "Found $deviceCount device(s)"
flutter devices

Write-Host ""
$buildModeInput = Read-Host "Select build mode (1=Debug, 2=Profile, 3=Release) [1]"
if ([string]::IsNullOrWhiteSpace($buildModeInput)) {
    $buildModeInput = "1"
}

switch ($buildModeInput) {
    "1" {
        $mode = "debug"
        Print-Info "Building in DEBUG mode"
    }
    "2" {
        $mode = "profile"
        Print-Info "Building in PROFILE mode"
    }
    "3" {
        $mode = "release"
        Print-Info "Building in RELEASE mode"
    }
    default {
        Print-Error "Invalid selection"
        exit 1
    }
}

Write-Host ""
$platformInput = Read-Host "Select target platform (1=Android, 2=iOS, 3=Auto-detect) [3]"
if ([string]::IsNullOrWhiteSpace($platformInput)) {
    $platformInput = "3"
}

# Step 1: Clean previous builds (optional)
$cleanInput = Read-Host "Clean previous builds? (y/N)"
if ($cleanInput -eq "y" -or $cleanInput -eq "Y") {
    Print-Info "Cleaning previous builds..."
    flutter clean
    if (Test-Path ".dart_tool/build") {
        Remove-Item -Recurse -Force ".dart_tool/build"
    }
}

# Step 2: Get dependencies
Print-Info "Getting dependencies..."
flutter pub get

# Step 3: Generate localization
Print-Info "Generating localization files..."
flutter gen-l10n

# Step 4: Run code generation
Print-Info "Running code generation..."
dart run build_runner build --delete-conflicting-outputs

# Step 5: Analyze code
Print-Info "Analyzing code..."
$analyzeResult = flutter analyze
if ($LASTEXITCODE -ne 0) {
    $continueInput = Read-Host "Code analysis found issues. Continue anyway? (y/N)"
    if ($continueInput -ne "y" -and $continueInput -ne "Y") {
        exit 1
    }
}

# Step 6: Build and install based on platform
switch ($platformInput) {
    "1" {
        # Android
        Print-Info "Building and installing for Android..."
        if ($mode -eq "release") {
            flutter build apk --release
            Print-Info "Installing APK..."
            flutter install --release
        } else {
            flutter run --$mode
        }
    }
    "2" {
        # iOS
        Print-Info "Building and installing for iOS..."
        if ($mode -eq "release") {
            flutter build ios --release --no-codesign
            Print-Warning "Release build completed. Please use Xcode to sign and install."
        } else {
            flutter run --$mode
        }
    }
    "3" {
        # Auto-detect
        Print-Info "Auto-detecting platform and installing..."
        if ($mode -eq "release") {
            try {
                flutter build apk --release
                flutter install --release
            } catch {
                flutter build ios --release --no-codesign
                Print-Warning "iOS release build completed. Please use Xcode to sign and install."
            }
        } else {
            flutter run --$mode
        }
    }
    default {
        Print-Error "Invalid platform selection"
        exit 1
    }
}

Print-Info "Build and install completed successfully!"
Write-Host ""
Print-Info "App is now running on your device."
