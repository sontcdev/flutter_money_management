@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   MyMoney - Build AAB Release Script
echo ========================================
echo.

REM Step 1: Increment version
echo [1/7] Incrementing version...
call scripts\increment_version.bat
if errorlevel 1 (
    echo ERROR: Failed to increment version
    exit /b 1
)
echo.

REM Step 2: Flutter pub get
echo [2/7] Running flutter pub get...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    exit /b 1
)
echo.

REM Step 3: Generate localizations
echo [3/7] Generating localizations...
call flutter gen-l10n
if errorlevel 1 (
    echo ERROR: Failed to generate localizations
    exit /b 1
)
echo.

REM Step 4: Build runner
echo [4/7] Running build_runner...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo ERROR: Failed to run build_runner
    exit /b 1
)
echo.

REM Step 5: Analyze code
echo [5/7] Analyzing code...
call flutter analyze
if errorlevel 1 (
    echo WARNING: Code analysis found issues
    echo Continuing with build...
)
echo.

REM Step 6: Build AAB
echo [6/7] Building AAB (release)...
call flutter build appbundle --release
if errorlevel 1 (
    echo ERROR: Failed to build AAB
    exit /b 1
)
echo.

REM Step 7: Show results
echo [7/7] Build completed successfully!
echo.
echo ========================================
echo   BUILD SUMMARY
echo ========================================

REM Get version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" pubspec.yaml') do set VERSION=%%a
echo Version: %VERSION%

REM Get file size
set AAB_PATH=build\app\outputs\bundle\release\app-release.aab
if exist "%AAB_PATH%" (
    for %%A in ("%AAB_PATH%") do set SIZE=%%~zA
    set /a SIZE_MB=!SIZE! / 1048576
    echo File size: !SIZE_MB! MB
    echo.
    echo Output file:
    echo %CD%\%AAB_PATH%
    echo.
    echo Ready to upload to Google Play Console!
) else (
    echo ERROR: AAB file not found at expected location
    exit /b 1
)

echo ========================================
pause
