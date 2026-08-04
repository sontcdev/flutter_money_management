# Test Plan — Workspace

Phạm vi: mọi hành vi phụ thuộc `activeWorkspaceIdProvider` và `role` của user trong
workspace đang chọn (`owner` / `admin` / `member`).

Nguồn sự thật:
- Quyền phía client: `lib/src/features/workspace/providers/workspace_providers.dart`
  (`workspaceRoleProvider`, `canManageWorkspaceProvider`, `canManageWorkspaceContentProvider`,
  `canLeaveWorkspaceProvider`, `isWorkspaceOwnerProvider`).
- Quyền phía server: RLS + `public.can_manage_workspace()` / `public.is_workspace_member()`
  trong `supabase/01_create_schema.sql`.
- Đồng bộ khi đổi workspace: `workspace_sync_helper.dart` → `invalidateCoreDataProviders()`.

---

## 1. Ma trận quyền (cần đúng ở CẢ client và server)

| Hành động | owner | admin | member |
|---|---|---|---|
| Xem transactions / categories / budgets / wallets / recurring | ✅ | ✅ | ✅ |
| Tạo / sửa / xoá transaction | ✅ | ✅ | ❌ |
| Tạo / sửa / xoá category | ✅ | ✅ | ❌ |
| Tạo / sửa / xoá budget | ✅ | ✅ | ❌ |
| Tạo / sửa / xoá / archive wallet, đặt ví mặc định | ✅ | ✅ | ❌ |
| Mời thành viên, đổi role, gỡ thành viên | ✅ | ✅ | ❌ |
| Đổi tên / xoá workspace | ✅ | ❌ | ❌ |
| Rời workspace | ❌ | ✅ | ✅ |

**Nguyên tắc kiểm thử:** mỗi ô ❌ phải fail ở **hai lớp** — UI ẩn/disable nút, *và*
gọi thẳng repository vẫn bị Postgres từ chối. Chỉ test lớp UI là chưa đủ.

## 2. Cô lập dữ liệu giữa các workspace (ưu tiên cao nhất)

Setup: user A thuộc workspace W1 và W2, mỗi workspace có data riêng.

- W1 → W2: danh sách transaction, category, budget, wallet, recurring đổi hoàn toàn,
  không sót item của W1 (kiểm tra cả sau pull-to-refresh).
- Report / calendar / biểu đồ tròn tính lại theo W2 (`report_providers.dart` có luồng
  invalidate riêng — phải kiểm tra tách biệt).
- Số dư ví (`walletBalancesProvider`) và tổng tài sản chỉ cộng ví của workspace hiện tại.
- Budget "đã tiêu" không lẫn transaction của workspace khác.
- Notification / activity log chỉ hiện của workspace hiện tại.
- Thử truy cập trực tiếp bằng id chéo workspace (ví dụ `/transaction-detail` với id của
  W1 khi đang ở W2) → phải trả về "không tìm thấy", không được lộ dữ liệu.

## 3. Vòng đời workspace

- Tạo workspace mới → tự động seed category mặc định + ví mặc định, và được chọn làm active.
- Đổi tên workspace → phản ánh ở switcher, settings, workspace detail.
- Xoá workspace đang active → app chuyển sang workspace khác, không rơi vào màn trắng /
  lỗi "No active workspace selected".
- User chỉ có 1 workspace → không cho rời / xoá workspace cuối cùng.
- Owner rời workspace → bị chặn (phải chuyển quyền owner trước).

## 4. Mời & thành viên

- Tạo link mời → mở `/workspace-invite-preview` bằng token hợp lệ → xem trước đúng tên workspace.
- Token hết hạn / đã dùng / sai định dạng → thông báo lỗi rõ ràng, không crash.
- Chấp nhận lời mời khi chưa đăng nhập → sau khi đăng nhập vẫn vào đúng workspace.
- User đã là thành viên bấm lại link mời → không tạo bản ghi trùng.
- Hạ role admin → member khi user đó **đang mở app**: UI phải khoá quyền sau lần refresh
  kế tiếp, và mọi ghi dữ liệu bị server chặn ngay.
- Gỡ thành viên khi user đó đang mở workspace → user bị đưa về màn chọn workspace.

## 5. Trạng thái biên

- `activeWorkspaceIdProvider == null` (vừa đăng nhập, chưa chọn): mọi repository dùng
  `_requireWorkspaceId` phải hiện lỗi/empty state thân thiện, không văng exception thô
  ra màn hình. Đây là màn hình dễ vỡ nhất — test riêng cho **wallets, transactions,
  budgets, categories, recurring**.
- Mất mạng khi đang đổi workspace → giữ nguyên workspace cũ, có thể retry.
- Kill app rồi mở lại → khôi phục đúng workspace đã chọn.
- Đăng xuất rồi đăng nhập tài khoản khác → không còn dấu vết workspace của tài khoản cũ.

## 6. Test tự động nên bổ sung (`test/`)

Hiện `test/` chưa có test nào cho workspace. Đề xuất, theo thứ tự ưu tiên:

1. `test/workspace_permission_test.dart` — unit test thuần cho các provider quyền:
   override `activeWorkspaceProvider` với từng role, assert đúng ma trận ở mục 1.
   Rẻ, nhanh, chặn được hầu hết lỗi hồi quy về quyền.
2. `test/workspace_scoped_repository_test.dart` — với `WalletRepository` /
   `CategoryRepository` bằng Supabase client giả: assert mọi query đều kèm
   `.eq('workspace_id', ...)` và ném lỗi khi workspace id null.
3. `test/workspace_switch_invalidation_test.dart` — đổi `activeWorkspaceIdProvider`,
   assert `invalidateCoreDataProviders` làm các provider fetch lại (đếm số lần gọi).
4. `test/wallets_screen_test.dart` — widget test: role `member` không thấy nút thêm/xoá ví;
   role `admin` thì thấy.
5. Test RLS phía DB (chạy tay bằng `psql` với 2 JWT khác nhau): user của W1 select
   `wallets` của W2 trả về 0 dòng. Không tự động hoá được trong `flutter test`.

## 7. Quy trình chạy

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage
```

Chuẩn bị dữ liệu thử: `supabase/03_seed_demo_data.sql`.
