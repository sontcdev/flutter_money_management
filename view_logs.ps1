# Script to view Flutter app logs on Windows
# Usage: .\view_logs.ps1

Write-Host "=== Flutter App Logs ===" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop viewing logs" -ForegroundColor Yellow
Write-Host ""

# Filter for Flutter/Dart logs
adb logcat | Select-String -Pattern "flutter|dart|sqlite|test3_cursor" -Context 0,2

