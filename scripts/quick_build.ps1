param(
    [string]$Mode = "debug",
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

if ($Mode -notin @("debug", "profile", "release")) {
    throw "Usage: .\quick_build.ps1 [debug|profile|release] [device-id]"
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is not installed or not in PATH."
}

flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

if ($Mode -eq "release") {
    flutter build apk --release
    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        flutter install --release
    } else {
        flutter install --release -d $DeviceId
    }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    flutter run --$Mode
} else {
    flutter run --$Mode -d $DeviceId
}
