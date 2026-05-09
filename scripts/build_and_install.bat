@echo off
setlocal enabledelayedexpansion

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not in PATH.
  exit /b 1
)

echo ==^> Interactive build and install
call flutter devices
echo.

set "MODE="
set /p "MODE=Build mode [debug/profile/release] (default: debug): "
if "%MODE%"=="" set "MODE=debug"

if /I not "%MODE%"=="debug" if /I not "%MODE%"=="profile" if /I not "%MODE%"=="release" (
  echo Invalid mode: %MODE%
  exit /b 1
)

set "PLATFORM="
set /p "PLATFORM=Platform [android] (default: android): "
if "%PLATFORM%"=="" set "PLATFORM=android"
if /I not "%PLATFORM%"=="android" (
  echo This Windows helper supports Android only. Use PowerShell or macOS for iOS flows.
  exit /b 1
)

set "CLEAN="
set /p "CLEAN=Clean first? [y/N]: "
if /I "%CLEAN%"=="y" (
  call flutter clean
  if exist ".dart_tool\build" rmdir /s /q ".dart_tool\build"
)

call flutter pub get || exit /b 1
call flutter gen-l10n || exit /b 1
call dart run build_runner build --delete-conflicting-outputs || exit /b 1
call flutter analyze || exit /b 1

set "DEVICE_ID="
set /p "DEVICE_ID=Device id (leave empty for auto-detect): "

if /I "%MODE%"=="release" (
  call flutter build apk --release || exit /b 1
  if "%DEVICE_ID%"=="" (
    call flutter install --release || exit /b 1
  ) else (
    call flutter install --release -d %DEVICE_ID% || exit /b 1
  )
) else (
  if "%DEVICE_ID%"=="" (
    call flutter run --%MODE% || exit /b 1
  ) else (
    call flutter run --%MODE% -d %DEVICE_ID% || exit /b 1
  )
)
