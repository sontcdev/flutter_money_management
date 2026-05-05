# Build Guide

Hướng dẫn build và cài đặt ứng dụng Flutter Money Management.

## Yêu cầu

- Flutter SDK 3.27+
- Dart SDK 3.0+
- Android Studio / Xcode (tùy platform)
- Device hoặc Emulator đã kết nối

## Quick Start

### 1. Setup lần đầu

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

### 2. Build nhanh (Development)

```bash
# Windows Command Prompt
quick_build.bat

# PowerShell
.\quick_build.ps1

# Bash (macOS/Linux)
./quick_build.sh
```

### 3. Build đầy đủ (với tất cả checks)

```bash
# Windows
build_and_install.bat

# PowerShell
.\build_and_install.ps1
```

## Build Scripts

### Quick Build (Khuyến nghị cho development)

**Đặc điểm:**
- Không có prompts
- Build nhanh nhất
- Hỗ trợ command-line arguments
- Tự động chạy codegen

**Cách dùng:**

```bash
# Debug mode (mặc định)
quick_build.bat

# Chỉ định build mode
quick_build.bat debug
quick_build.bat profile
quick_build.bat release

# Chỉ định device cụ thể
quick_build.bat debug emulator-5554
quick_build.bat release 192.168.1.100:5555
```

**PowerShell:**
```powershell
.\quick_build.ps1
.\quick_build.ps1 debug
.\quick_build.ps1 release emulator-5554
```

### Full Interactive Build

**Đặc điểm:**
- Interactive prompts
- Tùy chọn clean build
- Code analysis trước khi build
- Chọn platform và device

**Cách dùng:**

```bash
build_and_install.bat
```

**Các bước:**
1. Chọn build mode (Debug/Profile/Release)
2. Chọn platform (Android/iOS/Auto-detect)
3. Chọn có clean build không
4. Chọn device (nếu có nhiều devices)
5. Script tự động: dependencies → localization → codegen → analyze → build → install

## Build Modes

### Debug Mode
- Có hot reload
- Có debug symbols
- Performance chậm hơn
- Dùng cho development

```bash
quick_build.bat debug
flutter run --debug
```

### Profile Mode
- Không có hot reload
- Performance gần release
- Có profiling tools
- Dùng để test performance

```bash
quick_build.bat profile
flutter run --profile
```

### Release Mode
- Không có hot reload
- Performance tối ưu
- Không có debug symbols
- Dùng cho production

```bash
quick_build.bat release
flutter build apk --release
```

## Platform-Specific Builds

### Android

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

**App Bundle (cho Google Play):**
```bash
flutter build appbundle --release
```

**Cài đặt:**
```bash
flutter install
flutter install -d emulator-5554
```

### iOS

**Debug (Simulator):**
```bash
flutter build ios --debug --simulator
```

**Release (Physical Device):**
```bash
flutter build ios --release --no-codesign
```

**Quick build script:**
```bash
./ios_build_all.sh
```

Script này có interactive menu:
- Release build cho physical devices
- Debug build cho simulators

## Device Management

### Xem danh sách devices

```bash
flutter devices
```

**Output mẫu:**
```
emulator-5554 • Android SDK built for x86 • android-x86 • Android 11 (API 30)
192.168.1.100:5555 • SM G973F • android-arm64 • Android 12 (API 31)
```

### Kết nối device qua WiFi (Android)

```bash
# Kết nối device qua USB trước
adb tcpip 5555
adb connect 192.168.1.100:5555

# Giờ có thể rút USB và build wireless
quick_build.bat debug 192.168.1.100:5555
```

### Khởi động emulator

```bash
# List emulators
flutter emulators

# Khởi động emulator
flutter emulators --launch <emulator_id>
```

## Code Generation

### Khi nào cần chạy codegen?

Sau khi thay đổi:
- Models với `@freezed` annotation (`lib/src/models/*.dart`)
- Database tables (`lib/src/data/local/tables/*.dart`)
- DAOs (`lib/src/data/local/daos/*.dart`)
- Database schema (`lib/src/data/local/app_database.dart`)

### Chạy codegen

**One-time:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Watch mode (tự động chạy khi file thay đổi):**
```bash
dart run build_runner watch --delete-conflicting-outputs
```

**Clean và rebuild:**
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## Localization

### Generate localization files

```bash
flutter gen-l10n
```

### Thêm translation mới

1. Sửa file ARB trong `lib/l10n/`:
   - `app_en.arb` (English)
   - `app_vi.arb` (Vietnamese)

2. Chạy codegen:
   ```bash
   flutter gen-l10n
   ```

3. Sử dụng trong code:
   ```dart
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.hello)
   ```

## Verification

### Analyze code

```bash
flutter analyze
```

### Run tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/budget_service_test.dart

# With coverage
flutter test --coverage
```

### Full verification (như CI)

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage
flutter build apk --release
```

## Troubleshooting

### Build fails với "No such file .g.dart"

**Nguyên nhân:** Thiếu generated files

**Giải pháp:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Build fails với localization errors

**Nguyên nhân:** Thiếu localization files

**Giải pháp:**
```bash
flutter gen-l10n
```

### Stale generated code

**Nguyên nhân:** Generated files cũ không khớp với source

**Giải pháp:**
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Flutter command not found

**Giải pháp:**
```bash
# Windows
setx PATH "%PATH%;C:\flutter\bin"

# macOS/Linux
export PATH="$PATH:$HOME/flutter/bin"
```

### Device not detected

**Android:**
```bash
adb devices
adb kill-server
adb start-server
```

**iOS:**
```bash
xcrun simctl list devices
```

### PowerShell script won't run

**Nguyên nhân:** Execution policy

**Giải pháp:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Clean build (khi mọi thứ bị lỗi)

```bash
flutter clean
rm -rf .dart_tool/build
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## CI/CD Workflow

Project sử dụng GitHub Actions (`.github/workflows/ci.yml`):

**Steps:**
1. `flutter pub get`
2. `flutter gen-l10n`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter analyze`
5. `flutter test --coverage`
6. `flutter build apk --release`

**Để test locally giống CI:**
```bash
flutter pub get && \
flutter gen-l10n && \
dart run build_runner build --delete-conflicting-outputs && \
flutter analyze && \
flutter test --coverage && \
flutter build apk --release
```

## Performance Tips

### Development

1. Dùng `quick_build.bat` thay vì full build
2. Dùng watch mode cho codegen:
   ```bash
   dart run build_runner watch --delete-conflicting-outputs
   ```
3. Dùng hot reload thay vì rebuild:
   - Press `r` trong terminal để hot reload
   - Press `R` để hot restart

### Build Time

1. Tăng Gradle memory (Android):
   ```properties
   # android/gradle.properties
   org.gradle.jvmargs=-Xmx4096m
   ```

2. Enable parallel builds:
   ```properties
   # android/gradle.properties
   org.gradle.parallel=true
   org.gradle.workers.max=4
   ```

3. Sử dụng build cache:
   ```bash
   flutter build apk --release --build-shared-library
   ```

## Package Info

- **Bundle ID (Android):** `com.sontc.financeapp`
- **Bundle ID (iOS):** `com.sontc.financeappv1`
- **App Name:** Money Wise
- **Current Schema Version:** 4

## Viewing API Logs

### Method 1: Enable Supabase Debug Mode (Recommended)

Supabase debug mode is already enabled in `lib/src/app_bootstrap.dart`:

```dart
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.supabaseAnonKey,
  debug: true, // Shows all API calls
);
```

**Run app and view logs:**
```bash
flutter run --debug
```

All Supabase API calls will be logged to console with:
- Request URL and method
- Request headers and body
- Response status and data
- Timing information

### Method 2: Use API Logger Utility

For custom logging, use `ApiLogger` utility (`lib/src/utils/api_logger.dart`):

```dart
import 'package:flutter_money_management/src/utils/api_logger.dart';

// Log request
ApiLogger.logRequest('POST', '/workspaces', data: {'name': 'My Workspace'});

// Log response
ApiLogger.logResponse('POST', '/workspaces', response, statusCode: 201);

// Log error
ApiLogger.logError('POST', '/workspaces', error, stackTrace: stackTrace);
```

### Method 3: Filter Logs by Pattern

**Windows PowerShell:**
```powershell
flutter run --debug 2>&1 | Select-String -Pattern "supabase|API|HTTP"
```

**Windows Command Prompt:**
```bash
flutter run --debug 2>&1 | findstr /i "supabase API HTTP"
```

**Git Bash / WSL:**
```bash
flutter run --debug 2>&1 | grep -i "supabase\|api\|http"
```

### Method 4: Save Logs to File

```bash
# Save all logs
flutter run --debug > app_logs.txt 2>&1

# Save and view simultaneously
flutter run --debug 2>&1 | tee app_logs.txt
```

### Method 5: Use Flutter DevTools

```bash
# Run app
flutter run --debug

# In another terminal, open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Or use the URL shown in flutter run output
```

DevTools provides:
- Network tab for HTTP requests
- Logging tab for all debug prints
- Timeline for performance
- Memory profiler

### Method 6: Android Studio / VS Code

**Android Studio:**
1. Run app in debug mode
2. Open "Run" tab at bottom
3. Filter by "supabase" or "API"

**VS Code:**
1. Run app with F5 or "Run > Start Debugging"
2. View logs in "Debug Console"
3. Use search box to filter logs

### Log Levels

**Verbose (all logs):**
```bash
flutter run --debug --verbose
```

**Only errors:**
```bash
flutter run --debug 2>&1 | findstr /i "error exception failed"
```

**Only API calls:**
```bash
flutter run --debug 2>&1 | findstr /i "supabase http request response"
```

### Example Log Output

With debug mode enabled, you'll see:

```
✅ Supabase initialized: https://mbocotktllisnoskomyo.supabase.co
🔵 API REQUEST ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 POST /auth/v1/signup
📦 Data: {email: user@example.com}
⏰ 2026-05-05T02:18:46.123Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 API RESPONSE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 POST /auth/v1/signup
📊 Status: 200
📦 Response: {user: {...}, session: {...}}
⏰ 2026-05-05T02:18:46.456Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Production Builds

**Important:** API logging is automatically disabled in release builds:

```dart
static const bool _enableLogging = kDebugMode; // Only debug mode
```

Release builds will not show any API logs for performance and security.

## Useful Commands

```bash
# Check Flutter version
flutter --version

# Check connected devices
flutter devices

# Clean build artifacts
flutter clean

# Update dependencies
flutter pub upgrade

# Check outdated packages
flutter pub outdated

# Run app with specific device
flutter run -d emulator-5554

# Build with verbose output
flutter build apk --release --verbose

# Generate icons
flutter pub run flutter_launcher_icons

# Check app size
flutter build apk --analyze-size
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Project AGENTS.md](./AGENTS.md) - Agent guidance
- [Build Scripts Documentation](./BUILD_SCRIPTS.md) - Detailed script usage
