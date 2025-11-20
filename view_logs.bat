@echo off
echo === Flutter App Logs ===
echo Press Ctrl+C to stop viewing logs
echo.
adb logcat | findstr /i "flutter dart sqlite test3_cursor"

