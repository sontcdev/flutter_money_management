# Flutter Money Management — Project Knowledge

RAG này là bản đồ tra cứu mã nguồn, không thay thế implementation. Đọc tài liệu đúng phạm vi rồi kiểm tra source trước khi sửa.

## Tra cứu

| Khi cần | Tài liệu |
| --- | --- |
| Kiến trúc, schema, quyền, codegen và kiểm tra | [Architecture](systems/architecture.md) |
| Đăng nhập, workspace, refresh, resume, báo cáo | [Workspace sync](workflows/workspace-sync.md) |
| Ví, số dư, giao dịch, chuyển tiền, ngân sách | [Wallets and transactions](systems/wallets-transactions.md) |
| Nhập giọng nói, lịch định kỳ, thông báo | [Transaction input and recurring](workflows/transaction-input-recurring.md) |

## Maintenance

Cập nhật tài liệu tương ứng khi workflow, schema, contract hoặc invariant thay đổi; ghi nguồn và `Last Verified`. Giữ thông tin vận hành nhạy cảm ngoài RAG. Kiểm tra đường dẫn tài liệu sau mỗi cập nhật.

## Last Verified

2026-10-02 — đối chiếu source và SQL trong checkout; chưa xác minh database đang triển khai hoặc runtime thiết bị.
