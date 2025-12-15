# MoneyWise - Ứng dụng Quản lý Tài chính Cá nhân 💰

<p align="center">
  <img src="assets/icon/app_icon.png" alt="MoneyWise Logo" width="120" height="120">
</p>

<p align="center">
  <strong>Quản lý chi tiêu thông minh, ngân sách rõ ràng, tài chính minh bạch</strong>
</p>

<p align="center">
  <a href="#tính-năng">Tính năng</a> •
  <a href="#yêu-cầu-hệ-thống">Yêu cầu</a> •
  <a href="#cài-đặt">Cài đặt</a> •
  <a href="#build-app">Build</a> •
  <a href="#công-nghệ">Công nghệ</a>
</p>

---

## 📱 Giới thiệu

**MoneyWise** là ứng dụng quản lý tài chính cá nhân hiện đại, giúp bạn:
- 📊 Theo dõi thu chi hàng ngày dễ dàng
- 💼 Quản lý ngân sách theo danh mục
- 📈 Xem báo cáo chi tiết và trực quan
- 📅 Lịch giao dịch theo tháng
- 🌍 Hỗ trợ đa ngôn ngữ (Tiếng Việt, English)
- 🎨 Giao diện đẹp mắt, dễ sử dụng

---

## ✨ Tính năng

### 🎯 Quản lý Giao dịch
- ➕ Thêm giao dịch thu/chi nhanh chóng
- ✏️ Sửa/xóa giao dịch dễ dàng
- 🏷️ Phân loại theo danh mục
- 📸 Đính kèm hóa đơn/chứng từ
- 📝 Ghi chú chi tiết

### 💼 Quản lý Ngân sách
- 🎯 Đặt ngân sách theo danh mục
- ⏰ Chu kỳ linh hoạt: Tháng, Năm, Tùy chỉnh
- 📊 Theo dõi tiến độ chi tiêu real-time
- ⚠️ Cảnh báo khi vượt ngân sách
- 📈 Lịch sử ngân sách

### 📊 Báo cáo & Thống kê
- 📅 Lịch giao dịch theo tháng
- 💹 Biểu đồ thu/chi trực quan
- 📈 Phân tích theo danh mục
- 🎯 Báo cáo ngân sách chi tiết
- 📊 Tổng quan tài chính

### 🎨 Tùy chỉnh
- 🏷️ Tạo danh mục riêng với icon và màu sắc
- 🌙 Dark mode / Light mode
- 🌍 Đa ngôn ngữ: Tiếng Việt, English
- 🎨 Chọn màu chủ đề yêu thích

### 💾 Dữ liệu
- 🗄️ Lưu trữ local với SQLite (Drift)
- 🔒 An toàn và bảo mật
- ⚡ Hiệu suất cao
- 📱 Offline-first

---

## 🛠️ Công nghệ

### Framework & Ngôn ngữ
- **Flutter** 3.27+ - Cross-platform UI framework
- **Dart** 3.6+ - Programming language

### State Management & Architecture
- **Riverpod** 2.6.1 - State management
- **Flutter Hooks** 0.20.5 - React-like hooks
- **Freezed** 2.5.8 - Code generation for models

### Database
- **Drift** 2.28.2 - Type-safe SQLite wrapper
- **SQLite** - Local database

### UI & Design
- **Material Design 3** - Modern UI components
- **Custom Theme System** - Professional design
- **Responsive Layout** - Adaptive UI

### Localization
- **flutter_localizations** - Multi-language support
- **intl** - Internationalization

### Utilities
- **Image Picker** 1.1.2 - Camera & gallery
- **File Picker** 8.3.7 - File selection
- **Package Info Plus** 8.3.1 - App info
- **Shared Preferences** 2.5.3 - Settings storage

### Development Tools
- **Build Runner** 2.5.4 - Code generation
- **Flutter Lints** 3.0.2 - Code quality
- **JSON Serializable** 6.9.5 - JSON serialization

---

## 📋 Yêu cầu Hệ thống

### Để phát triển (Development)
- **Flutter SDK:** 3.27.0 hoặc cao hơn
- **Dart SDK:** 3.6.0 hoặc cao hơn
- **IDE:** 
  - Android Studio 2024+ hoặc
  - Visual Studio Code với Flutter extension hoặc
  - IntelliJ IDEA
- **Git:** Để clone repository

### Để build Android
- **Android SDK:** API 21+ (Android 5.0+)
- **Java JDK:** 17 hoặc cao hơn
- **Android Studio:** Bản mới nhất
- **Gradle:** 8.0+

### Để build iOS
- **macOS:** 12.0+ (Monterey hoặc mới hơn)
- **Xcode:** 15.0+
- **CocoaPods:** Bản mới nhất
- **iOS Deployment Target:** 12.0+

### Thiết bị test
- **Android:** Android 5.0 (API 21) trở lên
- **iOS:** iOS 12.0 trở lên
- **Emulator/Simulator** hoặc thiết bị thật

---

## 🚀 Cài đặt

### 1️⃣ Cài đặt Flutter

#### macOS
```bash
# Tải Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Thêm vào ~/.zshrc hoặc ~/.bash_profile
echo 'export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"' >> ~/.zshrc

# Kiểm tra
flutter doctor
```

#### Windows
```bash
# Download Flutter từ: https://docs.flutter.dev/get-started/install/windows
# Giải nén và thêm vào PATH

# Kiểm tra
flutter doctor
```

#### Linux
```bash
# Tải Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Thêm vào ~/.bashrc
echo 'export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"' >> ~/.bashrc

# Kiểm tra
flutter doctor
```

### 2️⃣ Cài đặt Dependencies

#### Android
```bash
# Install Android Studio
# Download từ: https://developer.android.com/studio

# Cài đặt Android SDK
# Trong Android Studio: Tools > SDK Manager
# Chọn Android SDK Platform 21+

# Chấp nhận licenses
flutter doctor --android-licenses
```

#### iOS (macOS only)
```bash
# Install Xcode
# Download từ App Store

# Cài đặt Xcode Command Line Tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Install CocoaPods
sudo gem install cocoapods
```

### 3️⃣ Clone Project

```bash
# Clone repository
git clone <repository-url>
cd flutter_money_management

# Kiểm tra Flutter
flutter doctor -v
```

### 4️⃣ Install Dependencies

```bash
# Get Flutter packages
flutter pub get

# Generate code (cho Drift, Freezed, JSON Serializable)
dart run build_runner build --delete-conflicting-outputs

# Hoặc watch mode (tự động generate khi có thay đổi)
dart run build_runner watch --delete-conflicting-outputs
```

### 5️⃣ Kiểm tra thiết bị

```bash
# Liệt kê thiết bị có sẵn
flutter devices

# Kết quả mẫu:
# Found 3 connected devices:
#   iPhone 15 Pro (mobile) • <id> • ios
#   Android SDK (mobile)   • <id> • android-x64
#   Chrome (web)           • chrome • web-javascript
```

---

## 🏗️ Build App

### 🤖 Android

#### Debug Build (Phát triển)
```bash
# Build APK debug
flutter build apk --debug

# Hoặc run trực tiếp
flutter run
```

#### Release Build (Production)

##### Tạo Keystore (lần đầu)
```bash
# Tạo keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Nhập thông tin:
# - Password: <your-password>
# - Name: <your-name>
# - Organization: <your-org>
```

##### Cấu hình Signing
```bash
# Tạo file android/key.properties
cat > android/key.properties << EOF
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=/Users/<username>/upload-keystore.jks
EOF
```

##### Build APK Release
```bash
# Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

##### Build App Bundle (Cho Google Play)
```bash
# Build AAB
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Install APK
```bash
# Install vào thiết bị
flutter install
# Hoặc
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

### 🍎 iOS

#### Debug Build
```bash
# Build debug
flutter build ios --debug

# Hoặc run trực tiếp
flutter run -d ios
```

#### Release Build

##### Mở Xcode workspace
```bash
open ios/Runner.xcworkspace
```

##### Cấu hình trong Xcode:
1. **Signing & Capabilities**
   - Select Team
   - Bundle Identifier: `com.sontc.financeapp`
   - Signing Certificate

2. **Build Settings**
   - Deployment Target: iOS 12.0+
   - Architecture: ARM64

##### Build từ Command Line
```bash
# Build iOS
flutter build ios --release

# Archive
flutter build ipa --release

# Output: build/ios/ipa/MoneyWise.ipa
```

##### Build từ Xcode
1. Select `Product > Archive`
2. Chọn Archive vừa tạo
3. Click `Distribute App`
4. Chọn phương thức distribution:
   - **App Store Connect** - Upload lên App Store
   - **Ad Hoc** - Test trên thiết bị registered
   - **Development** - Test local
   - **Enterprise** - Enterprise distribution

---

## 🧪 Testing

### Run Tests
```bash
# Run all tests
flutter test

# Run specific test
flutter test test/budget_service_test.dart

# Run with coverage
flutter test --coverage
```

### Integration Tests
```bash
# Run integration tests
flutter test integration_test/
```

---

## 🎨 Development

### Hot Reload
```bash
# Run app
flutter run

# Trong terminal:
# Press 'r' - Hot reload
# Press 'R' - Hot restart
# Press 'h' - Help
# Press 'q' - Quit
```

### Code Generation
```bash
# Generate một lần
dart run build_runner build --delete-conflicting-outputs

# Watch mode (tự động generate)
dart run build_runner watch --delete-conflicting-outputs
```

### Clean Build
```bash
# Clean
flutter clean

# Get packages
flutter pub get

# Build
flutter run
```

### Analyze Code
```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Fix common issues
dart fix --apply
```

---

## 📁 Cấu trúc Project

```
flutter_money_management/
├── android/                 # Android native code
├── ios/                     # iOS native code
├── lib/
│   ├── l10n/               # Localization files
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_vi.dart
│   ├── src/
│   │   ├── data/           # Data layer
│   │   │   ├── local/      # Local database (Drift)
│   │   │   └── repositories/
│   │   ├── models/         # Data models (Freezed)
│   │   ├── providers/      # Riverpod providers
│   │   ├── services/       # Business logic
│   │   ├── theme/          # App theme
│   │   │   ├── app_colors.dart
│   │   │   └── app_theme.dart
│   │   ├── ui/             # UI layer
│   │   │   ├── screens/    # App screens
│   │   │   └── widgets/    # Reusable widgets
│   │   ├── utils/          # Utilities
│   │   └── app.dart        # Main app widget
│   └── main.dart           # Entry point
├── test/                   # Unit tests
├── assets/                 # Assets (images, icons)
├── pubspec.yaml           # Dependencies
└── README.md              # This file
```

---

## 🔧 Troubleshooting

### Flutter doctor issues
```bash
# Chạy flutter doctor
flutter doctor -v

# Fix Android licenses
flutter doctor --android-licenses

# Fix iOS issues
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Build errors
```bash
# Clean project
flutter clean
rm -rf build/
rm -rf .dart_tool/

# Delete generated files
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete

# Rebuild
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### iOS pod install errors
```bash
cd ios
rm -rf Pods/
rm Podfile.lock
pod install --repo-update
cd ..
flutter run
```

### Gradle issues
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 🌟 Features Roadmap

### Hiện tại (v1.0.0)
- ✅ Quản lý giao dịch thu/chi
- ✅ Quản lý ngân sách
- ✅ Báo cáo và thống kê
- ✅ Lịch giao dịch
- ✅ Đa ngôn ngữ (VI/EN)
- ✅ Dark/Light mode
- ✅ Offline-first

### Tương lai (v1.1+)
- 🔄 Đồng bộ cloud
- 📊 Biểu đồ nâng cao
- 🔔 Thông báo nhắc nhở
- 📤 Export/Import dữ liệu (CSV, Excel)
- 💳 Quản lý nhiều tài khoản
- 🔐 Bảo mật bằng PIN/FaceID
- 🌐 Web version
- 📱 Widget cho home screen

---

## 📄 License

This project is proprietary software. All rights reserved.

---

## 👤 Author

**Trinh Cong Son**
- Package: `com.sontc.financeapp`
- Version: 1.0.0+1

---

## 📞 Support

Nếu bạn gặp vấn đề hoặc có câu hỏi:
1. Kiểm tra [Troubleshooting](#troubleshooting)
2. Chạy `flutter doctor -v` để kiểm tra môi trường
3. Xem logs: `flutter run --verbose`

---

## 🎉 Acknowledgments

- **Flutter Team** - Amazing framework
- **Riverpod** - Excellent state management
- **Drift** - Type-safe SQLite
- **Community** - Open source packages

---

<p align="center">
  Made with ❤️ using Flutter
</p>

<p align="center">
  <strong>MoneyWise - Quản lý tài chính thông minh</strong>
</p>

