# Natural-Language Input — Review Fixes

Source: code review of `6b9a14f..a9cc055`. Scope: `lib/src/utils/voice_transaction_parser.dart` + tests.

## Fix 1 — Bare weekday resolves to a future date

Cause: `_extractDate` weekday branch (`now.day + target - now.weekday - offset`) always picks the day in the current week; with no `tuan nay/truoc`, "thứ 6" said on Monday → next Friday.

- [x] Group 2 null (bare weekday): if computed date is after `today`, subtract 7 days → most recent occurrence on or before today.
- [x] Keep `tuan nay` explicit behavior (current week, may be future) and `tuan truoc` (−7) unchanged.
- [x] Tests (fixed `clock`): Monday + "thứ 6" → previous Friday; Friday + "thứ 6" → today; Wednesday + "thứ 2" → this Monday; "chủ nhật" on Saturday → previous Sunday; "thứ 6 tuần này" on Monday → coming Friday; "thứ 6 tuần trước" unchanged.
- [x] Same class, check: `ngay 15` before the 15th → this month (future). Apply the same rule (fall back to previous month) only if it is consistent with `dd/mm` handling; otherwise note as follow-up.

## Fix 2 — Splitting breaks category/wallet names containing "và"

Cause: `parseMany` splits on every separator, then requires every part to have an amount; "Ăn và uống 50k và cafe 30k" → part "Ăn" has no amount → whole split abandoned → one transaction.

- [x] Change splitting to "split only at separators that come after an amount": iterate separator matches, cut only when the accumulated segment (from last cut) already contains an amount (`_extractAmount(_normalize(segment)) != null`). Trailing text without amount is merged into the last segment.
- [x] Keep the existing fallback: if fewer than 2 segments result, return the whole text as a single segment.
- [x] Extract into a private `_splitSegments(String text)` helper; `parseMany` body otherwise unchanged.
- [x] Tests:
  - "Ăn và uống 50k và cafe 30k" → 2 results: 50k (category Ăn và uống), 30k.
  - "cafe 30k, ăn trưa 50k" and "cafe 30k + grab 45k" → 2 results (regression).
  - "hôm qua cafe 30k và ăn trưa 50k" → shared date propagated (regression).
  - "mua 1,5tr" → 1 result (comma inside number not a separator).
  - "ví tiền mặt và thẻ 50k" (no amount before first "và") → 1 result.
  - Existing corpus tests in `test/voice_transaction_parser_test.dart` still pass.

## Follow-up (not in this fix)
- [ ] Review UI changes in `b477a40` (`quick_input_review_sheet.dart`, `voice_input_sheet.dart`, `add_transaction_screen.dart`), which the review skipped.
- [ ] Unrelated uncommitted changes: `applicationId` rename in `android/app/build.gradle.kts`, uncaught `launchUrl` exception in `settings_screen.dart:358`.

## Validation
- [x] `flutter test test/voice_transaction_parser_test.dart`
- [x] `flutter analyze` (infos fail CI)
- [x] Commit: `fix(transactions): resolve past weekdays and split after amounts`

## Verification results

- Regression tests reproduced four failures before the fixes; all 106 parser tests pass after the fixes.
- `flutter analyze`: no issues found.
- `ngày 15` and `dd/mm` both allow future explicit dates. Their behavior is preserved; changing explicit dates to past-only remains a follow-up.
- Human-operated procedures are temporarily accepted by the user; no physical-device result is claimed.
- UI review and unrelated working-tree findings remain outside this fix.
