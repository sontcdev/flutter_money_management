$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is not installed or not in PATH."
}

flutter devices

$mode = Read-Host "Build mode [debug/profile/release] (default: debug)"
if ([string]::IsNullOrWhiteSpace($mode)) { $mode = "debug" }
if ($mode -notin @("debug", "profile", "release")) {
    throw "Invalid mode: $mode"
}

$platform = Read-Host "Platform [android/ios] (default: android)"
if ([string]::IsNullOrWhiteSpace($platform)) { $platform = "android" }
if ($platform -notin @("android", "ios")) {
    throw "Invalid platform: $platform"
}

$clean = Read-Host "Clean first? [y/N]"
if ($clean -in @("y", "Y")) {
    flutter clean
    if (Test-Path ".dart_tool/build") {
        Remove-Item -LiteralPath ".dart_tool/build" -Recurse -Force
    }
}

flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze

$deviceId = Read-Host "Device id (leave empty for auto-detect)"

if ($platform -eq "android") {
    if ($mode -eq "release") {
        flutter build apk --release
        if ([string]::IsNullOrWhiteSpace($deviceId)) {
            flutter install --release
        } else {
            flutter install --release -d $deviceId
        }
    } else {
        if ([string]::IsNullOrWhiteSpace($deviceId)) {
            flutter run --$mode
        } else {
            flutter run --$mode -d $deviceId
        }
    }
    exit 0
}

if ($mode -eq "release") {
    flutter build ios --release --no-codesign
    "iOS release build completed. Sign and install from Xcode as needed."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($deviceId)) {
    flutter run --$mode
} else {
    flutter run --$mode -d $deviceId
}
