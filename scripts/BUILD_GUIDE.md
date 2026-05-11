# Build Guide

`scripts/` hiện giữ 2 script build Android, mỗi script có cả bản shell và batch cho Windows:

- `scripts/build_play_store_aab.sh`: build AAB release để upload Google Play
- `scripts/build_release_apk.sh`: build APK release
- `scripts/build_play_store_aab.bat`: bản Windows của script build AAB release
- `scripts/build_release_apk.bat`: bản Windows của script build APK release

## Cách dùng

```bash
chmod +x scripts/build_play_store_aab.sh scripts/build_release_apk.sh
./scripts/build_play_store_aab.sh
./scripts/build_release_apk.sh
```

Windows Command Prompt:

```bat
scripts\build_play_store_aab.bat
scripts\build_release_apk.bat
```

## Những gì script sẽ chạy

1. `flutter pub get`
2. `flutter gen-l10n`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter analyze`
5. `flutter test --coverage`
6. Build artifact release tương ứng

## Output

Play Store AAB:
`build/app/outputs/bundle/release/app-release.aab`

Release APK:
`build/app/outputs/flutter-apk/app-release.apk`

## Lưu ý

1. Script không tự tăng version. Cập nhật version thủ công trong `pubspec.yaml` trước khi build nếu cần.
2. Để build ký release thành công, cần cấu hình signing Android hợp lệ.
3. Nếu `flutter analyze` hoặc `flutter test` fail, script sẽ dừng ngay để tránh tạo artifact từ trạng thái lỗi.
