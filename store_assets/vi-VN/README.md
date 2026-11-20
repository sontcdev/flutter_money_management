# Money Tracker — Google Play, tiếng Việt

- `short-description.txt`: mô tả ngắn, 69 ký tự (giới hạn 80).
- `full-description.txt`: mô tả đầy đủ, 1.698 ký tự (giới hạn 4.000).
- `icon-512.png`: icon 512 × 512.
- `feature-graphic-1024x500.png`: feature graphic 1024 × 500.
- `phone/01.png` đến `06.png`: ảnh điện thoại 1080 × 1920, upload theo thứ tự số.
- `preview.png`: xem nhanh; không upload ảnh này vào listing.

## Nguồn và giới hạn

Ảnh giao diện được lấy từ bộ acceptance screenshot có sẵn trong repo, dùng dữ liệu mẫu và provider giả. Nguồn từng ảnh nằm trong `source/sources.json`. Đây không phải ảnh chụp mới từ AAB 1.0.0. Cần đối chiếu giao diện với release trước khi gửi review. Không có ảnh AI dựng lại giao diện. Icon dùng `assets/icon/app_icon.png` hiện có.

Tên trên artwork là Money Tracker theo yêu cầu. Tên hiển thị trong app và trang privacy vẫn cần kiểm tra sự thống nhất trước khi phát hành. Không có cam kết Google sẽ duyệt app hoặc tên mới.

Ảnh đã được mở kiểm tra bố cục; kích thước và giới hạn mô tả đã được kiểm tra tự động.

Thông số: https://support.google.com/googleplay/android-developer/answer/9866151?hl=en

## Render lại trong checkout này

`node store_assets/vi-VN/source/render.cjs`

Script dùng Playwright đã có trên máy ở `/Volumes/sontc/sources/Tools/dashboard-flow/node_modules/playwright`. Đổi đường dẫn require nếu máy khác; không có thay đổi dependency của app.

## Bổ sung tablet 7 inch và 10 inch

- `tablet-7/`: 4 ảnh 1200 × 1920, viewport Flutter 600 × 960 dp, DPR 2.
- `tablet-10/`: 4 ảnh 1600 × 2560, viewport Flutter 800 × 1280 dp, DPR 2.
- Thứ tự upload: `home.png`, `txlist.png`, `report_calendar.png`, `cats.png`.
- `tablet-preview.png` chỉ để xem nhanh, không upload.

Ảnh tablet được render mới bằng widget hiện tại qua Flutter widget test, dữ liệu mẫu từ harness acceptance. Không kéo giãn ảnh phone, không gọi Supabase và không dùng dữ liệu người dùng thật. Font Roboto được load cho môi trường test; title dùng cùng kích thước và weight, với font Roboto tường minh để tránh Ahem. MaterialIcons và font avatar Sora được load riêng. Đây là viewport mô phỏng theo nhóm kích thước, không phải ảnh chụp tablet vật lý hay AAB đang chạy trên Android.

Nguồn tái hiện: `source/tablet_capture.dart.txt`. Copy vào `test/store_tablet_capture_test.dart`, chuẩn bị `/tmp/store-Sora-Bold.ttf` từ URL Google Fonts trong log/Google Fonts Sora, rồi chạy `flutter test test/store_tablet_capture_test.dart`. Đường dẫn Flutter SDK/font hiện tại nằm trong harness, cần đổi nếu máy khác. Kết quả: 8/8 capture test pass, không có Flutter exception hoặc overflow; đã mở contact sheet kiểm tra cả 8 ảnh.
