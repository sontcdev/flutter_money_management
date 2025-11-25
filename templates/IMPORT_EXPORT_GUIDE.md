# Hướng dẫn Import/Export Giao dịch

## Tổng quan

Tính năng Import/Export cho phép bạn:
- **Export**: Xuất tất cả giao dịch ra file CSV hoặc JSON để sao lưu
- **Import**: Nhập giao dịch từ file CSV hoặc JSON vào ứng dụng

## Các trường dữ liệu

| Trường | Mô tả | Bắt buộc | Ví dụ |
|--------|-------|----------|-------|
| `date` | Ngày giao dịch (dd/MM/yyyy) | ✅ | 25/11/2024 |
| `type` | Loại giao dịch | ✅ | income hoặc expense |
| `amount` | Số tiền (VND, số nguyên) | ✅ | 50000 |
| `category` | Tên danh mục | ✅ | Ăn uống |
| `note` | Ghi chú | ❌ | Ăn sáng |

## Định dạng CSV

### Cấu trúc
```csv
date,type,amount,category,note
25/11/2024,expense,50000,Ăn uống,Ăn sáng phở
25/11/2024,income,15000000,Lương,Lương tháng 11
```

### Lưu ý
- Dòng đầu tiên phải là header
- Các trường cách nhau bằng dấu phẩy
- Nếu ghi chú có dấu phẩy, đặt trong dấu ngoặc kép: `"Ăn sáng, trưa"`
- Số tiền không có dấu phân cách (50000, không phải 50,000 hay 50.000)

## Định dạng JSON

### Cấu trúc
```json
{
  "exportDate": "2024-11-25T10:00:00.000",
  "version": "1.0",
  "transactions": [
    {
      "date": "25/11/2024",
      "type": "expense",
      "amount": 50000,
      "category": "Ăn uống",
      "note": "Ăn sáng phở"
    },
    {
      "date": "25/11/2024",
      "type": "income",
      "amount": 15000000,
      "category": "Lương",
      "note": "Lương tháng 11"
    }
  ]
}
```

### Lưu ý
- `amount` là số nguyên (không phải chuỗi)
- `type` chỉ có 2 giá trị: `income` hoặc `expense`
- `note` có thể để trống `""`

## Xử lý Danh mục

Khi import:
- Nếu danh mục đã tồn tại → Sử dụng danh mục đó
- Nếu danh mục chưa tồn tại → Tự động tạo mới với:
  - Icon mặc định dựa trên tên danh mục
  - Màu mặc định dựa trên tên danh mục

### Ánh xạ Icon tự động
| Từ khóa trong tên | Icon |
|-------------------|------|
| ăn, food, eat | 🍔 |
| di chuyển, xăng, transport | 🚗 |
| lương, salary, income | 💰 |
| mua sắm, shopping | 🛍️ |
| giải trí, entertainment | 🎮 |
| sức khỏe, health | 🏥 |
| Khác | 📦 |

## Cách sử dụng

### Export
1. Vào **Cài đặt** → **Import / Export**
2. Chọn **Export CSV** hoặc **Export JSON**
3. File được lưu và có thể copy nội dung

### Import
1. Vào **Cài đặt** → **Import / Export**
2. Chọn **Import CSV** hoặc **Import JSON**
3. Dán nội dung file vào ô nhập liệu
4. Nhấn **Import**

### Lấy Template
1. Vào **Cài đặt** → **Import / Export**
2. Chọn **Template CSV** hoặc **Template JSON**
3. Nội dung template được copy vào clipboard

## Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách khắc phục |
|-----|-------------|----------------|
| "Thiếu trường dữ liệu" | Thiếu cột trong CSV | Đảm bảo đủ 4-5 cột |
| "Lỗi định dạng" | Ngày sai format | Dùng đúng dd/MM/yyyy |
| "Số tiền không hợp lệ" | Có dấu phân cách | Bỏ dấu chấm/phẩy trong số |

## File Template

Xem các file mẫu trong thư mục `templates/`:
- `template_transactions.csv`
- `template_transactions.json`
