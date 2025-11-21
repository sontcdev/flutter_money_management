# Tóm Tắt Triển Khai Chức Năng Hũ Chi Tiêu

## Ngày: 21/11/2025

## Các Thay Đổi Đã Thực Hiện

### 1. Models & Database
- ✅ **SpendJar Model** (`lib/src/models/spend_jar.dart`)
  - Các trường: id, name, balanceCents, iconName, colorValue, createdAt, updatedAt
  
- ✅ **Category Model** - Cập nhật để thêm `jarId` (nullable)
  - Một danh mục có thể được gắn với một hũ chi tiêu

- ✅ **SpendJars Table** (`lib/src/data/local/tables/spend_jars_table.dart`)
  - Bảng database để lưu trữ thông tin hũ chi tiêu

### 2. Data Access Layer
- ✅ **SpendJarDao** (`lib/src/data/local/daos/spend_jar_dao.dart`)
  - CRUD operations
  - `decreaseBalance()` - Giảm số dư hũ
  - `increaseBalance()` - Tăng số dư hũ
  - `isSpendJarInUse()` - Kiểm tra hũ có đang được sử dụng không

- ✅ **SpendJarRepository** (`lib/src/data/repositories/spend_jar_repository.dart`)
  - Chuyển đổi giữa entity và model
  - Xử lý logic nghiệp vụ
  - Exception handling khi xóa hũ đang được sử dụng

### 3. Business Logic
- ✅ **Transaction Repository** - Cập nhật để xử lý số dư hũ
  - `createTransaction()`: Tự động giảm số dư hũ khi tạo giao dịch chi tiêu với danh mục có liên kết hũ
  - `updateTransaction()`: Hoàn trả số dư hũ cũ và áp dụng số dư hũ mới
  - `deleteTransaction()`: Hoàn trả số dư hũ khi xóa giao dịch chi tiêu

### 4. UI Screens
- ✅ **SpendJarsScreen** (`lib/src/ui/screens/spend_jars_screen.dart`)
  - Hiển thị danh sách hũ chi tiêu
  - Xóa hũ với xác nhận
  - Refresh sau khi thêm/sửa/xóa
  - Empty state khi chưa có hũ

- ✅ **SpendJarEditScreen** (`lib/src/ui/screens/spend_jar_edit_screen.dart`)
  - Thêm/sửa hũ chi tiêu
  - Chọn icon emoji
  - Chọn màu sắc
  - Nhập số dư (VNĐ)

- ✅ **CategoryEditScreen** - Cập nhật để thêm dropdown chọn hũ
  - Dropdown hiển thị danh sách hũ chi tiêu
  - Option "Không gắn hũ"
  - Hiển thị icon và tên hũ

### 5. UI Components
- ✅ **CategoryItem Widget** - Cập nhật để hiển thị thông tin hũ
  - Hiển thị emoji icon thay vì Material icon
  - Hiển thị tên hũ chi tiêu (nếu có) ở subtitle
  - Icon savings nhỏ bên cạnh tên hũ

### 6. Providers
- ✅ **spendJarRepositoryProvider**
- ✅ **spendJarsProvider** - FutureProvider để load danh sách hũ
- ✅ **spendJarProvider** - Family provider để load hũ theo ID

### 7. Routing
- ✅ **AppRouter** - Thêm routes
  - `/spend-jars` → SpendJarsScreen
  - `/spend-jar-edit` → SpendJarEditScreen (với optional SpendJar argument)

### 8. Navigation
- ✅ **HomeScreen** - Thêm nút "Hũ Chi Tiêu" trong Quick Actions

## Luồng Hoạt Động

### Khi Tạo Giao Dịch Chi Tiêu:
1. User chọn category có liên kết với hũ chi tiêu
2. Tạo transaction
3. System tự động giảm số dư hũ tương ứng với số tiền giao dịch

### Khi Sửa Giao Dịch:
1. System hoàn trả số dư hũ của category cũ (nếu có)
2. Áp dụng giảm số dư hũ của category mới (nếu có)

### Khi Xóa Giao Dịch:
1. System hoàn trả số dư hũ (nếu là giao dịch chi tiêu với category có liên kết hũ)

## Đặc Điểm Chính

### 1. Tính Toàn Vẹn Dữ Liệu
- Không thể xóa hũ đang được gắn với category
- Transaction được wrap trong database transaction để đảm bảo ACID

### 2. User Experience
- Refresh tự động sau mọi thao tác
- Empty state với hướng dẫn rõ ràng
- Confirmation dialog khi xóa
- Loading states
- Error handling với snackbar

### 3. Tích Hợp
- Hoàn toàn tích hợp với hệ thống category và transaction hiện có
- Không làm ảnh hưởng đến các chức năng khác
- Backward compatible (jarId nullable)

## Cấu Trúc Database

```
spend_jars
├── id (PK, auto increment)
├── name (text)
├── balance_cents (integer)
├── icon_name (text)
├── color_value (integer)
├── created_at (datetime)
└── updated_at (datetime)

categories
├── id (PK)
├── name (text)
├── icon_name (text)
├── color_value (integer)
├── jar_id (FK → spend_jars.id, nullable)
├── created_at (datetime)
└── updated_at (datetime)
```

## Testing

### Manual Testing Checklist:
- [ ] Tạo hũ chi tiêu mới
- [ ] Sửa hũ chi tiêu
- [ ] Xóa hũ chi tiêu (không có category liên kết)
- [ ] Thử xóa hũ có category liên kết (phải báo lỗi)
- [ ] Gắn hũ vào category
- [ ] Tạo giao dịch chi tiêu với category có hũ (kiểm tra số dư hũ giảm)
- [ ] Sửa giao dịch (đổi category) - kiểm tra số dư hũ cũ/mới
- [ ] Xóa giao dịch chi tiêu - kiểm tra số dư hũ tăng lại
- [ ] Kiểm tra hiển thị tên hũ trong danh sách category

## Notes
- Số tiền được lưu dưới dạng cents (x100) để tránh lỗi floating point
- Icon sử dụng emoji thay vì Material Icons để dễ customize
- Màu sắc được lưu dưới dạng integer (Color.value)

