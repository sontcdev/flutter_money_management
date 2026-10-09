# Quick input: final consolidated fixes

Replaces the open follow-ups in `.plan/quick-input-tail-guards.md`, `.plan/quick-input-unit-tails.md` and `.plan/natural-language-input-review-fixes.md` (the old plans are left unchanged).
Scope: `lib/src/utils/voice_transaction_parser.dart`, `test/voice_transaction_parser_test.dart`, `.codex/project-knowledge/workflows/transaction-input-recurring.md`.
Clock for all fixtures: `DateTime(2026, 10, 9)`.

## Ground rules (stop the fix-review-fix loop)

1. **Frozen format list.** Only the formats in section F are supported. Anything else is a known limitation, not a bug, unless the user adds it to F.
2. **Flag, don't guess.** If a chunk has more than one amount candidate, keep the first valid one and set `hasExtraAmounts`. If the amount cannot be read safely, set `amountVnd` to null and let the review screen ask for it. Never invent a value.
3. **One corpus.** Every input in this plan is a row in one table-driven test, `group('Format corpus')`. A change is done only when the whole corpus passes. New review findings become new rows, not new plans.
4. **Probe before reporting done.** Run the full corpus plus the old groups, then `flutter analyze`. Review the result against section F only.

## 0. Prerequisite

- [x] Commit the uncommitted tail-guard work first: parser, test and knowledge-doc changes only, with no l10n, settings, gradle, pubspec or script files. Use the message `fix(transactions): restrict unit tails to integer amounts`. Start this plan from a clean parser diff.

## A. Amounts (`_amountWithUnit`, `_currencyAmount`, `_extractAmount`)

- [x] **A1 Space thousands.** Accept `\d{1,3}(?: \d{3})+` as one grouped number when no unit follows inside the group, for example `30 000` → 30,000 and `1 500 000` → 1,500,000. A trailing currency word is allowed (`30 000 đ`). The groups must be exactly 3 digits, so `phòng 12 500` stays two numbers (12, flagged).
- [x] **A2 `rưỡi`.** An optional `\s*ruoi` right after any unit adds `0.5 × multiplier`: `1tr rưỡi` → 1,500,000; `1 triệu rưỡi` → 1,500,000; `2 củ rưỡi` → 2,500,000; `30 nghìn rưỡi` → 30,500; `5 trăm rưỡi` → 550,000. A digit tail and `rưỡi` cannot both apply. The note must drop `rưỡi`.
- [x] **A3 Foreign currency.** Remove `\$` from `_currencyAmount`. If the chunk matches `\$\s*\d|\d\s*(?:do|usd|\$)(?![a-z])` (normalized), set `amountVnd` to null with no conversion. Examples: `$20 sách`, `20 đô`, `20 usd`. The note keeps the text so the user can see it.
- [x] **A4 Zero.** A parsed amount `<= 0` becomes null (`0k`, `0đ`).
- [x] **A5 Year contexts are never amounts.** In `_extractAmount`, blank `_yearContext` and `_monthYear` matches before choosing the amount, the same way dates are already blanked. So `cafe năm 2026 30000` → 30,000, not flagged, and `tiền nhà tháng 10/2026 5tr` → 5,000,000.
- [x] **A6 Bare small numbers:** no change. `500` → 500 stays as-is (listed in limitations).

## B. Dates (`_extractDate` plus the blanking lists used by amount and extra-amount detection)

- [x] **B1 Past-only explicit dates.** Every explicit date without a year resolves to today or earlier:
  - `ngày N` with N greater than today's day → previous month. If that month lacks day N, go back month by month until it has it (`ngày 31` → 2026-08-31).
  - `dd/mm` with no year, if after today → the previous year (`15/10` → 2025-10-15).
  - Explicit years and `ngày mai` are unchanged (`ngày mai` is still +1).
- [x] **B2 `ngày N tháng M [năm Y]`.** Parse it as a calendar date. With no year, apply the past-only rule (`ngày 15 tháng 9` → 2026-09-15). The whole phrase, including `năm Y`, is removed from the note and blanked for amount and extra detection. A bare `tháng M` with no `ngày N` (`tiền nhà tháng 10`) stays note text and is not a date.
- [x] **B3 Relative phrases.** Add:
  - `tháng trước` → the same day last month, clamped to that month's last day;
  - `N ngày trước` → today − N, for N from 1 to 90;
  - `N tuần trước` → today − 7N, for N from 1 to 12.
  The digits in these phrases are blanked for amount and extra detection. For example, `cafe 30k 3 ngày trước` → 30,000, not flagged.
- [x] **B4 Note.** Every matched date phrase from B1–B3 is removed from the note.

## C. Note (`_cleanNote`)

- [x] **C1** Strip `\bv\.?\s?v\.?` and `\betc\.?` together with any trailing punctuation: `cafe 30k v.v.` → `Cafe`.
- [x] **C2** Trim leftover leading or trailing `,.;:-` after all removals.

## D. Type (`_extractType`)

- [x] **D1 Diacritic-aware matching.** Match keywords against the lowercased text with diacritics kept, falling back to normalized matching only when the input has no Vietnamese diacritics at all. Speech always outputs diacritics; this fallback is for unaccented typing. The change fixes `1.500.000 đồng` → null type (`đồng` ≠ `đóng`).
- [x] **D2** Before matching, blank amount spans including the currency word, so unit or currency words never match a keyword.
- [x] **D3** Add the income keyword `bán` (with diacritic matching, `bạn` is not affected): `bán đồ cũ 300k` → income, `ăn với bạn 200k` → expense. `vay` and `cho vay` stay null and are listed as a limitation.

## E. Corpus test (`test/voice_transaction_parser_test.dart`)

- [x] Add one `group('Format corpus')` built from a `const` list of records `(input, amount, date, type, note, flagged)`. Pass `null` to mean "don't care" only for fields the row does not test. Rows:

| Input | Amount | Date | Type | Note | Flag |
|---|---|---|---|---|---|
| `30 000` | 30000 | – | – | – | no |
| `cafe 1 500 000` | 1500000 | – | – | `Cafe` | no |
| `phòng 12 500` | 12 | – | – | – | yes |
| `1tr rưỡi` | 1500000 | – | – | – | no |
| `cafe 1 triệu rưỡi` | 1500000 | – | – | `Cafe` | no |
| `30 nghìn rưỡi` | 30500 | – | – | – | no |
| `5 trăm rưỡi` | 550000 | – | – | – | no |
| `$20 sách` | null | – | – | – | no |
| `20 đô` | null | – | – | – | no |
| `0k cafe` | null | – | – | – | no |
| `cafe năm 2026 30000` | 30000 | – | – | `Cafe` | no |
| `cafe 30k ngày 25` | 30000 | 2026-09-25 | – | `Cafe` | no |
| `cafe 30k 15/10` | 30000 | 2025-10-15 | – | `Cafe` | no |
| `cafe 30k ngày 31` | 30000 | 2026-08-31 | – | `Cafe` | no |
| `cafe 30k ngày 5` | 30000 | 2026-10-05 | – | `Cafe` | no |
| `cafe 30k ngày 15 tháng 9` | 30000 | 2026-09-15 | – | `Cafe` | no |
| `cafe 30k ngày 15 tháng 10 năm 2026` | 30000 | 2026-10-15 | – | `Cafe` | no |
| `cafe 30k tháng trước` | 30000 | 2026-09-09 | – | `Cafe` | no |
| `cafe 30k 3 ngày trước` | 30000 | 2026-10-06 | – | `Cafe` | no |
| `cafe 30k 2 tuần trước` | 30000 | 2026-09-25 | – | `Cafe` | no |
| `cafe 30k ngày mai` | 30000 | 2026-10-10 | – | `Cafe` | no |
| `cafe 30k v.v.` | 30000 | – | – | `Cafe` | no |
| `1.500.000 đồng` | 1500000 | – | null | – | no |
| `đóng học phí 1tr` | 1000000 | – | expense | – | no |
| `bán đồ cũ 300k` | 300000 | – | income | – | no |
| `ăn với bạn 200k` | 200000 | – | expense | – | no |
| `an voi ban 200k` | 200000 | – | expense | – | no |
| Regression: `30k`, `30 nghìn`, `30.000`, `30,000`, `30.000đ`, `1tr5`, `1tr 5`, `1 triệu 5`, `1.5tr`, `2 củ`, `5 trăm`, `1.2 tỷ`, `1.500.000` | current values | – | – | – | no |
| Regression: `iphone 15 20tr`, `xăng 95 50k`, `grab 7h 50k`, `cafe lúc 9h30 30k`, `tiền nhà tháng 10 5tr`, `mua 3 ly cafe 90k` | current values | – | – | – | no |
| Regression: `tiền nhà 2026 5tr`, `phòng 1203 tiền điện 500k`, `cafe 30k và 50k`, `cafe 30k + 50k`, `cafe 30k; 50k` | first amount | – | – | – | yes |

- [x] Write the corpus first, run it, and record which rows fail before the implementation, so each fix is proven by its row.

## F. Frozen supported formats (copy into the knowledge doc)

- **Amounts:**
  - `N` + unit, where units are `k`, `nghìn`/`ngàn`, `trăm`, `trăm nghìn`, `tr`/`triệu`/`củ`/`m`, `tỷ` and `lít` (the `lít` quantity is still counted as a candidate);
  - decimal units (`1.5tr`, `1,5tr`);
  - attached tail (`1tr2`, `1tr25`, `1tr200`) and spaced tail only at the end of a chunk (`1 triệu 5`);
  - `rưỡi`;
  - grouped digits with `.`, `,` or a space;
  - an optional `đ`/`đồng`/`vnd` suffix.
- **Not supported (amount null):** foreign currency and zero.
- **Dates:**
  - `hôm nay`, `hôm qua`, `hôm kia`, `hôm trước`, `ngày mai`, `sáng/trưa/tối nay`;
  - weekdays (past);
  - `tuần trước`, `N tuần trước`, `N ngày trước`, `tháng trước`;
  - `đầu tháng`, `cuối tháng`;
  - `ngày N`, `dd/mm`, `dd/mm/yyyy`, `ngày N tháng M [năm Y]`.
  All of these except `ngày mai` resolve to the past.
- **Splitting:** a comma splits only between chunks that both carry an amount. `và`, `+` and `;` do not split; they set the flag.

## G. Known limitations (document only; no code)

- Spoken word numbers (`ba mươi nghìn`, `hai triệu`) → amount null. Speech-to-text already outputs digits.
- A bare number with no unit is taken literally (`500` → 500 VND).
- `vay`, `cho vay` and `trả nợ` have no type; the user picks one on review.
- `tháng M` alone is note text, not a date.
- Two amounts with no separator (`cafe 30k bánh 20k`) keep the first amount and set the flag; they do not split.

## H. Docs and verification

- [x] Update `transaction-input-recurring.md`: replace the scattered rules with section F, add section G, and bump `Last Verified` and the source paths.
- [x] Verify: `flutter test test/voice_transaction_parser_test.dart test/quick_input_sheet_test.dart`, then `flutter analyze` (info-level lints must be clean too).
- [x] User requested commit: `fix(transactions): freeze quick input formats and past-only dates`.

## Out of scope (report only)

- UI review of `b477a40` (still open in `natural-language-input-review-fixes.md`).
- The unrelated `applicationId` rename in `android/app/build.gradle.kts` and the uncaught `launchUrl` exception at `settings_screen.dart:358`.

## Implementation evidence — 2026-10-10

- Prerequisite committed as `70bb566`; only parser, parser tests and the knowledge document were staged.
- The initial 64-row corpus was run before implementation: 36 passed and 28 failed. Failed rows:
  - `30 000`
  - `cafe 1 500 000`
  - `phòng 12 500`
  - `1tr rưỡi`
  - `cafe 1 triệu rưỡi`
  - `2 củ rưỡi`
  - `30 nghìn rưỡi`
  - `5 trăm rưỡi`
  - `$20 sách`
  - `20 đô`
  - `20 usd`
  - `0k cafe`
  - `0đ`
  - `cafe năm 2026 30000`
  - `cafe 30k ngày 25`
  - `cafe 30k 15/10`
  - `cafe 30k ngày 31`
  - `cafe 30k ngày 15 tháng 9`
  - `cafe 30k ngày 15 tháng 10 năm 2026`
  - `cafe 30k tháng trước`
  - `cafe 30k 3 ngày trước`
  - `cafe 30k 2 tuần trước`
  - `cafe 30k v.v.`
  - `cafe 30k etc.;`
  - `1.500.000 đồng`
  - `bán đồ cũ 300k`
  - `30 000 đ`
  - `trả nợ 50k`
- Final corpus: 97 rows at `DateTime(2026, 10, 9)`. Full parser/widget verification: 277 tests passed; `flutter analyze`: no issues.
- Plan conflicts resolved using explicit examples and existing contracts: room context excludes space grouping; explicit years and explicit weekday `tuần này` retain their specified dates; unit amounts retain priority over ambiguous bare counts in the listed regression rows. `cuối tháng` now uses the most recent month end.
- Android emulator: synthetic preview builds and launches; typed `cafe 1 500 000` displays `1.500.000 ₫` and note `Cafe`. Physical-device speech remains unverified. Human-operated verification is temporarily accepted under the user's instruction.
- Unrelated changes and the three older plans were preserved. User requested the final commit; consolidated fixes and diacritic guards are committed together.
