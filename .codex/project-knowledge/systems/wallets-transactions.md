# Wallets and transactions

## Wallet rules

- [WalletRepository](../../../lib/src/features/wallets/repositories/wallet_repository.dart) đọc theo workspace, lọc `deleted_at`; mặc định bỏ archived. Ghi qua `create_wallet_rpc`, `update_wallet_rpc`, `set_default_wallet_rpc`, `soft_delete_wallet_rpc`.
- SQL trong [01_create_schema.sql](../../../supabase/01_create_schema.sql) và [02_add_wallets.sql](../../../supabase/02_add_wallets.sql): tên normalized duy nhất trong workspace, tối đa một default chưa xóa; RPC quản lý ví yêu cầu owner/admin.
- Archive bỏ default. Xóa ví có giao dịch chưa xóa ở nguồn hoặc đích trả `WALLET_IN_USE`, mapper chuyển thành `WalletInUseException`; người dùng có thể archive.
- [wallet_providers.dart](../../../lib/src/features/wallets/providers/wallet_providers.dart): default fallback ví đầu tiên. `computeWalletBalances` = opening + income − expense + transfer in − transfer out; bỏ transaction đã xóa. Tổng số dư hiện dùng danh sách ví không archived.

## Transaction contract

- [Transaction](../../../lib/src/features/transactions/models/transaction.dart): `expense`, `income`, `transfer`; wallet IDs nullable trong Dart để biểu diễn state cũ/form, nhưng SQL yêu cầu `wallet_id`.
- Transfer: nguồn/đích khác nhau, `to_wallet_id` có giá trị, `category_id` null. Income/expense: có category, không có đích. SQL có `transactions_transfer_shape_check`.
- [TransactionRepository](../../../lib/src/features/transactions/repositories/transaction_repository.dart): reads lọc workspace và soft deletion; writes dùng `create_transaction_rpc`, `update_transaction_rpc`, `soft_delete_transaction_rpc`.
- [AddTransactionScreen](../../../lib/src/features/transactions/presentation/screens/add_transaction_screen.dart) chọn ví mặc định; transfer chọn ví đích và bỏ category. Sau lưu invalidate dữ liệu/số dư liên quan.
- `amountCents` ánh xạ SQL `amount_minor`. [CurrencyFormatter](../../../lib/src/utils/currency_formatter.dart) nhân 100 khi lưu VND, chia 100 khi hiển thị; opening balance cùng đơn vị minor. Không ghi giá trị VND hiển thị trực tiếp vào minor.
- `_validateBudgetImpact` chỉ tính expense cùng category trong kỳ ngân sách, bỏ giao dịch cũ khi edit; `allowOverdraft`/budget override kiểm soát vượt hạn mức. Transfer không tiêu ngân sách và không tính là thu/chi báo cáo.

## Verification sources

- [wallet_balance_test.dart](../../../test/wallet_balance_test.dart)
- [transfer_exclusion_test.dart](../../../test/transfer_exclusion_test.dart)
- [phase4-wallets-manual-test-plan.md](../../../docs/phase4-wallets-manual-test-plan.md)

## Last Verified

2026-10-02 — model, repository, provider, form và SQL; chưa xác minh RPC/schema đang triển khai.

2026-10-10 — local [financial mutation migration](../../../supabase/08_harden_financial_mutations.sql) adds identified active-membership checks to category, transaction and budget mutation RPCs, plus workspace ownership checks for referenced categories and transaction wallets. [Authorization tests](../../../supabase/tests/financial_mutation_security_test.sql) reject unauthorized workspace calls to all nine RPCs in isolated Postgres 17. Populated permitted/reference coverage and live API verification remain pending; the migration is not deployed. Existing wallet owner/admin contracts are preserved.

2026-10-10 — populated isolated Postgres 17 tests pass for permitted category/budget/expense/transfer create and edit, plus soft deletion. Foreign category/source-wallet/destination-wallet references are rejected; rejected edits preserve budget amounts and transfer destinations. Administrative assertions verify stored deletion state where RLS hides deleted rows. Other workspace category/wallet records remain unchanged. Production deployment and live API checks remain pending.

2026-10-10 — [10_harden_wallet_targets.sql](../../../supabase/10_harden_wallet_targets.sql) validates target wallet workspace ownership and non-deleted state before update/default/deletion side effects. Owner/admin checks remain intact. [wallet_target_security_test.sql](../../../supabase/tests/wallet_target_security_test.sql) verifies rejected foreign targets preserve the default and foreign record, plus permitted switching/editing/deletion. Isolated PostgreSQL tests pass; deployment and live verification remain pending.
