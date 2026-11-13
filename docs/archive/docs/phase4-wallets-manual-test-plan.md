# Phase 4 — Plan kiểm tra tay: Ví & Chuyển khoản

Phạm vi: 3 hạng mục chưa verify của Phase 4 — **dải ví trên màn Hôm nay**,
**luồng chuyển khoản**, **light/dark theme**.

## 0. Chuẩn bị

```bash
flutter analyze          # phải "No issues found!"
flutter test             # 25/25 pass
flutter run -d emulator-5554 --debug
```

- DB đã chạy `01_create_schema.sql` → `02_add_wallets.sql` (kèm `notify pgrst`).
- Dữ liệu thử: `supabase/03_seed_demo_data.sql` (5 ví: Tiền mặt, Vietcombank,
  Ví MoMo, Thẻ tín dụng số dư **âm**, Tiết kiệm).
- Ghi lại tổng thu / tổng chi của chu kỳ hiện tại trên màn Hôm nay **trước khi test** —
  dùng làm mốc so sánh ở mục 2.

## 1. Dải ví trên màn Hôm nay

| # | Bước | Kỳ vọng |
|---|---|---|
| 1.1 | Mở màn Hôm nay | Dải card ví cuộn ngang nằm dưới hero balance |
| 1.2 | Cuộn ngang hết dải | Đủ 5 ví, không tràn/cắt chữ, tên dài bị ellipsis chứ không xuống dòng vỡ layout |
| 1.3 | Đối chiếu số dư từng ví | Bằng `opening + Σthu − Σchi + Σchuyển_đến − Σchuyển_đi` (chạy SELECT verify ở cuối `03_seed_demo_data.sql`) |
| 1.4 | Ví Thẻ tín dụng | Hiển thị số dư **âm**, đúng định dạng VND, màu cảnh báo/đỏ |
| 1.5 | Tap 1 card ví | Điều hướng sang `/wallets` |
| 1.6 | Workspace chỉ có 1 ví | Dải vẫn hiện, không crash |
| 1.7 | Kéo pull-to-refresh | Số dư cập nhật lại, không nháy lỗi |

## 2. Luồng chuyển khoản (trọng tâm)

| # | Bước | Kỳ vọng |
|---|---|---|
| 2.1 | Thêm giao dịch → chọn segment "Chuyển khoản" | Khối chọn **danh mục biến mất**; hiện "Từ ví" → "Đến ví" |
| 2.2 | Để trống ví đích rồi Lưu | Báo lỗi validate, không gọi API |
| 2.3 | Chọn Từ ví = Đến ví | Bị chặn, thông báo 2 ví phải khác nhau |
| 2.4 | Chuyển 500.000₫ Vietcombank → Tiền mặt, Lưu | Lưu thành công, quay về danh sách |
| 2.5 | Xem lại dải ví | Vietcombank **−500.000**, Tiền mặt **+500.000**, tổng tài sản **không đổi** |
| 2.6 | Xem tổng thu / tổng chi màn Hôm nay | **Bằng đúng mốc ghi ở mục 0** — chuyển khoản không tính vào thu/chi |
| 2.7 | Mở màn Ngân sách | Phần "đã tiêu" **không đổi** sau giao dịch chuyển khoản |
| 2.8 | Mở Báo cáo (biểu đồ tròn + lịch) | Không có lát/điểm nào cho giao dịch chuyển khoản |
| 2.9 | Danh sách giao dịch | Dòng transfer hiện `Ví A → Ví B`, màu **trung tính** (không đỏ/xanh) |
| 2.10 | Mở chi tiết giao dịch transfer | Hiện đủ 2 ví, không có danh mục, không crash |
| 2.11 | Sửa transfer: đổi ví đích sang Ví MoMo | Số dư 3 ví cập nhật đúng (hoàn lại ví cũ, trừ/cộng ví mới) |
| 2.12 | Xoá transfer vừa tạo | Số dư 2 ví trở lại giá trị trước 2.4 |
| 2.13 | Thêm khoản **chi** từ Ví MoMo | Chỉ MoMo giảm; tổng chi tăng đúng số tiền |
| 2.14 | Xoá ví đang có giao dịch | Bị chặn, gợi ý archive thay vì xoá |
| 2.15 | Archive 1 ví | Biến mất khỏi picker & dải ví, giao dịch cũ vẫn còn |
| 2.16 | Đổi ví mặc định | Form thêm giao dịch mở lên chọn sẵn ví mới |
| 2.17 | Tắt mạng rồi lưu transfer | Báo lỗi rõ ràng, không mất dữ liệu form |

## 3. Light / Dark theme

Lặp lại **mục 1 và các bước 2.1, 2.9, 2.10** ở cả 2 theme (Settings → Giao diện).

| # | Điểm kiểm | Kỳ vọng |
|---|---|---|
| 3.1 | Dải card ví | Chữ đọc được, contrast đủ, viền card không biến mất trên nền tối |
| 3.2 | Số dư âm (Thẻ tín dụng) | Màu đỏ vẫn phân biệt được trên nền tối |
| 3.3 | Bottom sheet chọn ví | Nền sheet đúng theme, item đang chọn nổi rõ |
| 3.4 | Màn Ví + màn sửa ví | Icon picker / color swatch không bị chìm nền |
| 3.5 | Segment "Chuyển khoản" | Trạng thái selected/unselected phân biệt được ở cả 2 theme |
| 3.6 | Đổi theme khi đang mở màn Ví | Đổi tức thì, không phải restart |

## 4. Hồi quy nhanh (khu vực vừa sửa)

- Splash: mở app → chỉ thấy **một** màn splash có icon app, không chớp 2 lần.
- Màn Hôm nay → tap thẻ "Nhắc việc sắp tới" → mở `/recurring-transactions`.
- Biểu đồ tròn Báo cáo: không tràn viền trên máy hẹp, lát < 5% không hiện nhãn.

## 5. Ghi nhận kết quả

Với mỗi mục FAIL, ghi: bước, kỳ vọng, thực tế, screenshot, và log `flutter run`
quanh thời điểm lỗi. Ưu tiên sửa theo thứ tự: 2.5–2.8 (sai số liệu) >
2.2–2.3 (validate) > 3.x (thẩm mỹ).
