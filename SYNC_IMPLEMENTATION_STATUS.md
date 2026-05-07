# Sync Implementation Status

## ✅ Đã Hoàn Thành

### 1. Local Schema với Workspace Support
- ✅ Thêm `workspace_id` (nullable) vào 3 bảng: `categories`, `transactions`, `budgets`
- ✅ Tăng schema version từ 5 lên 6
- ✅ Migration tự động thêm cột `workspace_id` cho database cũ
- ✅ Code generation hoàn tất (build_runner)

**Files đã sửa:**
- `lib/src/data/local/tables/categories_table.dart:7`
- `lib/src/data/local/tables/transactions_table.dart:7`
- `lib/src/data/local/tables/budgets_table.dart:7`
- `lib/src/data/local/app_database.dart:32` (schema version)
- `lib/src/data/local/app_database.dart:86-93` (migration logic)

### 2. Inbound Sync (Remote → Local)
- ✅ `CloudToLocalSyncService` đã cập nhật để lưu `workspace_id` vào local
- ✅ Pull categories, transactions, budgets theo `workspace_id`
- ✅ Upsert vào local database với đầy đủ metadata
- ✅ Schema mapping đúng: `icon`, `color`, `transaction_date`, `limit_cents`

**Files đã sửa:**
- `lib/src/services/cloud_to_local_sync_service.dart:41-145`

### 3. Outbound Sync (Local → Remote)
- ✅ `SupabaseSyncService` đã cập nhật để gửi `workspace_id` lên cloud
- ✅ Payload sync bao gồm đầy đủ: `workspace_id`, `created_at`, `updated_at`, `deleted_at`
- ✅ Schema mapping chuẩn hóa theo Supabase migration

**Files đã sửa:**
- `lib/src/services/sync/supabase_sync_service.dart:21-112`

### 4. Providers
- ✅ Tạo `supabaseSyncServiceProvider`
- ✅ `cloudToLocalSyncServiceProvider` đã có sẵn
- ✅ Flow login/splash đã gọi hydrate sau authentication

**Files đã sửa:**
- `lib/src/providers/providers.dart:46-52`

### 5. Verification
- ✅ Build runner chạy thành công
- ✅ Flutter analyze: chỉ còn 12 warnings (không có error)
- ✅ App có thể compile

## ⚠️ Chưa Hoàn Thành (Cần Làm Tiếp)

### 1. Gọi Outbound Sync Từ Repository
**Vấn đề:** Khi user tạo/sửa/xóa category/budget/transaction, dữ liệu chỉ lưu local, chưa được push lên Supabase.

**Cần làm:**
- Sau mỗi `createCategory()`, `createBudget()`, `createTransaction()` trong repository
- Gọi `SupabaseSyncService` để push lên cloud
- Cần truyền `workspace_id` từ `activeWorkspaceIdProvider`

**Files cần sửa:**
- `lib/src/data/repositories/category_repository.dart:34-42`
- `lib/src/data/repositories/budget_repository.dart:49-68`
- `lib/src/data/repositories/transaction_repository.dart:36-57`

**Ví dụ code cần thêm:**
```dart
// Trong CategoryRepository.createCategory()
Future<Category> createCategory(Category category) async {
  final id = category.id.isEmpty ? _uuid.v4() : category.id;
  final categoryWithId = category.copyWith(id: id);
  
  final companion = _modelToCompanion(categoryWithId);
  await _db.categoryDao.insertCategory(companion);
  
  // ⚠️ CẦN THÊM: Push to cloud
  try {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId != null) {
      final syncService = ref.read(supabaseSyncServiceProvider);
      await syncService.syncCategory(categoryWithId, workspaceId);
    }
  } catch (e) {
    debugPrint('Failed to sync category to cloud: $e');
    // Continue - local data is saved
  }
  
  return getCategoryById(categoryWithId.id);
}
```

### 2. Lưu workspace_id Khi Tạo Dữ Liệu Mới
**Vấn đề:** Khi tạo category/budget/transaction mới, cần lưu `workspace_id` vào local record.

**Cần làm:**
- Lấy `activeWorkspaceId` từ provider
- Lưu vào local database khi insert
- Đảm bảo companion object có `workspaceId: Value(workspaceId)`

**Files cần sửa:**
- `lib/src/data/repositories/category_repository.dart:71-81`
- `lib/src/data/repositories/budget_repository.dart:110-124`
- `lib/src/data/repositories/transaction_repository.dart:120-135`

### 3. Sync Khi App Resume
**Mục đích:** Mỗi lần mở lại app, tự động pull dữ liệu mới từ cloud.

**Cần làm:**
- Thêm `WidgetsBindingObserver` vào `AppBootstrap` hoặc `HomeScreen`
- Khi `AppLifecycleState.resumed`, gọi `CloudToLocalSyncService.hydrateWorkspaceData()`
- Thêm guard: `isSyncing`, `lastSyncAt`, cooldown 15-30 giây

**File cần tạo/sửa:**
- `lib/src/services/app_lifecycle_sync_manager.dart` (mới)
- `lib/src/app_bootstrap.dart` hoặc `lib/src/ui/screens/home_screen.dart`

### 4. Chuẩn Hóa Pull-to-Refresh
**Mục đích:** Khi user kéo refresh, trigger cloud sync trước khi invalidate provider.

**Cần làm:**
- Tạo helper method chung: `syncAndRefresh()`
- Cập nhật các màn đã có `RefreshIndicator`:
  - `DashboardScreen`
  - `TodayScreen`
  - `TransactionsScreen`
  - `BudgetsScreen`
  - `ReportCalendarScreen`
- Thêm `RefreshIndicator` cho:
  - `CategoriesScreen`
  - `ReportsScreen`
  - `WorkspaceSelectionScreen`

**Ví dụ helper:**
```dart
Future<void> syncAndRefresh(WidgetRef ref) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId != null) {
    final syncService = ref.read(cloudToLocalSyncServiceProvider);
    await syncService.hydrateWorkspaceData(workspaceId);
  }
  
  ref.invalidate(categoriesProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(budgetsProvider);
  ref.invalidate(budgetsWithConsumedProvider);
}
```

### 5. Filter Dữ Liệu Theo Workspace (Optional - Nâng Cao)
**Mục đích:** Khi có nhiều workspace, chỉ hiển thị dữ liệu của workspace active.

**Cần làm:**
- Cập nhật DAO queries để filter theo `workspace_id`
- Cập nhật providers để truyền `activeWorkspaceId`
- Đảm bảo chuyển workspace không bị trộn dữ liệu

**Lưu ý:** Vì `workspace_id` là nullable, có thể làm sau khi sync cơ bản hoạt động.

## 🧪 Kịch Bản Test

### Test 1: Uninstall/Reinstall Flow (Quan Trọng Nhất)
```
1. Login app
2. Tạo 1 category
3. Tạo 1 budget
4. Tạo 1 transaction
5. Kiểm tra Supabase dashboard:
   - Có 3 records trong categories/budgets/transactions?
   - Có workspace_id đúng không?
6. Gỡ app
7. Cài lại app
8. Login lại
9. ✅ Dữ liệu phải hiển thị đầy đủ
```

### Test 2: App Resume Sync
```
1. Mở app
2. Đưa app xuống background
3. Từ thiết bị khác hoặc web, thêm dữ liệu mới
4. Quay lại app
5. ✅ Sau vài giây, dữ liệu mới phải xuất hiện
```

### Test 3: Pull-to-Refresh
```
1. Mở màn Transactions/Budgets/Categories
2. Kéo xuống để refresh
3. ✅ Dữ liệu mới từ cloud phải load về
```

## 📋 Checklist Triển Khai Tiếp

### Ưu Tiên Cao (Bắt Buộc)
- [ ] Gọi `SupabaseSyncService` từ repository sau create/update/delete
- [ ] Lưu `workspace_id` vào local khi tạo dữ liệu mới
- [ ] Test flow uninstall/reinstall

### Ưu Tiên Trung Bình
- [ ] Thêm sync khi app resume
- [ ] Chuẩn hóa pull-to-refresh cho các màn chính
- [ ] Thêm error handling và logging rõ ràng

### Ưu Tiên Thấp (Nâng Cao)
- [ ] Filter DAO queries theo workspace_id
- [ ] Implement sync queue processor đầy đủ
- [ ] Thêm "Last synced at" trong Settings
- [ ] Offline queue với retry logic

## 🔍 Debug Tips

### Kiểm tra dữ liệu có lên Supabase không:
```sql
-- Trong Supabase SQL Editor
SELECT * FROM categories WHERE workspace_id = 'your-workspace-id';
SELECT * FROM transactions WHERE workspace_id = 'your-workspace-id';
SELECT * FROM budgets WHERE workspace_id = 'your-workspace-id';
```

### Kiểm tra local database:
```dart
// Thêm debug log trong repository
debugPrint('Creating category with workspace_id: $workspaceId');
```

### Kiểm tra sync errors:
```dart
// Trong CloudToLocalSyncService
catch (e) {
  debugPrint('Sync error: $e');
  debugPrint('Workspace ID: $workspaceId');
  rethrow;
}
```

## 📝 Notes

- Schema Supabase giả định theo migration code: `icon`, `color`, `transaction_date`, `limit_cents`
- Nếu schema thực tế khác, cần điều chỉnh field names trong sync services
- `workspace_id` là nullable để tương thích với dữ liệu cũ
- Outbound sync hiện chưa được gọi tự động - đây là nguyên nhân chính của bug "mất dữ liệu sau reinstall"
