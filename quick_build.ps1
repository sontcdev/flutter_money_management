# Quick build and install script - skips prompts, uses defaults
# Usage: .\quick_build.ps1 [debug|profile|release] [device-id]

param(
    [string]$Mode = "debug",
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Flutter Quick Build & Install" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Validate mode
if ($Mode -notin @("debug", "profile", "release")) {
    Write-Host "[ERROR] Invalid mode: $Mode" -ForegroundColor Red
    Write-Host "Usage: .\quick_build.ps1 [debug|profile|release] [device-id]" -ForegroundColor Yellow
    exit 1
}

Write-Host "[INFO] Mode: $Mode" -ForegroundColor Green
if ($DeviceId) {
    Write-Host "[INFO] Target device: $DeviceId" -ForegroundColor Green
}
Write-Host ""

# Check Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Flutter not found in PATH" -ForegroundColor Red
    exit 1
}

# Quick dependency check
Write-Host "[INFO] Getting dependencies..." -ForegroundColor Green
flutter pub get | Out-Null

# Generate code
Write-Host "[INFO] Generating code..." -ForegroundColor Green
flutter gen-l10n | Out-Null
dart run build_runner build --delete-conflicting-outputs | Out-Null

# Build and run
Write-Host "[INFO] Building and installing..." -ForegroundColor Green
if ($Mode -eq "release") {
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Build failed" -ForegroundColor Red
        exit 1
    }
    if ($DeviceId) {
        flutter install --release -d $DeviceId
    } else {
        flutter install --release
    }
} else {
    if ($DeviceId) {
        flutter run --$Mode -d $DeviceId
    } else {
        flutter run --$Mode
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[INFO] Done!" -ForegroundColor Green
