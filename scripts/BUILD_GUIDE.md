# Hướng Dẫn Build AAB cho Google Play Store

## Tổng Quan

Hệ thống build tự động này giúp bạn:
- Tự động tăng version number (patch version)
- Build file AAB đã ký sẵn sàng upload lên Google Play Store
- Chạy tất cả bước verify (pub get, gen-l10n, build_runner, analyze)

## Cách Sử Dụng

### Windows
```cmd
build_aab.bat
```

### Linux/Mac
```bash
chmod +x build_aab.sh
./build_aab.sh
```

## Quy Trình Build

Script sẽ tự động thực hiện các bước sau:

1. **Tăng version** - Tự động tăng patch number (ví dụ: 1.0.7 → 1.0.8)
2. **Flutter pub get** - Cài đặt dependencies
3. **Flutter gen-l10n** - Generate localization files
4. **Build runner** - Generate code cho models, Drift, DAOs
5. **Flutter analyze** - Kiểm tra lỗi code
6. **Flutter build appbundle** - Build file AAB release

## File Output

Sau khi build thành công, file AAB sẽ nằm ở:
```
build/app/outputs/bundle/release/app-release.aab
```

File này đã được ký và sẵn sàng upload lên Google Play Console.

## Cấu Trúc Files

```
flutter_money_management/
├── android/
│   ├── app/
│   │   └── upload-keystore.jks      # Signing key (KHÔNG commit lên Git)
│   └── key.properties               # Thông tin keystore (KHÔNG commit lên Git)
├── scripts/
│   ├── increment_version.bat        # Script tăng version (Windows)
│   └── increment_version.sh         # Script tăng version (Linux/Mac)
├── build_aab.bat                    # Script build chính (Windows)
└── build_aab.sh                     # Script build chính (Linux/Mac)
```

## Thông Tin Keystore

**QUAN TRỌNG**: Các file sau đã được thêm vào `.gitignore` và KHÔNG được commit lên Git:
- `android/key.properties`
- `android/app/upload-keystore.jks`

### Thông tin keystore hiện tại:
- **Key alias**: mymoney-key
- **Store file**: android/app/upload-keystore.jks
- **Validity**: 10000 ngày (~27 năm)

### Backup Keystore

**CỰC KỲ QUAN TRỌNG**: Hãy backup file `upload-keystore.jks` ở nơi an toàn!

Nếu mất keystore, bạn sẽ KHÔNG THỂ update app trên Google Play Store nữa.

Khuyến nghị:
- Lưu vào cloud storage (Google Drive, Dropbox, etc.)
- Lưu vào USB/ổ cứng ngoài
- Lưu vào password manager

## Thay Đổi Password Keystore

Nếu muốn đổi password keystore:

### 1. Đổi store password:
```bash
keytool -storepasswd -keystore android/app/upload-keystore.jks
```

### 2. Đổi key password:
```bash
keytool -keypasswd -alias mymoney-key -keystore android/app/upload-keystore.jks
```

### 3. Cập nhật file `android/key.properties`:
```properties
storePassword=<password_mới>
keyPassword=<password_mới>
keyAlias=mymoney-key
storeFile=app/upload-keystore.jks
```

## Quản Lý Version

### Tăng version thủ công

Nếu muốn tăng minor hoặc major version, sửa trực tiếp trong `pubspec.yaml`:

```yaml
version: 1.1.0  # Tăng minor version
version: 2.0.0  # Tăng major version
```

### Format version

Format: `major.minor.patch`
- **Major**: Thay đổi lớn, breaking changes (1.0.0 → 2.0.0)
- **Minor**: Tính năng mới, không breaking (1.0.0 → 1.1.0)
- **Patch**: Bug fixes, cải tiến nhỏ (1.0.0 → 1.0.1)

Script tự động chỉ tăng **patch** version.

## Upload lên Google Play Store

1. Truy cập [Google Play Console](https://play.google.com/console)
2. Chọn app của bạn
3. Vào **Release** → **Production** (hoặc Internal testing/Closed testing)
4. Tạo release mới
5. Upload file `app-release.aab`
6. Điền thông tin release notes
7. Review và publish

## Troubleshooting

### Lỗi: "Keystore file not found"
- Đảm bảo file `android/app/upload-keystore.jks` tồn tại
- Kiểm tra đường dẫn trong `android/key.properties`

### Lỗi: "Failed to read key from keystore"
- Kiểm tra password trong `android/key.properties`
- Đảm bảo key alias đúng

### Lỗi: "Flutter analyze found issues"
- Script sẽ tiếp tục build dù có warning
- Nên fix các issues trước khi upload lên Store

### Build thất bại
- Chạy từng lệnh thủ công để xác định bước nào lỗi:
  ```bash
  flutter pub get
  flutter gen-l10n
  dart run build_runner build --delete-conflicting-outputs
  flutter analyze
  flutter build appbundle --release
  ```

## Lưu Ý Bảo Mật

1. **KHÔNG BAO GIỜ** commit các file sau lên Git:
   - `android/key.properties`
   - `android/app/upload-keystore.jks`
   - Bất kỳ file `.jks` nào

2. **KHÔNG BAO GIỜ** share password keystore công khai

3. Nếu vô tình commit keystore lên Git:
   - Tạo keystore mới ngay lập tức
   - Xóa keystore cũ khỏi Git history
   - Đổi password tất cả các tài khoản liên quan

## Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
- [Flutter Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
