# Quick input: residual guards (review of the quick-input-diacritic-guards implementation)

Follows `.plan/quick-input-diacritic-guards.md`; ground rules still apply: frozen formats (F), flag don't guess, one corpus, probe before done.
Scope: `lib/src/utils/voice_transaction_parser.dart`, `test/voice_transaction_parser_test.dart`, `.codex/project-knowledge/workflows/transaction-input-recurring.md`.
Clock for fixtures: `DateTime(2026, 10, 9)`.

This is the last round for the diacritic findings: one code fix (1). Items 2–4 are pinned as limitations, with no new parsing rules.

## 1. Decomposed `đô` (NFD) must count as foreign currency (low, regression)

Current: `20 đô` → amount 20, note `Đô`. The literal `đô` in `_foreignCurrency` only matches the composed form (NFC). The previous normalized check caught both forms.

- [x] In `_foreignCurrency`, accept both forms: `\d\s*(?:đô|đô|usd|\$)(?![\p{L}\p{M}0-9])` (unicode). Adding `\p{M}` to the lookahead also stops a trailing combining mark from ending the match early.
- [x] Expected: `20 đô` → null; `mua 2 đôi giày 500k` → 500000 (the `i` after the mark blocks the match); NFC rows are unchanged.
- [x] Do not add general NFC normalization; it is out of scope and has no SDK support.

## 2. Foreign chunk blocks the comma split (limitation)

`nhận 20 đô, cafe 30k` → 1 segment, amount null. The split needs an amount on both sides, and a foreign-currency chunk has no amount. A null amount forces the user to enter it on review, which is acceptable under "flag, don't guess". Splitting next to a foreign chunk would change the frozen split contract (`4ce6dec`).

- [x] No code change.

## 3. Unaccented `N do` after a unit amount is not flagged (limitation)

`cafe 30k, 20 do` → 1 segment, 30000, note `Cafe, 20 do`, not flagged. This can't be told apart from `mua 20 do an 50k` (a count) without guessing.

- [x] No code change.

## 4. Accented input with unaccented `do` (limitation)

`mua sách 20 do` → 20, note `Mua sách do`. Unaccented `do` counts as foreign currency only when the whole chunk is unaccented (item 1 of the previous plan).

- [x] No code change.

## 5. Corpus rows (`group('Format corpus')`)

These rows pin the current behaviour so that any later change to it shows up as a test failure. `–` means the column is not asserted.

| Input | Segments | Amount | Note | Flag |
|-------|----------|--------|------|------|
| `20 đô` | 1 | null | – | no |
| `mua 2 đôi giày 500k` | 1 | 500000 | – | no |
| `nhận 20 đô, cafe 30k` | 1 | null | – | – |
| `cafe 30k, 20 do` | 1 | 30000 | `Cafe, 20 do` | no |
| `mua sách 20 do` | 1 | 20 | `Mua sách do` | – |

- [x] Write the rows first. Only the two NFD rows should fail before item 1; if any other row fails, record the actual output under "Verification results" and do not change code for it.

## 6. Docs

- [x] Section G (knowledge doc): add items 2–4 as known limitations with their example inputs, and note that `đô` matches both NFC and NFD.
- [x] Bump `Last Verified`.

## 7. Verify

- [x] `flutter test test/voice_transaction_parser_test.dart test/quick_input_sheet_test.dart`, then `flutter analyze` (info-level lints must be clean too).
- [x] `git diff` vs `git diff -w`: no whitespace-only changes; no new comments.
- [x] User requested a separate commit: `fix(transactions): recognize decomposed foreign currency`.

## Out of scope

- Performance of `_isUnaccented`: it is called up to 3 times per chunk and runs `_normalize` per character. Chunks are short and there is no user-visible cost, so the signatures stay as they are.
- Older follow-ups still open in `.plan/quick-input-tail-guards.md` (bare year as amount, date residue in note) and `.plan/quick-input-unit-tails.md`.

## Verification results

2026-10-10:
- Added all five rows to the existing Format corpus, including one-segment assertions through `parseMany`; 112 corpus rows total. All five rows assert `hasExtraAmounts` as `false`.
- Before implementation: 111 rows passed; only `20 đô` failed (expected null, actual 20 VND). The NFD `đôi` row already returned 500,000 VND, so the plan's prediction that both NFD rows would fail was not observed. All limitation rows matched their expected output; no additional parsing rules were introduced.
- Updated only the foreign-currency regex to accept NFC/NFD `đô` and reject a following combining mark.
- After implementation: all 292 parser/widget tests passed; full `flutter analyze` reported no issues.
- Updated known limitations and Last Verified. Reviewed the complete task diff and `git diff -w`; no whitespace-only changes or new comments. Changed test lines match `dart format`; `git diff --check` passed.
- Prepared a separate commit at the user's request. The previous consolidated implementation was committed as `10bbc75` before this work; unrelated changes remain preserved.
- Review follow-up: dropped the flag-skip wrapper so the existing `hasExtraAmounts` assertion line is unchanged; the two previously unasserted rows now assert `false` (probed actual value). 292 tests pass; analyze clean.
