@echo off
setlocal

set "MODE=%~1"
set "DEVICE_ID=%~2"
if "%MODE%"=="" set "MODE=debug"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not in PATH.
  exit /b 1
)

if /I not "%MODE%"=="debug" if /I not "%MODE%"=="profile" if /I not "%MODE%"=="release" (
  echo Usage: quick_build.bat [debug^|profile^|release] [device-id]
  exit /b 1
)

call flutter pub get || exit /b 1
call flutter gen-l10n || exit /b 1
call dart run build_runner build --delete-conflicting-outputs || exit /b 1

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
