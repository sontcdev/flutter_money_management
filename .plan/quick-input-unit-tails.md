# Quick input: unit tail scaling and spaced amounts

Follows `.plan/natural-language-input-review-fixes.md` (Fixes 1–5, done).

Source: review of `95e6490` plus an edge-case probe (2026-10-09, clock 2026-10-09). Root cause: the trailing group `(?:\s*(\d{1,3})(?![\d.,/\-]))?` in `_amountWithUnit` applies to every unit, and `_extractAmount` always adds `sub * 100000`.

| Input | Current result | Expected |
|-------|----------------|----------|
| `1tr200` | 21,000,000 | 1,200,000 |
| `1tr25` | 3,500,000 | 1,250,000 |
| `cafe 1tr 200k` | 21,000,000, note `Cafe k` | 1,000,000, flagged, note `Cafe` (first amount kept) |
| `1 triệu 500k` | 51,000,000, note `K` | 1,000,000, flagged |
| `cafe 30k 50k` | 30,000, note `Cafe k`, not flagged | 30,000, note `Cafe`, flagged |
| `đổ xăng 2 lít 50k` | 200,000, note `Đổ xăng k`, not flagged | 200,000, flagged |
| `nhận lương 1 tỷ 2` | 1,000,000,000 (tail ignored) | 1,200,000,000 |
| `cafe 2 trăm nghìn` | 200,000, note `Cafe nghìn` | 200,000, note `Cafe` |
| `cafe 30k năm 2026` / `tiền nhà tháng 10/2026 5tr` / `phòng 1203 tiền điện 500k` | flagged | not flagged (first two); `1203` stays flagged (acceptable) |

## A. Tail group (`_amountWithUnit`)
- [x] Capture the tail only for `trieu|tr|cu|m|ty`, and only when no unit follows the tail digits:
  `(?:(?<=trieu|tr|cu|m|ty)\s*(\d{1,3})(?![\d.,/\-])(?!\s*(?:trieu|tr|cu|ty|lit|tram|m|nghin|ngan|k)(?![a-z])))?`
  (or split into two alternatives; any form is fine as long as `30k 50k` and `2 lit 50k` no longer consume `50`).
- [x] Accept the compound unit `tram\s+(?:nghin|ngan)` (= ×100,000) before plain `tram`, so `2 trăm nghìn` is one match and the note loses `nghìn`.

## B. Tail scaling (`_extractAmount`)
- [x] Scale by digit count relative to the unit: tail value × (multiplier / 10^digits). `tr`: 1 digit ×100,000, 2 digits ×10,000, 3 digits ×1,000. `ty`: 1 digit ×100,000,000, 2 ×10,000,000, 3 ×1,000,000.
- [x] `_hasExtraAmounts` needs no change: once the tail stops swallowing `50`, `50k` is counted as a second unit match.

## C. Year false positives (`_hasExtraAmounts`, optional)
- [x] Before counting, blank `\b(?:nam|thang\s+\d{1,2}[/\-])\s*(?:19|20)\d{2}\b` and `\b\d{1,2}[/\-](?:19|20)\d{2}\b` (month/year). Do not touch `_extractAmount`; the first-amount choice already works for these inputs.

## D. Tests (`test/voice_transaction_parser_test.dart`)
- [x] Scaling: `1tr2` → 1,200,000; `1tr25` → 1,250,000; `1tr200` → 1,200,000; `1 triệu 5` → 1,500,000 (regression); `1 tỷ 2` → 1,200,000,000.
- [x] Flags: `cafe 1tr 200k`, `1 triệu 500k`, `cafe 30k 50k` (note `Cafe`), `đổ xăng 2 lít 50k` → `hasExtraAmounts` true and first amount kept.
- [x] Note: `cafe 2 trăm nghìn` → 200,000, note `Cafe`.
- [x] Optional (C): `cafe 30k năm 2026`, `tiền nhà tháng 10/2026 5tr` → not flagged.

## E. Docs and wrap-up
- [x] Knowledge doc `.codex/project-knowledge/workflows/transaction-input-recurring.md`: tail rules (`tr`/`ty` only, digit-count scaling) and the accepted split `mua 2tr,5 cafe 30k` → 2,000,000 `Mua` + 30,000 `5 cafe` (letter-comma-digit rule from Fix 5); update `Last Verified`.
- [x] Validation: `flutter test test/voice_transaction_parser_test.dart test/quick_input_sheet_test.dart`, then `flutter analyze`.
- [x] Commit: `fix(transactions): scale million tails and flag spaced amounts`

## Follow-up (not in this fix)
- [ ] Explicit dates still resolve to the future: `cafe 30k ngày 25` → 2026-10-25, `cafe 30k 15/10` → 2026-10-15 (today 2026-10-09). Tracked in the previous plan; needs a past-only decision.
- [ ] `$20 sách` → 20 VND: `$` is accepted but not converted. Either drop `$` from `_currencyAmount` or leave amount unset; needs a product decision.
- [ ] Spoken word numbers (`ba mươi nghìn`) are not parsed (amount null). Speech-to-text usually emits digits, so low priority.
- [ ] Minor note residue: `cafe 30k v.v.` → `Cafe v.v`.

## Verification results

- New regression tests reproduced 18 failures before implementation. All 166 focused parser/widget tests pass after the fix; `flutter analyze` reports no issues.
- Optional year/month-year warning filtering is included; amount extraction for these contexts remains unchanged.
- Note cleanup removes all matched unit amounts to satisfy the specified `Cafe` results; empty-note fallback is preserved.
- Android emulator preview builds and launches. Typed `cafe 30k 50k` shows 30,000 VND, note `Cafe` and the warning; `cafe 1tr200` shows 1,200,000 VND without the warning.
- Human-operated procedures remain temporarily accepted; no physical-device speech result is claimed.
- Unrelated working-tree changes and all listed follow-ups remain excluded.
