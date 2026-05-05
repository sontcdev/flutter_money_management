@echo off
REM Quick build and install script - skips prompts, uses defaults
REM Usage: quick_build.bat [debug|profile|release] [device-id]

setlocal enabledelayedexpansion

echo ==================================
echo Flutter Quick Build ^& Install
echo ==================================
echo.

REM Parse arguments
set "MODE=%~1"
set "DEVICE_ID=%~2"

REM Default to debug mode if not specified
if "!MODE!"=="" set "MODE=debug"

REM Validate mode
if not "!MODE!"=="debug" if not "!MODE!"=="profile" if not "!MODE!"=="release" (
    echo [ERROR] Invalid mode: !MODE!
    echo Usage: quick_build.bat [debug^|profile^|release] [device-id]
    exit /b 1
)

echo [INFO] Mode: !MODE!
if not "!DEVICE_ID!"=="" echo [INFO] Target device: !DEVICE_ID!
echo.

REM Check Flutter
where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Flutter not found in PATH
    exit /b 1
)

REM Quick dependency check
echo [INFO] Getting dependencies...
call flutter pub get >nul 2>nul

REM Generate code
echo [INFO] Generating code...
call flutter gen-l10n >nul 2>nul
call dart run build_runner build --delete-conflicting-outputs >nul 2>nul

REM Build and run
echo [INFO] Building and installing...
if "!MODE!"=="release" (
    call flutter build apk --release
    if errorlevel 1 (
        echo [ERROR] Build failed
        exit /b 1
    )
    if "!DEVICE_ID!"=="" (
        call flutter install --release
    ) else (
        call flutter install --release -d !DEVICE_ID!
    )
) else (
    if "!DEVICE_ID!"=="" (
        call flutter run --!MODE!
    ) else (
        call flutter run --!MODE! -d !DEVICE_ID!
    )
)

if errorlevel 1 (
    echo [ERROR] Failed
    exit /b 1
)

echo.
echo [INFO] Done!
