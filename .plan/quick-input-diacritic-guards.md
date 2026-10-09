# Quick input: diacritic guards (review of the quick-input-final-fixes implementation)

Follows `.plan/quick-input-final-fixes.md`; its ground rules still apply: frozen formats (F), flag don't guess, one corpus, probe before done.
Scope: `lib/src/utils/voice_transaction_parser.dart`, `test/voice_transaction_parser_test.dart`, `.codex/project-knowledge/workflows/transaction-input-recurring.md`.
Clock for fixtures: `DateTime(2026, 10, 9)`.

Root cause shared by 1 and 2: the matching runs on normalized text, where `đồ`/`đô`/`do` all become `do` and `bán`/`bạn`/`bàn` all become `ban`. Both checks must look at diacritics, the same way D1 does for type keywords.

## 1. Foreign currency must not match `đồ` (regression, high)

Current: `mua 2 đồ chơi 100k` → amount null, raw note (HEAD: 100,000, note `Mua 2 đồ chơi`).

- [x] Add `static bool _hasForeignCurrency(String raw)` working on `raw.toLowerCase()`:
  - always foreign: `\$\s*\d`, `\d\s*(?:đô|usd|\$)(?![\p{L}0-9])` (unicode);
  - unaccented input only (same detection as `_extractType`): `\d\s*do(?![a-z0-9])` counts only when the chunk has no unit amount (`_amountWithUnit` has no match on the normalized text). So `20 do` → foreign, `mua 20 do an 50k` → not foreign.
- [x] Compute the flag once in `_parseSingle` from `trimmed` and pass it to `_extractAmount`, `_hasExtraAmounts` and `_cleanNote` in place of the three `_foreignCurrency.hasMatch(...)` calls. Remove `_foreignCurrency` if it becomes unused.
- [x] Extract the unaccented detection into a shared `static bool _isUnaccented(String raw)`. Use one static `RegExp` and do not compile one per character (this also covers item 3).

## 2. Unaccented `ban` must not decide the type (medium)

Current: `cafe ban 50k` and `gui ban 50k` → income (HEAD: null).

- [x] In `_extractType`, skip `bán` when the input is unaccented. Unaccented `ban` is ambiguous (bạn/bán/bàn), and the user picks the type on review. Remove the `voi ban` special case; it is no longer needed.
- [x] Accented input is unchanged: `bán xe 5tr` → income, `ăn với bạn 200k` → expense.

## 3. Per-character RegExp in `_extractType` (low)

- [x] Covered by `_isUnaccented` in item 1: one `static final` regex, no behaviour change.

## 4. Corpus rows (`group('Format corpus')`)

| Input | Amount | Type | Note | Flag |
|-------|--------|------|------|------|
| `mua 2 đồ chơi 100k` | 100000 | expense | `Mua 2 đồ chơi` | no |
| `mua 20 đồ ăn 50k` | 50000 | expense | `Mua 20 đồ ăn` | no |
| `mua 20 do an 50k` | 50000 | expense | `Mua 20 do an` | no |
| `20 đô` | null | – | – | no |
| `20 do` | null | – | – | no |
| `cafe 20 usd` | null | – | – | no |
| `cafe ban 50k` | 50000 | null | `Cafe ban` | no |
| `gui ban 50k` | 50000 | null | `Gui ban` | no |
| `an com voi ban 50k` | 50000 | expense | `An com voi ban` | no |
| `ban xe 5tr` | 5000000 | null | `Ban xe` | no |
| `bán xe 5tr` | 5000000 | income | `Bán xe` | no |

- [x] Update any existing row whose expectation changes from item 2 (an unaccented `ban … ` income row, if present) and note it in the commit body.
- [x] If any expected value conflicts with an existing corpus row, the existing frozen-format row wins; record the conflict under "Verification results" and do not invent a new rule.

## 5. Docs

- [x] Section G (knowledge doc): add
  - unaccented `ban` has no type;
  - unaccented `N do` is foreign only when the chunk has no unit amount;
  - a bare count before a bare amount keeps the first number and sets the flag (`mua 3 ly cafe 90000` → 3, flagged; use `90k`);
  - space grouping is disabled only after `phòng N`; `số 12 500` / `bàn 12 500` read as 12,500.
- [x] Bump `Last Verified`.

## 6. Verify

- [x] Write the new rows first and confirm that they fail; then implement.
- [x] `flutter test test/voice_transaction_parser_test.dart test/quick_input_sheet_test.dart`, then `flutter analyze` (info-level lints must be clean too).
- [x] `git diff` vs `git diff -w`: no whitespace-only changes; no new comments.
- [x] Commit only when the user asks. Either fold this into the pending `fix(transactions): freeze quick input formats and past-only dates`, or commit it separately as `fix(transactions): keep diacritics in currency and type guards`.

## Out of scope

- Choosing a unit amount over an earlier bare count when both are bare (`mua 3 ly cafe 90000`) is a limitation, not a fix (rule 2).
- Generalising the `phòng` space-grouping heuristic.

## Verification results

2026-10-10:
- Added 10 rows to the existing corpus (the `20 đô` row was already present): 107 rows total.
- Before implementation: 101 corpus rows passed and 6 failed: `mua 2 đồ chơi 100k`, `mua 20 đồ ăn 50k`, `mua 20 do an 50k`, `cafe ban 50k`, `gui ban 50k`, `ban xe 5tr`.
- After implementation: all 287 parser/widget tests passed; full `flutter analyze` reported no issues.
- No frozen-format conflicts and no existing unaccented `ban` income row required an expectation change.
- Comma splitting also passes a raw-text foreign-currency flag to the amount helper, preserving the same contract across its callers.
- Reviewed the complete parser/test/document diff and compared whitespace-sensitive and whitespace-insensitive diffs; reverted formatter-only changes to existing lines. No comments added; `git diff --check` passed.
- Updated known limitations and Last Verified. Existing unrelated working-tree changes were preserved.
- User requested the commit; folded into `fix(transactions): freeze quick input formats and past-only dates`.
