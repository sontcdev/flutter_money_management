@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0.."
for %%I in ("%ROOT_DIR%") do set "ROOT_DIR=%%~fI"
set "OUTPUT_PATH=%ROOT_DIR%\build\app\outputs\bundle\release\app-release.aab"

call :require_tool flutter
if errorlevel 1 exit /b 1

call :require_tool dart
if errorlevel 1 exit /b 1

echo MyMoney Play Store AAB build
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

echo ==^> Build Android App Bundle
call flutter build appbundle --release
if errorlevel 1 exit /b 1
echo.

if not exist "%OUTPUT_PATH%" (
  echo AAB output not found: %OUTPUT_PATH% 1>&2
  exit /b 1
)

echo Build completed successfully.
echo AAB: %OUTPUT_PATH%
exit /b 0

:require_tool
where %~1 >nul 2>&1
if errorlevel 1 (
  echo Required tool not found: %~1 1>&2
  exit /b 1
)
exit /b 0
