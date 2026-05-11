@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0.."
for %%I in ("%ROOT_DIR%") do set "ROOT_DIR=%%~fI"
set "OUTPUT_PATH=%ROOT_DIR%\build\app\outputs\flutter-apk\app-release.apk"
set "PACKAGE_NAME=com.sontc.financeappv1"

call :require_tool flutter
if errorlevel 1 exit /b 1

call :require_tool dart
if errorlevel 1 exit /b 1

echo MyMoney Android release APK build
echo Project root: %ROOT_DIR%
echo.

echo ==^> Install dependencies
call flutter pub get
if errorlevel 1 exit /b 1
echo.

echo ==^> Generate localizations
call flutter gen-l10n
if errorlevel 1 exit /b 1
echo.

echo ==^> Generate code
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 exit /b 1
echo.

echo ==^> Analyze project
call flutter analyze
if errorlevel 1 exit /b 1
echo.

echo ==^> Run tests
call flutter test --coverage
if errorlevel 1 exit /b 1
echo.

echo ==^> Build release APK
call flutter build apk --release --dart-define=ENABLE_RELEASE_NETWORK_LOGGING=true
if errorlevel 1 exit /b 1
echo.

if not exist "%OUTPUT_PATH%" (
  echo APK output not found: %OUTPUT_PATH% 1>&2
  exit /b 1
)

echo Build completed successfully.
echo APK: %OUTPUT_PATH%

call :reinstall_apk_if_possible
exit /b 0

:require_tool
where %~1 >nul 2>&1
if errorlevel 1 (
  echo Required tool not found: %~1 1>&2
  exit /b 1
)
exit /b 0

:reinstall_apk_if_possible
where adb >nul 2>&1
if errorlevel 1 (
  echo ADB not found; skipping device uninstall/install step.
  exit /b 0
)

set "DEVICE_ID="
for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
  if "%%B"=="device" (
    set "DEVICE_ID=%%A"
    goto :device_found
  )
)

echo No connected Android device/emulator found; skipping reinstall step.
exit /b 0

:device_found
echo ==^> Reinstall on device: %DEVICE_ID%
adb -s %DEVICE_ID% uninstall %PACKAGE_NAME% >nul 2>&1
adb -s %DEVICE_ID% install -r "%OUTPUT_PATH%"
if errorlevel 1 exit /b 1
echo.
exit /b 0
