# Build Guide

`scripts/` hiện chỉ giữ 2 script build Android:

- `scripts/build_play_store_aab.sh`: build AAB release để upload Google Play
- `scripts/build_release_apk.sh`: build APK release

## Cách dùng

```bash
chmod +x scripts/build_play_store_aab.sh scripts/build_release_apk.sh
./scripts/build_play_store_aab.sh
./scripts/build_release_apk.sh
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
