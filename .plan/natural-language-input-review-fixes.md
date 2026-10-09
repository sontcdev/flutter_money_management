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

## Fix 3 — Amount-first phrasing splits inside "và" names

Source: review of `d495032`. Cause: `_splitSegments` cuts at the first separator once the accumulated segment has an amount; with amount-first phrasing "50k ăn và uống, 30k cafe" the `và` inside the category already follows `50k` → `[50k ăn]` `[uống, 30k cafe]`.

- [x] Add a lookahead condition in `_splitSegments`: cut at a separator only if the accumulated segment has an amount **and** the next chunk (text from this separator's end to the next separator match, or end of text) also has an amount. Otherwise keep accumulating.
- [x] Remove the trailing-merge branch only if it becomes unreachable; keep the `< 2 segments → [text.trim()]` fallback.
- [x] Hoist the separator `RegExp` to a `static final` field next to `_weekday` and the other patterns.
- [x] Tests:
  - "50k ăn và uống, 30k cafe" → 2 results: 50k (Ăn và uống), 30k.
  - "50k ăn và uống" → 1 result.
  - "30k cafe và 50k ăn trưa" → 2 results (amount-first both sides).
  - Fix 2 cases stay green ("Ăn và uống 50k và cafe 30k", "cafe 30k, ăn trưa 50k", "cafe 30k + grab 45k", shared date, "mua 1,5tr", "ví tiền mặt và thẻ 50k").
- [x] Known limitation (document in project knowledge, no fix): mixed phrasing such as "cafe 30k và ăn trưa và uống 50k" stays ambiguous and splits at the last `và`.
- [x] Update `.codex/project-knowledge/workflows/transaction-input-recurring.md` split rule + `Last Verified`.
- [x] Validation: `flutter test test/voice_transaction_parser_test.dart`, `flutter analyze`.
- [x] Commit: `fix(transactions): split only between amount-bearing chunks`

## Fix 4 — Split transactions only at commas

Source: review of `4ce6dec` + user decision (2026-10-09): split only after `,`. Cause: word separators (`và/rồi/xong`) collide with names ("Ăn và uống", "bánh và sữa"); every amount-position heuristic left an ambiguous case, and Fix 3 regressed category-first names ("cafe 30k và bánh và sữa 50k" → `[cafe 30k và bánh]` `[sữa 50k]`).

Decision: the only segment separator is a comma not followed by a digit (`,(?!\d)`). `và`, `va`, `rồi`, `roi`, `xong`, `;`, `+` and newline no longer split.

- [x] Change `_segmentSeparator` to `,(?!\d)` (drop `unicode`/`caseSensitive` flags if no longer needed).
- [x] Keep the current `_splitSegments` logic (cut only when the accumulated segment and the next chunk both have an amount) so amountless comma chunks merge: "ví tiền mặt, thẻ 50k" → 1 result, "cafe 30k, mang về" → 1 result.
- [x] Keep `parseMany`, shared date/wallet propagation and the `< 2 segments → [text.trim()]` fallback unchanged.
- [x] Tests in `test/voice_transaction_parser_test.dart`:
  - Separator loop (`và`, `rồi`, `xong`, `,`, `;`, `+`, `\n`): only `,` splits into `[30000, 45000]`; every other separator returns 1 result with amount 30000.
  - Rewrite `và`-based multi-transaction tests to use commas: review examples, shared date ("hôm qua cafe 30k, ăn trưa 50k"), shared context from either end, local/conflicting contexts, "sách 150,000, cafe 30k".
  - Names with `và` stay intact: "Ăn và uống 50k, cafe 30k", "50k ăn và uống, 30k cafe", "cafe 30k, bánh và sữa 50k", "cafe 30k và bánh và sữa 50k" → 1 result.
  - Replace the Fix 3 tests "splits when both chunks start with an amount", "merges amountless trailing text" and "splits ambiguous mixed phrasing" with comma equivalents; delete the ambiguity test (no longer ambiguous).
  - Keep: "mua 1,5tr" → 1 result (1,500,000), "cafe 30,5k, grab 45k" → `[30500, 45000]`, "" → 1 result.
- [x] Update `quickInputExample` in `lib/l10n/app_en.arb`, `app_vi.arb`, `app_ja.arb` to "cafe 30k, grab 45k hôm qua ví momo"; run `flutter gen-l10n`. These ARB files have unrelated uncommitted changes — stage only the `quickInputExample` hunk.
- [x] Check `voice_input_sheet.dart` / `quick_input_review_sheet.dart` for other copy describing `và` splitting.
- [x] Known limitation (document, no fix): speech-to-text rarely emits commas, so spoken multi-transaction input stays as a single transaction unless the user edits the text and adds commas.
- [x] Update `.codex/project-knowledge/workflows/transaction-input-recurring.md`: comma-only split rule, remove the Fix 3 ambiguity text, add a `Last Verified` entry.
- [x] Validation: `flutter test test/voice_transaction_parser_test.dart test/quick_input_sheet_test.dart`, `flutter analyze`.
- [x] Commit: `fix(transactions): split quick input only at commas`

## Fix 5 — Comma-only follow-ups: lost amounts, comma edge cases, note punctuation

Source: detailed review of `7a24ab6` (2026-10-09). The comma-only decision stays: no word-based splitting comes back. Probe results (clock 2026-10-09):

| Input | Current result | Problem |
|-------|----------------|---------|
| `cafe 30k và bánh 50k` | 1 × 30k, note `Cafe và bánh 50k` | 50k dropped silently (speech-to-text rarely emits commas) |
| `cafe 30k,50k bánh` | 1 × 30k, note `Cafe ,50k bánh` | `,(?!\d)` blocks the cut; amount lookbehind `(?<![\d.,])` also hides `50k` |
| `cafe 30k,2 ly trà 50k` | 1 × 30k | same as above |
| `cafe 30k、grab 45k` / `cafe 30k，grab 45k` | 1 × 30k | CJK / full-width commas are not separators |
| `15/10, cafe 30k, grab 45k` | date null, note `15/10, cafe` | `_calendarDate` lookahead `(?![\d.,])` rejects a date followed by a comma, so the date is lost and not shared |
| `cafe 30k, sữa 50k, mang về` | note `Sữa , mang về` | orphan space before punctuation |
| `cafe 30k.` | note `Cafe .` | trailing `.` not trimmed |

### A. Separators (`_segmentSeparator`)
- [x] Change it to `RegExp(r'[,，、](?!\d)|(?<=\p{L})[,，、](?=\d)', unicode: true)`: any comma not followed by a digit, or a comma between a letter and a digit (`30k,50k`, `cafe 30k,2 ly`). `1,5tr`, `30,5k` and `150,000` keep their decimal/thousands comma because a digit precedes it.
- [x] Keep `_splitSegments` unchanged (cut only when both chunks have an amount), so amountless comma chunks still merge.

### B. Comma-adjacent number boundaries
- [x] `_amountWithUnit` and `_currencyAmount`: replace the lookbehind `(?<![\d.,])` with `(?<!\d)(?<!\d[.,])`, so an amount right after a non-numeric comma (`bánh,50k`) is still detected, while `1,5tr` / `150,000` stay single numbers.
- [x] `_calendarDate`: lookbehind becomes `(?<!\d)(?<!\d[.,])`, lookahead becomes `(?!\d|[.,]\d)`, so `15/10,` and `15/10.` parse as dates but `15/10,5` is still rejected.

### C. Flag segments with extra amounts (no silent loss)
- [x] Add `final bool hasExtraAmounts` to `VoiceParseResult` (constructor default `false`).
- [x] Add private `_hasExtraAmounts(String normalized)`: drop dates the same way as `_extractAmount`. Count every `_amountWithUnit` match, then blank those matches and count `_currencyAmount` matches whose parsed value is at least 1000, so small bare counts such as `2 ly` are ignored. Return `count >= 2`.
- [x] Set it in `_parseSingle`. `_QuickInputEditDialog` rebuilds the result without the flag, so the warning clears once the user edits and confirms. This is intended.
- [x] Add l10n key `quickInputExtraAmounts` to `app_en.arb`, `app_vi.arb`, `app_ja.arb`, then run `flutter gen-l10n`. Stage only this hunk, because the ARB files have unrelated uncommitted changes.
  - en: "Several amounts found. Separate transactions with commas."
  - vi: "Có nhiều số tiền. Dùng dấu phẩy để tách giao dịch."
  - ja: "複数の金額があります。取引はカンマで区切ってください。"
- [x] Show it in error color under the affected result:
  - in `voice_input_sheet.dart`, in the results loop next to `quickInputLearned`;
  - in `quick_input_review_sheet.dart`, on the card next to `quickInputMissingFields`.

  It is a warning only. Saving is not blocked, and no comma is inserted automatically, since guessing the cut point is the ambiguity Fix 4 removed.

### D. Note punctuation
- [x] In `_cleanNote`'s final cleanup:
  - collapse whitespace before punctuation: `\s+([,;.、，。])` → `$1`;
  - extend the edge-trim class to `[\s,;.+\-、，。]`.

  Expected results: `Sữa, mang về`, `Cafe`, `Cafe,` → `Cafe`. Leave the `cleaned.isEmpty → raw` fallback unchanged.

### E. Tests
- [x] `test/voice_transaction_parser_test.dart`:
  - Separators: `cafe 30k,50k bánh` → `[30000, 50000]`; `cafe 30k,2 ly trà 50k` → `[30000, 50000]`; `cafe 30k、grab 45k` and `cafe 30k，grab 45k` → `[30000, 45000]`.
  - Regression: `mua 1,5tr` → 1 result (1,500,000); `cafe 30,5k, grab 45k` → `[30500, 45000]`; `sách 150,000, cafe 30k` → `[150000, 30000]`; `ví tiền mặt, thẻ 50k` → 1 result.
  - Dates: `15/10, cafe 30k, grab 45k` → both dated 2026-10-15, first note `Cafe`; `15/10,5` is not a date.
  - Extra amounts:
    - `cafe 30k và bánh 50k` → `hasExtraAmounts` true;
    - `cafe 30k và bánh và sữa 50k`: extend the existing test to assert the flag;
    - `cafe 30k, 2 ly trà 50k` → no result flagged;
    - `1 triệu 5` → false;
    - `cafe 30k hôm 15/10` → false.
  - Notes: `cafe 30k, sữa 50k, mang về` → second note `Sữa, mang về`; `cafe 30k.` → `Cafe`.
- [x] `test/quick_input_sheet_test.dart`: typing `cafe 30k và bánh 50k` shows the `quickInputExtraAmounts` text; `cafe 30k, bánh 50k` does not.

### F. Docs and wrap-up
- [x] Update `.codex/project-knowledge/workflows/transaction-input-recurring.md`:
  - separator set (`,` `，` `、`, including the letter-comma-digit case);
  - the extra-amount warning;
  - `Last Verified`.
- [x] Out of scope: `quickInputExample` in `app_ja.arb` stays Vietnamese, because the parser only understands Vietnamese input.
- [x] Validation: `flutter test test/voice_transaction_parser_test.dart test/quick_input_sheet_test.dart`, then `flutter analyze` (infos fail CI).
- [x] Commit: `fix(transactions): flag extra amounts and harden comma splitting`

## Follow-up (not in this fix)
- [ ] Explicit dates (`ngày 15`, `dd/mm`) may resolve to the future; decide past-only rule consistently for both.
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

### Fix 3 verification

- Before the fix, the amount-first regression failed: `50k ăn và uống` was truncated to `50k ăn`.
- After the fix, all 110 parser tests pass; `flutter analyze` reports no issues.
- The lookahead requires an amount in the next chunk, so no cut occurs before amountless trailing text; the now-unreachable trailing-merge branch was removed.
- The previous mixed-phrasing test is retained with the newly specified split behavior; trailing-text preservation is also tested separately.
- All in-scope requirements are complete; the explicitly excluded follow-ups remain open.

### Fix 4 verification

- Before the change, the updated parser tests reproduced 10 failures, including retired separators and conjunctions in names.
- After the change, all 121 parser/widget tests pass; `flutter analyze` reports no issues.
- Only `_segmentSeparator` changed in production parser code; segmentation, fallback and context propagation remain unchanged.
- All three localized examples use commas. The input and review sheets contain no other copy promising conjunction-based splitting.
- Speech-to-text rarely emits commas; spoken multi-transaction input needs transcript editing to split. Human-operated procedures remain temporarily accepted, without physical-device speech evidence.
- Unrelated localization changes are excluded from the commit. All Fix 4 requirements are complete; follow-ups remain excluded.

### Fix 5 verification

- Regression tests reproduced seven failures before the fix; all 144 focused parser/widget tests pass afterward.
- `flutter analyze`: no issues found.
- Warning tests cover light/dark themes, compact layouts with keyboard and enlarged text, saving despite the warning, and clearing it after confirmed edits.
- Android emulator preview builds and launches; typed multi-amount input shows the warning, and comma-separated input produces two results without the warning.
- Human-operated procedures remain temporarily accepted; physical-device Vietnamese speech remains unverified.
- Unrelated working-tree and localization changes are excluded from the commit. All Fix 5 requirements are complete; follow-ups remain excluded.
