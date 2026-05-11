@echo off
setlocal enabledelayedexpansion

REM Script to increment patch version in pubspec.yaml
REM Example: 1.0.7 -> 1.0.8

set "PUBSPEC=pubspec.yaml"

REM Read current version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" %PUBSPEC%') do set CURRENT_VERSION=%%a

echo Current version: %CURRENT_VERSION%

REM Parse version (format: major.minor.patch)
for /f "tokens=1,2,3 delims=." %%a in ("%CURRENT_VERSION%") do (
    set MAJOR=%%a
    set MINOR=%%b
    set PATCH=%%c
)

REM Increment patch version
set /a NEW_PATCH=%PATCH%+1
set NEW_VERSION=%MAJOR%.%MINOR%.%NEW_PATCH%

echo New version: %NEW_VERSION%

REM Update pubspec.yaml
powershell -Command "(Get-Content '%PUBSPEC%') -replace '^version: %CURRENT_VERSION%', 'version: %NEW_VERSION%' | Set-Content '%PUBSPEC%'"

echo Version updated successfully!
exit /b 0
