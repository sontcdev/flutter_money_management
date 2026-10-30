# Account deletion review and Google Play appeal

Reviewed 2026-10-27, working tree at d854a73, app version 1.2.0+7.
Existing local changes include SupabaseAuthService; reviewed current working tree, not a published artifact. No application code was changed by this review.

## Verified evidence

- Signed-in users see Settings → Delete account: `lib/src/features/settings/presentation/screens/settings_screen.dart:147`.
- The settings handler calls get_account_deletion_blockers before showing confirmation, calls deleteAccount, then clears local authentication and workspace state after success: same file, line 188 onward.
- The confirmation dialog requires exact DELETE, disables submission while pending, and permits retry after failure: `lib/src/features/auth/presentation/widgets/account_deletion_dialog.dart`.
- SupabaseAuthService invokes delete-account and requires status=deleted: `lib/src/features/auth/services/supabase_auth_service.dart:18`.
- The Edge Function verifies the bearer token using auth.getUser, derives the target user server-side, prepares data cleanup, removes storage objects and calls auth.admin.deleteUser(userId, false): `supabase/functions/delete-account/{handler,index}.ts`.
- `supabase/05_account_deletion.sql` implements cleanup, shared-membership blockers, storage cleanup tracking and author-reference removal. Source presence does not prove deployment or successful execution against production constraints.
- Public deletion page returned HTTP 200 via curl. It identifies MyMoney / tcson.dev, offers email requests without reinstalling, explains ownership verification, deletion scope and retained shared content: https://sontcdev.github.io/flutter_money_management/delete-account.html . Web browsing tool could not fetch this URL; curl retrieved the actual page successfully.

## Validation

Flutter 3.41.7 / Dart 3.11.5.

`flutter test test/account_deletion_service_test.dart test/account_deletion_precheck_test.dart test/account_deletion_dialog_test.dart`

Exit 0; 13 tests passed. These tests validate isolated client behavior, not production deletion. Deno was not available on PATH; Edge Function and SQL tests were not executed.

## Unresolved release and policy questions

No confirmed explanation of the removal can be established from the appeal-form screenshot alone. Obtain the full enforcement notice, affected package/version code, and precise policy subsection.

1. Compare the removed Play artifact against this checkout. A current source implementation is not evidence that reviewers had access to it.
2. Verify production deployment of delete-account, the caller-scoped precheck RPC, cleanup SQL and required permissions. Use a disposable account to verify sign-up → deletion → rejected subsequent sign-in and data/storage cleanup; do not delete an existing user's account as a test.
3. Confirm Data safety contains the public deletion URL and accurately describes the shipped behavior; verify app/developer names match the actual listing.
4. Shared workspace membership blocks deletion; owners must transfer ownership before leaving. Confirm this can be resolved for pending/archived workspaces and that support can process requests when users cannot complete these steps. This is a review concern, not proof that Google rejected this condition.
5. Retained shared notes can still contain personal information even after author IDs are removed. Verify the actual justification and handling of that content before claiming all associated personal data is deleted. Disclosing retention alone does not establish compliance.
6. Public page does not state a concrete email-request processing time and leaves backup retention dependent on hosting configuration. Establish truthful expectations and actual retention before promising any deadline.

Official reference: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en . Google requires an in-app path, a working external request resource, Data safety answers, and deletion of associated user data; legitimate retention must be disclosed. Email is an allowed external request pathway.

## Appeal draft (under 1,000 characters)

Use with the form option acknowledging the issue and proposing remediation. This is a commitment to complete validation and corrections, not a statement that production has already passed review.

Dear Google Play Review Team,
I understand the account deletion requirement and request an opportunity to submit a compliant update for MyMoney. Before resubmission, I will ensure users can initiate permanent account and associated data deletion from Settings > Delete account, and request deletion without installing the app at:
https://sontcdev.github.io/flutter_money_management/delete-account.html
I will verify that the production backend deletes the account and associated data, resolve shared-workspace deletion obstacles, and clearly disclose any legitimate data retention and request processing times. I will update the Data safety form with the deletion URL and accurate disclosures, test the complete flow with a new account, and provide reviewer instructions and evidence. I will resubmit only after these checks and any necessary fixes are complete. Please allow me to submit the corrected release for review.

## Next evidence needed

Full enforcement notice and affected version code. No appeal was submitted, no backend was modified, and no live account was deleted.
