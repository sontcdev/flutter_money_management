# Architecture

## Entry points

- [main.dart](../../../lib/main.dart) → [AppBootstrap](../../../lib/src/app_bootstrap.dart) → [app.dart](../../../lib/src/app.dart).
- [AppRouter](../../../lib/src/app_router.dart) sở hữu các route auth, workspace, transactions, wallets, budgets, reports và recurring.
- Feature-first trong `lib/src/features/`; shared providers trong `lib/src/shared/providers/`; [providers.dart](../../../lib/src/providers/providers.dart) là compatibility barrel.
- Flutter Hooks/Riverpod quản lý state. Repository gọi Supabase trực tiếp; không có Drift/local database hay hàng đợi offline. SharedPreferences dùng cho preferences; `SyncStatus` còn trong model không chứng minh offline sync.
- Comment/log “local-only mode” trong bootstrap và mô tả offline-first trong README không phản ánh khả năng lưu giao dịch hiện tại.

## Schema and boundaries

- [01_create_schema.sql](../../../supabase/01_create_schema.sql): schema dựng mới, RPC, trigger và RLS. [02_add_wallets.sql](../../../supabase/02_add_wallets.sql): migration bổ sung wallets cho schema cũ; schema dựng mới đã có wallets.
- [00_reset_database.sql](../../../supabase/00_reset_database.sql) là script reset phá hủy dữ liệu; chỉ đọc để tra cứu. [03_seed_demo_data.sql](../../../supabase/03_seed_demo_data.sql) là seed, không phải dữ liệu production.
- Dữ liệu nghiệp vụ thuộc workspace: categories, transactions, wallets, budgets, attachments, recurring và activity logs. Repository dùng workspace hiện tại hoặc `workspaceIdOverride`; auth/workspace trống gây lỗi.
- Quyền UI trong [workspace_providers.dart](../../../lib/src/features/workspace/providers/workspace_providers.dart) không thay thế kiểm tra RPC/RLS. Kiểm tra function SQL thực tế khi sửa authorization.
- [supabase_auth_service.dart](../../../lib/src/features/auth/services/supabase_auth_service.dart) gọi `check_signup_uniqueness`; SQL có unique index cho `lower(display_name)`.
- [supabase_error_mapper.dart](../../../lib/src/data/repositories/supabase_error_mapper.dart) ánh xạ PostgrestException; [error_report_service.dart](../../../lib/src/services/error_report_service.dart) và [error_report_dialog.dart](../../../lib/src/ui/widgets/error_report_dialog.dart) phục vụ báo lỗi.

## Validation and generation

- [05_account_deletion.sql](../../../supabase/05_account_deletion.sql) adds a caller-scoped shared-workspace precheck and service-role-only deletion preparation. Active/pending shared memberships and shared ownership block preparation; removed memberships do not. Preparation removes sole-owned workspaces and personal records, clears author references in retained shared financial history, and records storage objects from authoritative ownership/workspace paths for API cleanup. A durable deletion job blocks further client writes and membership re-entry while cleanup is retried. The local delete-account Edge Function removes manifested storage objects before deleting the authenticated user. Settings checks blockers, requires DELETE confirmation, offers retry and the web request link, then clears the local session and workspace selection. Deployment and live verification remain pending.
- [recurring_transaction.dart](../../../lib/src/features/recurring/models/recurring_transaction.dart) accepts nullable author IDs after account deletion. [run_account_deletion_tests.py](../../../supabase/tests/run_account_deletion_tests.py) exercises the full local schema and migration 04 in isolated Postgres, with simulated auth/storage tables; it does not prove live Auth or Storage API deletion.

- Lệnh CI và quy tắc generated code: [AGENTS.md](../../../AGENTS.md), cấu hình thực tế: [ci.yml](../../../.github/workflows/ci.yml).
- Localization: [l10n.yaml](../../../lib/src/i18n/l10n.yaml), ARB trong `lib/l10n/`. Sau đổi ARB chạy `flutter gen-l10n`.
- Freezed/JSON có mặt ở nhiều feature; dùng build_runner sau đổi model; giữ `*.g.dart`, `*.freezed.dart` do generator quản lý.
- Thay đổi tài liệu: kiểm tra links và `git diff --check`; thay đổi behavior: chọn test liên quan trước khi mở rộng validation.

## Last Verified

2026-10-10 — account-deletion schema preparation, retry and privilege tests pass against the full local schema; recurring author-null parsing and service tests pass. Remote schema and live Auth/Storage deletion remain unverified.

2026-10-10 — [09_harden_workspace_activity_invites.sql](../../../supabase/09_harden_workspace_activity_invites.sql) requires active workspace membership for activity logging and authenticated recipient email matching for invitation preview/decline. Recipient-only preview preserves the existing response shape consumed by `WorkspaceManagementService.getInvitePreview`; other token holders cannot read member identity details. [workspace_activity_invite_security_test.sql](../../../supabase/tests/workspace_activity_invite_security_test.sql) verifies permitted logging/preview/decline, foreign workspace denial, and rejected decline preserving pending state. The isolated PostgreSQL suite passes; deployment and live API checks remain pending.

2026-10-10 — [11_harden_workspace_owner_transfer.sql](../../../supabase/11_harden_workspace_owner_transfer.sql) requires the ownership successor to be an active member of the same workspace before demoting the current owner. [workspace_owner_transfer_security_test.sql](../../../supabase/tests/workspace_owner_transfer_security_test.sql) covers rejected pending successors and permitted owner/role transitions in isolated PostgreSQL. Deployment and concurrent/live API verification remain pending.

2026-10-10 — the account-deletion test runner applies migrations 05–11 together; isolated precheck/cleanup/retry/privilege tests pass after the workspace authorization changes. Seven Edge Function handler tests also pass. Auth and Storage are simulated locally; production deployment and end-to-end deletion remain unverified.

2026-10-10 — [12_harden_table_privileges.sql](../../../supabase/12_harden_table_privileges.sql) restores the 15 application tables to authenticated CRUD, removes anonymous/PUBLIC table access and preserves service privileges. [table_privilege_security_test.sql](../../../supabase/tests/table_privilege_security_test.sql) checks all eight PostgreSQL 17 table privileges after reproducing production grant drift. Workspace and account-deletion suites pass with migrations 05–12; deployment remains pending.

2026-10-10 — anonymous signup uniqueness checks remain executable after migration 12; normalized existing and unused identities are covered by `workspace_helper_security_test.sql`. Direct anonymous profile reads/updates are denied and the existing profile remains unchanged. Isolated workspace regression suite passes; live auth/email verification remains pending.

2026-10-10 — migrations 05–12 are now deployed to the linked Supabase project and recorded in remote migration history. Read-only metadata verification confirms the account-deletion preparation helper and RLS plus anonymous denial, authenticated CRUD-only and preserved service-role privileges across all 15 application tables. The delete-account Edge Function deployment and live Auth/Storage deletion remain pending. Evidence: `.plan/store-release-migration-deploy.log` and `.plan/store-release-migration-verification.json`.
