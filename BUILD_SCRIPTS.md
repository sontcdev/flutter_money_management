# Build & Install Scripts

Automated scripts for building and installing the Flutter app.

## Available Scripts

### 1. Full Interactive Build (`build_and_install.bat` / `build_and_install.ps1`)

**Features:**
- Interactive prompts for all options
- Clean build option
- Code analysis before build
- Support for Android/iOS/Auto-detect
- Device selection

**Usage:**
```bash
# Windows Command Prompt
build_and_install.bat

# PowerShell
.\build_and_install.ps1
```

**Steps:**
1. Select build mode (Debug/Profile/Release)
2. Select platform (Android/iOS/Auto-detect)
3. Choose whether to clean previous builds
4. Optionally select specific device
5. Script handles: dependencies, localization, code generation, analysis, build, and install

### 2. Quick Build (`quick_build.bat` / `quick_build.ps1`)

**Features:**
- No prompts - uses defaults
- Fast execution
- Command-line arguments
- Perfect for development workflow

**Usage:**
```bash
# Default: debug mode, auto-detect device
quick_build.bat

# Specify mode
quick_build.bat debug
quick_build.bat profile
quick_build.bat release

# Specify mode and device
quick_build.bat debug emulator-5554
quick_build.bat release 192.168.1.100:5555

# PowerShell
.\quick_build.ps1
.\quick_build.ps1 debug
.\quick_build.ps1 release emulator-5554
```

**What it does:**
1. Gets dependencies (silent)
2. Generates localization (silent)
3. Runs code generation (silent)
4. Builds and installs app

## Common Scenarios

### Development (fastest)
```bash
quick_build.bat
# or
quick_build.bat debug emulator-5554
```

### Testing Performance
```bash
quick_build.bat profile
```

### Release Build
```bash
quick_build.bat release
```

### Full Clean Build
```bash
build_and_install.bat
# Then select: Clean = Yes
```

## Device IDs

Find your device ID:
```bash
flutter devices
```

Common device IDs:
- Android Emulator: `emulator-5554`, `emulator-5556`, etc.
- Physical Android: `<serial-number>` (e.g., `RF8M12345AB`)
- iOS Simulator: `<uuid>` (e.g., `A1B2C3D4-E5F6-...`)
- Physical iOS: `<uuid>`
- Wireless Android: `<ip>:5555` (e.g., `192.168.1.100:5555`)

## Troubleshooting

### Script won't run (PowerShell)
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Flutter not found
Add Flutter to PATH:
```bash
# Check current PATH
echo %PATH%

# Add Flutter (example)
setx PATH "%PATH%;C:\flutter\bin"
```

### Build fails
Try full clean build:
```bash
flutter clean
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Device not detected
```bash
# Android
adb devices
adb kill-server
adb start-server

# iOS
xcrun simctl list devices
```

## Script Comparison

| Feature | Full Interactive | Quick Build |
|---------|-----------------|-------------|
| Prompts | Yes | No |
| Clean option | Yes | No |
| Code analysis | Yes | No |
| Speed | Slower | Faster |
| Best for | First build, troubleshooting | Daily development |
| Arguments | No | Yes |

## Tips

1. **Daily development**: Use `quick_build.bat` for speed
2. **Before commit**: Use `build_and_install.bat` with analysis
3. **CI/CD simulation**: Use full interactive with clean + analysis
4. **Multiple devices**: Specify device ID to avoid ambiguity
5. **Wireless debugging**: Connect via `adb connect <ip>:5555` first

## Examples

```bash
# Quick debug build to specific emulator
quick_build.bat debug emulator-5554

# Quick release build
quick_build.bat release

# Full interactive with all checks
build_and_install.bat

# PowerShell quick build
.\quick_build.ps1 debug

# PowerShell with device
.\quick_build.ps1 profile emulator-5554
```
