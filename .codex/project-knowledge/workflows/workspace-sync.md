# Workspace and refresh

## State and selection

- [auth_providers.dart](../../../lib/src/features/auth/providers/auth_providers.dart) cung cấp session/user; [workspace_providers.dart](../../../lib/src/features/workspace/providers/workspace_providers.dart) tải workspace qua membership và giữ `activeWorkspaceIdProvider` (`StateProvider<String?>`).
- [workspace_management_service.dart](../../../lib/src/features/workspace/services/workspace_management_service.dart) xử lý quản lý workspace; UI dùng role providers để xác định quyền quản lý và khả năng rời nhóm. Owner và personal workspace không có luồng leave như member nhóm.

## Refresh contract

1. [syncCurrentWorkspaceData](../../../lib/src/features/workspace/services/workspace_sync_helper.dart) trả `null` nếu không có session.
2. Nếu `refreshWorkspaceList`, invalidate danh sách workspace. Nếu active ID trống, tải danh sách và chọn workspace đầu tiên; không có workspace thì trả `null`.
3. `invalidateCoreDataProviders` invalidate categories, transactions, budgets, budgetsWithConsumed, recurringTransactions, upcomingRecurringOccurrences, wallets và allWalletsIncludingArchived.
4. Trả workspace ID sau khi invalidate; kết thúc helper không đảm bảo mọi request refetch đã hoàn tất.

Repository đọc active workspace qua callback; đổi ID cần đi cùng invalidation. Wallet providers giữ cache Riverpod nên bỏ invalidation ví có thể hiển thị ví workspace trước.

## Lifecycle and reports

- [AppLifecycleSyncCoordinator](../../../lib/src/ui/widgets/app_lifecycle_sync_coordinator.dart) sync startup/resume, refresh notifications và recurring reminders. Resume có guard đang sync và cooldown 20 giây.
- [report_providers.dart](../../../lib/src/features/reports/providers/report_providers.dart): calendar/summary/groups dùng cycle từ `monthStartDayProvider`, không mặc định tháng dương lịch. Providers theo dõi transactions rồi query repository.
- `TransactionListNotifier.refresh()` gọi helper chung và invalidate ba report providers cho tháng đang chọn. Transfer vẫn xuất hiện trong group nhưng không cộng vào income/expense hoặc badges.

## Verification sources

- [report_calendar_widget_test.dart](../../../test/report_calendar_widget_test.dart)
- [transfer_exclusion_test.dart](../../../test/transfer_exclusion_test.dart)
- [workspace-test-plan.md](../../../docs/workspace-test-plan.md)

## Last Verified

2026-10-02 — provider/helper/lifecycle source; chưa kiểm thử đổi workspace trên thiết bị.

## Password recovery

- `sign_in_screen.dart` opens `forgot_password_screen.dart` without making a request. The email-entry screen validates the address, sends the recovery email, then opens `password_reset_code_screen.dart`. Password fields remain on `reset_password_screen.dart` and appear only after successful recovery verification.
- `SupabaseAuthService.verifyPasswordResetCode` verifies `OtpType.recovery`; `AuthCallbackFeedbackListener` uses the app navigator key to open `/reset-password` on `AuthChangeEvent.passwordRecovery` (covered by `password_recovery_navigation_test.dart`).
- The hosted Reset password email template must include `{{ .Token }}`. The prepared body is `supabase/templates/password_recovery.html`; setup and device verification are described in `docs/password-reset.md`.
- Last Verified: 2026-10-10 — source contracts; hosted template publication and live email/device recovery remain unverified.
