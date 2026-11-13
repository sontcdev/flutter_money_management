# Nghiệm thu icon và splash (emulator thật)

Thiết bị: `emulator-5554` (sdk_gphone64_arm64), 1080x2424. Ảnh chụp bằng `adb exec-out screencap -p`. HEAD `42e32899d68dcb8a97006e59e5e1d911548d7e3b` + working tree chưa commit.

## Cách chạy (cwd = thư mục repo)
1. Entrypoint ngoài `lib/`: `harness/splash_main.dart.txt` (copy ra `$TMPDIR/opencode/icon_emu/splash_main.dart`). Render `SplashView` thật + asset thật `assets/icon/icon.png`, tự đổi sáng/tối mỗi 8 giây. Không `Supabase.initialize`, không network.
2. `flutter build apk --debug --no-pub --target $TMPDIR/opencode/icon_emu/splash_main.dart` → exit 0 (`harness/splash_build.log`).
3. `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk` → Success, exit 0.
4. `am force-stop` → HOME → `monkey -p com.sontc.mymoney -c android.intent.category.LAUNCHER 1` → chụp 0.25s / 3s / 11s.
5. HOME + vuốt lên mở app drawer, chụp.
6. Khôi phục: `flutter build apk --debug --no-pub --target lib/main.dart` → exit 0 (`restore_build.log`); `adb -s emulator-5554 install -r` → Success, exit 0, versionName 1.2.0, lastUpdateTime 2026-11-12 15:56:22. Không chạy app thường (không online).
7. Rotation: không thay đổi. Đọc trước/sau: `accelerometer_rotation=1`, `user_rotation=0`.

## Ảnh (`img/`)
| File | Nội dung |
|---|---|
| `01_native_cold_start_attempt.png` | Cold start ~0.25s: **native splash của Android** (icon trên nền trắng, chưa có spinner/chữ). Đây là native, không phải Flutter |
| `02_flutter_splash_light.png` | `SplashView` Flutter, theme sáng: artwork không méo, spinner + chữ "MyMoney" |
| `03_flutter_splash_dark.png` | `SplashView` Flutter, theme tối |
| `04_launcher_app_drawer.png` | App drawer launcher, icon MyMoney (hàng 7, cột 4). Có icon app khác của emulator |
| `05_launcher_mymoney_icon_crop.png` | Crop 300x300 icon MyMoney từ ảnh 04 (adaptive icon, cắt tròn): artwork cân đối, không méo |

Kích thước: ảnh 01–04 là 1080x2424; ảnh 05 là 300x300 (`sips -c`).

## Tỉ lệ artwork (bbox pixel không-trắng, ngưỡng 40/255; `harness/ratio.py.txt`, kết quả `harness/ratios.txt`)
| File | Canvas | Bbox | Rộng/cao |
|---|---|---|---|
| Baseline `app_icon.png` (gốc) | 1024x687 | 489x384 | **1.273** |
| Baseline `icon.png` (cũ) | 192x192 | 92x107 | **0.860** (méo) |
| Mới `assets/icon/app_icon.png` | 1024x1024 | 489x384 | 1.273 |
| Mới `assets/icon/icon.png` | 192x192 | 92x72 | **1.278** |
| Android `mipmap-xxxhdpi/ic_launcher.png` | 192x192 | 92x72 | 1.278 |
| Android `mipmap-mdpi/ic_launcher.png` | 48x48 | 23x18 | 1.278 |
| Android `drawable-xxxhdpi/ic_launcher_foreground.png` | 432x432 | 207x162 | 1.278 |
| Android `drawable-mdpi/ic_launcher_foreground.png` | 108x108 | 52x41 | 1.268 |
| iOS `Icon-App-1024x1024@1x.png` | 1024x1024 | 489x384 | 1.273 |
| iOS `Icon-App-60x60@3x.png` | 180x180 | 86x68 | 1.265 |

Kết luận: tỉ lệ artwork giữ ~1.27 (sai lệch ≤0.01 do làm tròn pixel ở size nhỏ), so với 0.860 cũ. SHA256: `harness/sha256.txt`.

## Giới hạn
- iOS chỉ kiểm tra file output tĩnh (kích thước, tỉ lệ). Không chạy trên thiết bị/simulator iOS, không khẳng định hiển thị thật.
- Artwork chỉ chiếm ~48% chiều rộng và ~37.5% chiều cao canvas icon (giống tỉ lệ nguồn gốc); icon trông nhỏ trong vòng tròn. Đây là lựa chọn của nguồn, không phải lỗi méo.
- Ảnh tối (03): `icon.png` là ảnh không alpha nền trắng nên hiện khung vuông trắng trên nền tối. Hành vi có sẵn của `SplashView`, không sửa trong phạm vi này.
- Ảnh 01 chụp ở thời điểm ~0.25s nên chỉ là native splash; thời điểm chuyển sang Flutter không được chụp chính xác.
- Splash Flutter dùng harness ngoài, không chạy `AppBootstrap`/Supabase thật.
