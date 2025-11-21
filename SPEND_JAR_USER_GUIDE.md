# 🏺 Hướng Dẫn Sử Dụng Chức Năng Hũ Chi Tiêu

## 📖 Giới thiệu

Chức năng Hũ Chi Tiêu giúp bạn quản lý ngân sách theo từng mục đích cụ thể. Mỗi hũ đại diện cho một "túi tiền" dành riêng cho một nhóm chi tiêu nhất định.

---

## 🚀 Bắt Đầu

### 1. Tạo Hũ Chi Tiêu

1. Từ màn hình Home, nhấn vào nút **"Hũ Chi Tiêu"**
2. Nhấn nút **"+"** ở góc dưới bên phải
3. Điền thông tin:
   - **Tên hũ**: Ví dụ "Ăn uống", "Đi lại", "Giải trí"
   - **Số dư**: Số tiền bạn dự định dành cho hũ này (VNĐ)
   - **Icon**: Chọn biểu tượng đại diện
   - **Màu sắc**: Chọn màu để dễ phân biệt
4. Nhấn **"Thêm Hũ"**

### 2. Gắn Hũ vào Danh Mục

1. Vào **Categories** từ màn hình Home
2. Chọn một danh mục có sẵn hoặc tạo mới
3. Trong màn hình sửa danh mục, kéo xuống phần **"Hũ Chi Tiêu"**
4. Chọn hũ từ dropdown (hoặc chọn "Không gắn hũ")
5. Nhấn **"Lưu"**

### 3. Tạo Giao Dịch

1. Nhấn nút **"+"** ở màn hình Home
2. Chọn loại: **Chi tiêu** (Expense)
3. Chọn **Danh mục** đã gắn với hũ
4. Nhập số tiền và các thông tin khác
5. Nhấn **"Lưu"**

**💡 Kết quả**: Số dư trong hũ sẽ tự động giảm theo số tiền giao dịch!

---

## 📊 Ví dụ Thực Tế

### Tình huống: Quản lý chi tiêu ăn uống

1. **Tạo hũ "Ăn Uống"**
   - Tên: Ăn Uống
   - Số dư: 5,000,000 VNĐ (ngân sách tháng này)
   - Icon: 🍔
   - Màu: Cam

2. **Gắn danh mục vào hũ**
   - Category "Ăn sáng" → Gắn với hũ "Ăn Uống"
   - Category "Ăn trưa" → Gắn với hũ "Ăn Uống"
   - Category "Ăn tối" → Gắn với hũ "Ăn Uống"

3. **Tạo giao dịch**
   - Ngày 1: Ăn sáng - 50,000 VNĐ
   - Ngày 1: Ăn trưa - 80,000 VNĐ
   - Ngày 1: Ăn tối - 100,000 VNĐ

4. **Kết quả**
   - Số dư hũ: 5,000,000 - 230,000 = **4,770,000 VNĐ**
   - Bạn còn lại 4,770,000 VNĐ cho chi tiêu ăn uống trong tháng!

---

## 💡 Các Trường Hợp Sử Dụng

### 1. Quản lý ngân sách theo mục đích

```
Hũ "Sinh Hoạt" (10M VNĐ)
├── Ăn uống
├── Đi lại
└── Mua sắm

Hũ "Giải Trí" (2M VNĐ)
├── Xem phim
├── Game
└── Du lịch

Hũ "Y Tế" (3M VNĐ)
├── Khám bệnh
└── Mua thuốc
```

### 2. Tiết kiệm cho mục tiêu cụ thể

```
Hũ "Mua Laptop" (20M VNĐ)
└── Lương tháng → Chuyển vào hũ

Hũ "Du Lịch Hè" (15M VNĐ)
└── Tiết kiệm mỗi tháng
```

### 3. Chia sẻ chi tiêu gia đình

```
Hũ "Con Cái" (5M VNĐ)
├── Học phí
├── Sách vở
└── Quần áo

Hũ "Nhà Cửa" (8M VNĐ)
├── Điện nước
├── Internet
└── Sửa chữa
```

---

## ⚙️ Các Tính Năng

### ✅ Đã Hoàn Thành

- **Tạo/Sửa/Xóa hũ chi tiêu**
- **Gắn một danh mục với một hũ**
- **Tự động giảm số dư hũ khi chi tiêu**
- **Hoàn trả số dư khi sửa/xóa giao dịch**
- **Hiển thị tên hũ trong danh sách category**
- **Không thể xóa hũ đang được sử dụng**

### 🔜 Có Thể Phát Triển Thêm

- Thống kê chi tiêu theo hũ
- Cảnh báo khi hũ sắp hết
- Chuyển tiền giữa các hũ
- Đặt mục tiêu cho từng hũ
- Biểu đồ chi tiêu theo hũ

---

## ❓ Câu Hỏi Thường Gặp

### 1. Một danh mục có thể gắn với nhiều hũ không?

❌ Không. Một danh mục chỉ có thể gắn với **một hũ duy nhất**. Điều này giúp việc quản lý rõ ràng hơn.

### 2. Phải gắn tất cả danh mục với hũ không?

❌ Không bắt buộc. Bạn có thể để một số danh mục không gắn với hũ nào cả.

### 3. Số dư hũ có thể âm không?

✅ Có. Khi bạn chi tiêu vượt quá số dư hũ, số dư sẽ trở thành âm để bạn biết đã chi vượt ngân sách.

### 4. Giao dịch thu nhập có ảnh hưởng đến hũ không?

❌ Không. Chỉ có **giao dịch chi tiêu** (expense) mới ảnh hưởng đến số dư hũ.

### 5. Nếu sửa giao dịch và đổi sang category khác thì sao?

✅ Hệ thống sẽ tự động:
1. Hoàn trả số tiền cho hũ của category cũ
2. Trừ số tiền từ hũ của category mới

### 6. Nếu xóa một giao dịch thì sao?

✅ Số tiền sẽ được **hoàn trả** vào hũ tương ứng.

### 7. Tôi có thể xóa hũ không?

⚠️ Có, nhưng chỉ khi:
- Hũ chưa được gắn với bất kỳ category nào
- Nếu hũ đang được sử dụng, bạn phải gỡ liên kết với các category trước

---

## 🎯 Tips & Tricks

### 1. Đặt tên hũ rõ ràng
❌ "Hũ 1", "Hũ 2"
✅ "Ăn Uống", "Đi Lại", "Giải Trí"

### 2. Sử dụng màu sắc phân biệt
- 🔴 Đỏ: Chi tiêu cố định (điện nước, nhà)
- 🟠 Cam: Ăn uống
- 🟢 Xanh: Tiết kiệm
- 🔵 Xanh dương: Giải trí

### 3. Tạo hũ theo chu kỳ
- Hũ theo tháng: "Tháng 11/2025"
- Hũ theo mục đích: "Du lịch hè 2026"
- Hũ theo người: "Chi tiêu của Anh", "Chi tiêu của Em"

### 4. Review định kỳ
- Cuối tuần: Kiểm tra số dư các hũ
- Cuối tháng: Đánh giá xem hũ nào chi vượt/thừa
- Điều chỉnh ngân sách cho tháng tiếp theo

---

## 🛠️ Troubleshooting

### Vấn đề: Không thể xóa hũ

**Nguyên nhân**: Hũ đang được gắn với một hoặc nhiều category

**Giải pháp**:
1. Vào **Categories**
2. Tìm các category có gắn hũ này (có icon 💰 và tên hũ)
3. Sửa từng category, chọn "Không gắn hũ"
4. Quay lại và xóa hũ

### Vấn đề: Số dư hũ không đúng

**Nguyên nhân**: Có thể đã sửa/xóa giao dịch trước đó

**Giải pháp**:
1. Kiểm tra lại lịch sử giao dịch
2. Xác nhận các giao dịch có sử dụng đúng category
3. Nếu cần, sửa số dư hũ thủ công

### Vấn đề: Muốn thay đổi category sang hũ khác

**Giải pháp**:
1. Vào **Categories**
2. Chọn category cần đổi
3. Chọn hũ mới từ dropdown
4. Lưu lại

**⚠️ Lưu ý**: Chỉ có giao dịch MỚI mới ảnh hưởng đến hũ mới. Giao dịch cũ vẫn liên quan đến hũ cũ.

---

## 📞 Hỗ Trợ

Nếu bạn gặp vấn đề hoặc có câu hỏi, vui lòng:
1. Kiểm tra phần **Câu Hỏi Thường Gặp** ở trên
2. Kiểm tra file **FINAL_IMPLEMENTATION_SUMMARY.md** để biết chi tiết kỹ thuật
3. Báo lỗi qua GitHub Issues (nếu có)

---

**Chúc bạn quản lý tài chính hiệu quả! 💰✨**

