@echo off
setlocal enabledelayedexpansion

echo ==================================
echo Flutter Auto Build ^& Install
echo ==================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH
    pause
    exit /b 1
)

REM Check for connected devices
echo [INFO] Checking for connected devices...
flutter devices 2>nul
echo.

REM Get build mode
:ask_build_mode
set "BUILD_MODE="
set /p "BUILD_MODE=Select build mode (1=Debug, 2=Profile, 3=Release) [1]: "
if "!BUILD_MODE!"=="" set "BUILD_MODE=1"

if "!BUILD_MODE!"=="1" (
    set "MODE=debug"
    echo [INFO] Building in DEBUG mode
) else if "!BUILD_MODE!"=="2" (
    set "MODE=profile"
    echo [INFO] Building in PROFILE mode
) else if "!BUILD_MODE!"=="3" (
    set "MODE=release"
    echo [INFO] Building in RELEASE mode
) else (
    echo [ERROR] Invalid selection. Please enter 1, 2, or 3.
    goto ask_build_mode
)
echo.

REM Get platform
:ask_platform
set "PLATFORM="
set /p "PLATFORM=Select target platform (1=Android, 2=iOS, 3=Auto-detect) [3]: "
if "!PLATFORM!"=="" set "PLATFORM=3"

if "!PLATFORM!"=="1" (
    echo [INFO] Target: Android
) else if "!PLATFORM!"=="2" (
    echo [INFO] Target: iOS
) else if "!PLATFORM!"=="3" (
    echo [INFO] Target: Auto-detect
) else (
    echo [ERROR] Invalid selection. Please enter 1, 2, or 3.
    goto ask_platform
)
echo.

REM Clean previous builds
set "CLEAN="
set /p "CLEAN=Clean previous builds? (y/N): "
if /i "!CLEAN!"=="y" (
    echo [INFO] Cleaning previous builds...
    call flutter clean
    if exist ".dart_tool\build" rmdir /s /q ".dart_tool\build" 2>nul
    echo.
)

REM Get dependencies
echo [INFO] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)
echo.

REM Generate localization
echo [INFO] Generating localization files...
call flutter gen-l10n
if errorlevel 1 (
    echo [ERROR] Failed to generate localization
    pause
    exit /b 1
)
echo.

REM Run code generation
echo [INFO] Running code generation...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo [ERROR] Failed to run code generation
    pause
    exit /b 1
)
echo.

REM Analyze code
echo [INFO] Analyzing code...
call flutter analyze
if errorlevel 1 (
    echo [WARNING] Code analysis found issues
    set /p "CONTINUE=Continue anyway? (y/N): "
    if /i not "!CONTINUE!"=="y" (
        pause
        exit /b 1
    )
)
echo.

REM Select device if multiple devices available
echo [INFO] Detecting available devices...
for /f "delims=" %%i in ('flutter devices') do set "DEVICES_OUTPUT=%%i"

REM Ask user to select device or use default
set "DEVICE_ID="
set /p "DEVICE_ID=Enter device ID (leave empty for auto-detect): "

REM Build and install
if "!PLATFORM!"=="1" (
    REM Android
    echo [INFO] Building and installing for Android...
    if "!MODE!"=="release" (
        call flutter build apk --release
        if errorlevel 1 (
            echo [ERROR] Build failed
            pause
            exit /b 1
        )
        echo [INFO] Installing APK...
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
) else if "!PLATFORM!"=="2" (
    REM iOS
    echo [INFO] Building for iOS...
    if "!MODE!"=="release" (
        call flutter build ios --release --no-codesign
        echo [WARNING] Release build completed. Please use Xcode to sign and install.
        pause
    ) else (
        if "!DEVICE_ID!"=="" (
            call flutter run --!MODE!
        ) else (
            call flutter run --!MODE! -d !DEVICE_ID!
        )
    )
) else (
    REM Auto-detect
    echo [INFO] Auto-detecting platform and installing...
    if "!MODE!"=="release" (
        call flutter build apk --release
        if errorlevel 1 (
            echo [ERROR] Build failed
            pause
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
)

if errorlevel 1 (
    echo [ERROR] Build/Install failed
    pause
    exit /b 1
)

echo.
echo [INFO] Build and install completed successfully!
echo [INFO] App is now running on your device.
pause
