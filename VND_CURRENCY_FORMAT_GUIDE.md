# Hướng Dẫn Format Tiền Tệ VND

## Tổng quan
Ứng dụng đã được cập nhật để hỗ trợ định dạng tiền tệ Việt Nam (VND) với các tính năng:
- Format hiển thị: `1.000.000 ₫` (dấu chấm phân cách hàng nghìn)
- Không có số thập phân (VND không sử dụng cent)
- Tự động format khi nhập liệu

## Files mới được tạo

### 1. `lib/src/utils/currency_formatter.dart`
Utility class chính để format tiền tệ với các method:

#### Methods chính:
- `formatVND(double amount)` - Format số tiền thành chuỗi VND
  ```dart
  CurrencyFormatter.formatVND(1000000) // "1.000.000 ₫"
  ```

- `formatVNDFromCents(int cents)` - Format từ cents (lưu trong DB)
  ```dart
  CurrencyFormatter.formatVNDFromCents(100000000) // "1.000.000 ₫"
  ```

- `parseVND(String text)` - Parse chuỗi VND thành số
  ```dart
  CurrencyFormatter.parseVND("1.000.000") // 1000000.0
  ```

- `formatInputVND(String text)` - Format input khi user đang nhập
  ```dart
  CurrencyFormatter.formatInputVND("1000000") // "1.000.000"
  ```

- `toCents(double amount)` - Chuyển đổi số tiền thành cents để lưu DB
  ```dart
  CurrencyFormatter.toCents(1000000.0) // 100000000
  ```

### 2. `lib/src/utils/vnd_input_formatter.dart`
TextInputFormatter tự động format khi user nhập tiền:
```dart
AppInput(
  controller: amountController,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    VNDInputFormatter(), // Tự động thêm dấu chấm phân cách
  ],
)
```

## Các file đã được cập nhật

### UI Screens:
1. ✅ **add_transaction_screen.dart** - Thêm/sửa giao dịch
   - Input field với VND formatter
   - Hiển thị ký hiệu ₫
   - Parse VND khi submit

2. ✅ **budget_edit_screen.dart** - Thêm/sửa ngân sách
   - Input field với VND formatter
   - Format budget limit

3. ✅ **budgets_screen.dart** - Danh sách ngân sách
   - Hiển thị consumed/limit với format VND
   - Hiển thị số tiền còn lại

4. ✅ **home_screen.dart** - Màn hình chính
   - Tổng thu nhập/chi tiêu format VND

5. ✅ **reports_screen.dart** - Báo cáo
   - Tổng thu/chi format VND
   - Top categories format VND

6. ✅ **transaction_detail_screen.dart** - Chi tiết giao dịch
   - Amount format VND

### UI Widgets:
1. ✅ **transaction_item.dart** - Item giao dịch trong list
   - Format amount với VND

2. ✅ **budget_progress.dart** - Progress bar ngân sách
   - Format consumed/limit/remaining với VND

## Cách sử dụng

### Hiển thị tiền từ database:
```dart
// Lấy từ DB (amountCents)
final amountCents = transaction.amountCents; // 100000000

// Hiển thị
Text(CurrencyFormatter.formatVNDFromCents(amountCents)) // "1.000.000 ₫"
```

### Nhập tiền từ user:
```dart
// 1. Setup input field
final amountController = useTextEditingController();

AppInput(
  controller: amountController,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    VNDInputFormatter(), // Auto-format với dấu chấm
  ],
  suffixIcon: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    child: Text('₫', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  ),
)

// 2. Parse khi submit
final amount = CurrencyFormatter.parseVND(amountController.text);
if (amount != null) {
  final amountCents = CurrencyFormatter.toCents(amount);
  // Lưu amountCents vào DB
}
```

### Load dữ liệu để edit:
```dart
// Format amount từ DB để hiển thị trong input
final amount = (budget.limitCents / 100).round();
limitController.text = CurrencyFormatter.formatInputVND(amount.toString());
```

## Format Rules

### VND (Vietnamese Dong):
- Locale: `vi_VN`
- Symbol: `₫`
- Decimal digits: 0 (không có số thập phân)
- Thousand separator: `.` (dấu chấm)
- Example: `1.000.000 ₫`

### USD (nếu cần):
- Locale: `en_US`
- Symbol: `$`
- Decimal digits: 2
- Thousand separator: `,`
- Example: `$1,000.00`

## Testing

Sau khi cập nhật, test các tính năng sau:
1. ✅ Thêm giao dịch mới - input tự động format
2. ✅ Hiển thị danh sách giao dịch - amount hiển thị VND
3. ✅ Thêm/sửa ngân sách - input và display VND
4. ✅ Màn hình home - tổng thu/chi format VND
5. ✅ Reports - tất cả số tiền format VND
6. ✅ Chi tiết giao dịch - amount format VND

## Notes

- Tất cả số tiền trong database vẫn lưu dưới dạng **cents** (int)
- VND format chỉ áp dụng ở tầng UI
- Formatter hỗ trợ multiple currencies (USD, EUR, VND)
- Default currency trong app là **VND**

