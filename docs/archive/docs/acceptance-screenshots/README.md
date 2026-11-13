# Ảnh nghiệm thu UI (emulator thật, dữ liệu mock)

Ảnh chụp bằng `adb exec-out screencap -p` trên emulator Android thật. Không phải ảnh widget-test.

## Bản chất mock
- Widget thật của app, nhưng dữ liệu là **fake providers** (Riverpod overrides). Không có `Supabase.initialize`, không có network.
- `SharedPreferences` chạy in-memory (`setMockInitialValues`), không đụng dữ liệu thật của app.
- Entrypoint mock nằm ngoài `lib/`: bản lưu để tái hiện là `harness/emu_main.dart.txt` (đuôi `.txt` để không bị compile hay test discovery). Dữ liệu (số dư, ngân sách "Không xác định", "Household") chỉ là dữ liệu giả.

## Metadata
- Thiết bị: `emulator-5554`, màn hình 1080x2424 (phone), text scale 1.3 (qua `MediaQuery`).
- Portrait: ảnh 01–16. Landscape: ảnh 17–19 (`user_rotation 1`).
- Nguồn: HEAD `42e32899d68dcb8a97006e59e5e1d911548d7e3b` + working tree có thay đổi chưa commit. Version `1.2.0+7`. SHA1 các file chính: `harness/source_sha1.txt`.

## Danh sách ảnh (`img/`)
| File | Màn hình | Ngôn ngữ | Theme |
|---|---|---|---|
| 01 / 02 | Home | vi | sáng / tối |
| 03 / 04 | Settings | vi / en | sáng / tối |
| 05 / 06 | Budgets | vi | sáng / tối |
| 07 / 08 | Add Transaction | en / vi | sáng / tối |
| 09 / 10 | Report Calendar | vi / en | sáng / tối |
| 11 / 12 | Recurring | vi / en | sáng / tối |
| 13 / 14 | Reports (chart đủ dữ liệu) | en | sáng / tối |
| 15 | Home | ja | sáng |
| 16 | Reports | ja | tối |
| 17 / 18 | Report Calendar landscape: đầu trang / tuần cuối | vi | sáng |
| 19 | Add Transaction landscape | en | tối |

Contact sheet: `contact_sheet_a.png` (ảnh 01–08), `contact_sheet_b.png` (ảnh 09–19).

## Lệnh đã chạy
```
flutter build apk --debug --no-pub --target <TMPDIR>/opencode/emu/emu_main.dart
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell settings put system accelerometer_rotation 0; adb shell settings put system user_rotation 0   # landscape: user_rotation 1
echo "<scenario>,<locale>,<dark 0|1>,1.3" | adb shell "run-as com.sontc.mymoney sh -c 'cat > files/emu_cfg.txt'"; sleep 3
adb exec-out screencap -p > img/<file>.png
adb shell input touchscreen swipe 1200 640 1200 300 500   # x2, cuộn tới tuần cuối (landscape)
```
Scenario: `home, settings, budgets, add_transaction, report_calendar, recurring, reports`.
Sau khi chụp: reset `user_rotation 0`, `accelerometer_rotation 1` (đúng giá trị ban đầu) và build/cài lại APK `lib/main.dart`.
`adb logcat` sau khi chụp: 0 dòng `overflowed / EXCEPTION CAUGHT / RenderFlex`.

## Quan sát / hạn chế
- Ảnh 08 (vi, tối, scale 1.3): nhãn "Chuyển khoản" trong toggle bị xuống 2 dòng.
- Ảnh 16 (ja): nhãn trục Y của chart bị chồng ở đầu trục ("1260/1200万" xuống dòng).
- Ảnh 18: ở landscape, hàng tổng "Thu nhập / Chi tiêu / Ròng" bị cắt sát mép dưới vùng cuộn lịch (tuần cuối 26–31 hiển thị đầy đủ).
- Ảnh 01/02/15: FAB che một phần empty state "Thông báo" (cosmetic).
- Chỉ phone, không có tablet / thiết bị thật. Đồng hồ status bar là giờ emulator.
- Số liệu mock có thể không nhất quán hoàn toàn giữa các màn hình.

## Mở rộng độ phủ (img/20–53)

Ảnh chụp trên emulator thật (`emulator-5554`, 1080x2424) bằng harness mock `harness/emu_main_v2.dart.txt`. Harness không gọi `Supabase.initialize`, override toàn bộ dependency, không có network và không ghi dữ liệu thật. Cấu hình scenario, locale, dark mode đổi lúc runtime (textscale 1.3). Ảnh gốc `img/01–19` được giữ nguyên.

| Họ màn hình | Ảnh |
|---|---|
| Transactions list / detail | 20–23 |
| Wallets list / edit | 24–27 |
| Categories list / edit | 28–31 |
| Workspace selection / management | 32–35 |
| Auth: sign in, sign up, forgot, reset code, reset password | 36–42 |
| Dialog xóa tài khoản | 43–44 |
| Reports ja dark sau khi sửa `chart_widget.dart` | 45 |
| Home trống, CTA nằm trên FAB (vi light/dark) | 46–47 |
| Calendar landscape, thấy đủ SummaryBar và tuần cuối 26–31 | 48 (cuộn hết), 49 (giữa) |
| Landscape: sign in, workspace management, wallets, transactions | 50–53 |

Contact sheet: `contact_sheet_c.png` (portrait 20–47), `contact_sheet_d_landscape.png` (landscape 48–53).

Giới hạn của mock:
- Dữ liệu giả. Dialog đăng xuất và unsaved-changes chưa được chụp (chỉ có dialog xóa tài khoản). Dialog không được xác nhận nên không gọi service.
- Landscape chỉ có 6 ảnh đại diện, chưa phủ đủ mọi họ.
- Chưa chụp đủ ma trận vi/en/ja x light/dark cho từng họ. Mỗi họ có 1–2 tổ hợp.

Quan sát (không sửa source trong nhiệm vụ này):
- Wallets (24, 25): tên ví bị cắt ("Househo…", "Ngân hà…") ở textscale 1.3 vì số dư và icon xóa chung hàng.
- Workspace management (34, 35): nhãn tab bị cắt ("Pending i", "Lời mời đ").
- Dialog xóa tài khoản ja (44): gợi ý nhập `DELETE` bị cắt.
- Chart ja (45): nhãn trục, tick tháng 6月–11月 không còn chồng lấn.

Source sha1 khi chụp: xem `harness/source_sha1_v2.txt`.

## Bổ sung 54–58: dialog đăng xuất và bỏ thay đổi (textscale 1.3)

Ảnh gốc 2424x1080 (landscape) hoặc 1080x2424 (portrait), emulator thật, harness mock `harness/emu_main_v3.dart.txt` (không `Supabase.initialize`, không mạng, không ghi prod).

- `54_dialog_unsaved_vi_light.png`: dialog "Bỏ thay đổi?" (vi, sáng).
- `55_dialog_unsaved_ja_dark.png`: dialog "変更を破棄しますか？" (ja, tối).
- `56_dialog_logout_vi_light.png`: dialog "Đăng xuất" (vi, sáng).
- `57_dialog_logout_ja_dark.png`: dialog "サインアウト" (ja, tối).
- `58_dialog_unsaved_landscape_vi_light.png`: dialog bỏ thay đổi, landscape (vi, sáng).
- `contact_sheet_e_dialogs.png`: tổng hợp 54–57.

Cách kích hoạt: dialog đăng xuất mở bằng cách chạm nút "Đăng xuất" thật trên màn hình Settings thật (nút xác nhận KHÔNG được chạm, không gọi signOut). Dialog bỏ thay đổi dùng `UnsavedChangesGuard(isDirty: true)` thật, kích hoạt bằng `Navigator.maybePop()`; không xác nhận "Bỏ". Dialog đăng xuất landscape chưa chụp.

## Ảnh 59–64: Workspace Management (mock harness v3, build v5)

Màn hình thật `WorkspaceManagementScreen`, textscale 1.3, emulator 1080x2424, không có overflow trong logcat (0 khớp).

- `img/59_wsmgmt_vi_dark_tabs_start.png`: vi, dark, tab đầu (Lời mời đang chờ (2)).
- `img/60_wsmgmt_vi_dark_tabs_end.png`: vi, dark, tab cuộn tới tab cuối "Lời mời đã thu hồi (0)".
- `img/61_wsmgmt_vi_dark_invites.png`: thẻ lời mời thật ("Khẩn cấp / Hết hạn hôm nay", "Sắp hết hạn / Hết hạn sau 2 ngày"), danh sách thành viên.
- `img/62_wsmgmt_en_light_tabs_start.png`, `63_..._tabs_end.png` (tab cuối "Revoked invites (0)"), `64_..._invites.png`: en, light.

Source sha1 (lúc build và lúc kết thúc): `workspace_management_screen.dart` 2d4b78b1db6ed9b389e891a4b6fabf1216814f1c; `app_status_chip.dart` 1d378cac08e4ceb820c9b6fe5ecfb1636df54444 (xem `harness/source_sha1_v5.txt`, `harness/build_v5.log`).
Giới hạn: dữ liệu mock, không bấm hành động xác nhận/phá hủy (menu lời mời, xóa thành viên, rời workspace).

## Ảnh 65–92: tinh chỉnh UX (harness v4, build v6)

- Thiết bị: emulator-5554 (1080x2424), textscale 1.3, mock harness `harness/emu_main_v4.dart.txt` (widget thật, fake provider, không `Supabase.initialize`, không mạng). Chuyển kịch bản qua `files/emu_cfg.txt`.
- Baseline: HEAD `42e32899d68dcb8a97006e59e5e1d911548d7e3b`, 114 dòng `git status` ở đầu và cuối. Hash source lúc build: `harness/source_sha1_v6.txt`; lúc kết thúc: `harness/source_sha1_v6_end.txt` (diff: giống hệt).
- Ảnh 01–64 không đổi. Mỗi ảnh được xem full-res; capture chỉ khi cửa sổ `com.sontc.mymoney` đang focus (trước và sau screencap).

| Ảnh | Nội dung |
|---|---|
| 65–68 | Ví tên dài + tổng số dư; menu ví (vi sáng / en tối), chỉ mở menu, không xác nhận xoá |
| 69–72 | Danh mục; menu danh mục (vi sáng / en tối) |
| 73–74 | Giao dịch nhóm theo ngày, tiêu đề ngày chỉ xuất hiện một lần |
| 75–76 | Home lần đầu, CTA dạng outlined (sáng/tối) |
| 77–84 | Workspace: Members → Invite → Pending invites → Settings → Danger zone (vi sáng, en tối); 79≡80 và 83≡84 (cùng md5, cuối vùng cuộn) |
| 85–89 | 5 màn auth dọc: signin, signup, forgot, resetcode, reset |
| 90–92 | Auth ngang có bàn phím mở: signin, signup, reset (field đã focus, không submit) |

- Xoay màn hình: gốc `user_rotation=0`, `accelerometer_rotation=1`; sau chụp ngang đã khôi phục đúng hai giá trị này (đọc lại: 0 và 1).
- Logcat: không có `RenderFlex overflowed`.
- Hạn chế: mock data cố định; chưa kiểm backend/auth thật, tablet, thiết bị thật.
- Khôi phục APK thường: `flutter build apk --debug --no-pub --target lib/main.dart` (cwd repo, exit 0) rồi `adb -s emulator-5554 install -r` (Success, exit 0, versionName 1.2.0, lastUpdateTime 2026-11-11 18:17:02). Không chạy app thường. File `files/emu_cfg.txt` còn lại trong dữ liệu app (app thường không đọc).

## Kết quả review cuối
- **Cập nhật revision UX:** ảnh 65–92 đã được reviewer mở từng ảnh gốc và đánh giá PASS trong các trạng thái mock đại diện. Ví/category, ngày giao dịch, CTA Home, thứ tự workspace và bố cục auth đạt yêu cầu đã duyệt. Ảnh 79/80 và 83/84 trùng nhau, không tăng phạm vi kiểm tra.
- Source tương ứng được đối chiếu với manifest: 58 hash khớp. Bản source mới nhất analyze sạch, **1.058 test pass**, `git diff --check` pass. Các số liệu 970 test bên dưới là lịch sử trước revision UX.
- Auth ngang có bàn phím được chụp ở ảnh 90–92. Ảnh không tự chứng minh mọi control cuộn tới được; khả năng cuộn có thêm bằng chứng widget test và source review. Chưa nghiệm thu backend, thiết bị thật hoặc mọi tổ hợp locale/theme.
- **PASS trong phạm vi các trạng thái mock đại diện đã review**, không phải nghiệm thu mọi luồng của toàn app.
- Reviewer đã mở từng ảnh gốc 20–53, 54–58 và 59–64. Không còn lỗi chặn trong các trạng thái mới đã kiểm tra.
- Ảnh 16 giữ lỗi chart tiếng Nhật cũ; dùng ảnh 45 để đánh giá bản sửa. Ảnh 34/35 giữ lỗi tab workspace cũ; dùng ảnh 59–64 để đánh giá bản sửa.
- Ảnh 46/47 xác nhận khoảng trống Home; ảnh 48 xác nhận đủ tuần cuối và hàng tổng lịch ngang.
- Bản source cuối: analyze sạch; 970 test pass; `git diff --check` pass. Các kết quả này không thay thế review ảnh.
- Chưa xác minh backend/auth, dữ liệu production, tablet, thiết bị thật, bàn phím mở hoặc mọi tổ hợp locale/theme. Không xác nhận số đo contrast mới chỉ từ ảnh.
