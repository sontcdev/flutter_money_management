# Natural-Language Transaction Input (no AI, on-device, $0)

## Goal

Let users type or speak a sentence such as `ăn trưa 50k hôm qua ví momo` or
`cafe 30k và grab 45k` and get a pre-filled, reviewable transaction form.
Everything runs on-device with rule-based parsing, fuzzy matching and a
Naive Bayes classifier trained on the user's own transaction history.
No LLM, no network calls, no new backend, no schema change.

## Current State (verified 2026-10-09)

- `lib/src/utils/voice_transaction_parser.dart`: static `VoiceTransactionParser.parse(text, categories:)`
  returns `VoiceParseResult { rawText, amountVnd, date, type, categoryId, categoryName, note }`.
  - Date: only `hom nay`, `hom qua`, `hom kia`.
  - Amount: `tr/trieu (+sub)`, `k/nghin/ngan`, grouped digits, plain digits.
  - Type: keyword lists for income/expense.
  - Category: exact token overlap + small `_categorySynonyms` table.
  - Note: always the full raw text.
- `lib/src/features/transactions/presentation/widgets/voice_input_sheet.dart`: speech only, parses live, returns one result.
- `lib/src/features/transactions/presentation/screens/add_transaction_screen.dart:243` `handleVoiceInput()` applies type/date/amount/category/note. Wallet is not applied.
- `transactionsProvider` already loads all transactions of the active workspace (`getAllTransactions()`), so history is available without a new query.
- Tests: `test/voice_transaction_parser_test.dart` (amount/date/type/category groups).

## Design

```
text ──► Normalizer ──► Splitter ──► per segment:
                                     ├─ AmountExtractor   (rules)
                                     ├─ DateExtractor     (rules)
                                     ├─ TypeExtractor     (rules)
                                     ├─ WalletMatcher     (fuzzy on wallet names)
                                     ├─ CategoryResolver  (1. name/synonym match
                                     │                     2. Naive Bayes on history
                                     │                     3. null)
                                     └─ NoteCleaner       (strip amount/date/wallet tokens)
                                   ──► List<VoiceParseResult>
```

Key decisions:
- Keep `VoiceTransactionParser.parse(...)` signature and behavior compatible; add optional params (`wallets`, `classifier`) and a new `parseMany(...)`. Existing tests must keep passing.
- Classifier is pure Dart, built in memory from `transactionsProvider` data; no persistence (rebuild is cheap: O(n tokens)).
- Fuzzy matching: implement a small Levenshtein/token-similarity helper in `lib/src/utils/` instead of adding a dependency (`fuzzywuzzy` has unknown license and low maintenance; `rapidfuzz` is 0.1.x). Revisit only if quality is insufficient.
- Rules reference: port relevant patterns and test sentences from Duckling `Duckling/Time/VI` and `AmountOfMoney/VI` corpora (BSD license; rewrite, don't copy code).
- AI output never auto-saves: user always reviews in the add screen (existing contract).

## Steps

### Phase 0 — Prep
- [x] Re-read `CODING_CONVENTIONS.md` and `.codex/project-knowledge/workflows/transaction-input-recurring.md`.
- [x] Collect a test corpus of ~60 real sentences (vi with/without diacritics, en, ja basics) into the test file as fixtures; mark expected amount/date/type/category/wallet.

### Phase 1 — Stronger rules (parser only, no UI)
- [ ] Amount: support `củ`, `lít` (=100k slang), `tỷ`, `trăm` (`5 trăm` = 500k context), `1tr2`, `2m`, `50.5k`, `$`/`đ`/`vnd` suffixes; choose the number nearest to an amount unit instead of the first digit (avoid matching `2` in `thứ 2`).
- [ ] Date: `ngày mai`, `hôm trước`, `thứ 2..CN (tuần này/tuần trước)`, `tuần trước`, `đầu/cuối tháng`, `ngày 15`, `15/9`, `15-9-2026`, `sáng/trưa/tối nay` (date only).
- [ ] Type: add income keywords (`được cho`, `lãi`, `cổ tức`, `nhận chuyển khoản`) and expense ones (`đổ xăng`, `ship`, `phí`); negative context (`trả lại cho tôi` → income).
- [ ] Make `now` injectable (`DateTime Function() clock` param, default `DateTime.now`) for deterministic date tests.
- [ ] Unit tests for every new pattern.

### Phase 2 — Fuzzy wallet & category name matching
- [ ] Add `lib/src/utils/text_similarity.dart`: `normalizeVi()` (move/reuse `_normalize`), Levenshtein ratio, best-match helper with threshold.
- [ ] Add `wallets` param to `parse`; add `walletId`/`walletName` to `VoiceParseResult` (plain class, no codegen).
- [ ] Wallet match: n-gram (1–3 tokens) vs wallet names, ratio ≥ 0.8, plus aliases (`ck`/`chuyển khoản` → bank-type wallet, `tiền mặt`/`cash`).
- [ ] Category match: replace exact token overlap with fuzzy token match (handles `cafe`/`ca phe`/`cà fê`), keep synonym table.
- [ ] Tests: typos, missing diacritics, multi-word wallet names.

### Phase 3 — Learn from history (Naive Bayes)
- [ ] Add `lib/src/features/transactions/services/category_suggestion_service.dart`:
  - `CategoryClassifier.train(List<Transaction>)` — features = normalized unigrams + bigrams of `note` (strip numbers/date words); label = `categoryId`; also learn `walletId` per category/token for wallet fallback.
  - Multinomial Naive Bayes with Laplace smoothing, log-probabilities; ignore transfers and empty notes; recency weight (e.g. last 6 months ×2).
  - `predict(text, {CategoryType? type}) → (categoryId, confidence)`; return null under min confidence or with < N training samples.
- [ ] Add `categoryClassifierProvider` (FutureProvider) in `transactions/providers/transaction_providers.dart`, derived from `transactionsProvider`; auto-invalidated through `invalidateCoreDataProviders`.
- [ ] `CategoryResolver` order: explicit name/synonym match (high confidence) → classifier → null.
- [ ] Tests with `_txn(...)` factory helpers: learns `cà phê` → Ăn uống, respects type filter, returns null on cold start, handles deleted categories (id not in current list → ignore).

### Phase 4 — Multiple transactions in one sentence
- [ ] Splitter on `và`, `,`, `;`, `+`, `rồi`, `xong`, newline — only when each segment has its own amount; shared date/wallet propagate to segments missing them (`hôm qua cafe 30k và ăn trưa 50k`).
- [ ] `VoiceTransactionParser.parseMany(...) → List<VoiceParseResult>`; `parse` = first item for backward compatibility.
- [ ] Note cleaner: remove matched amount/date/wallet phrases, capitalize, fallback to raw segment.
- [ ] Tests for splitting and propagation.

### Phase 5 — UI
- [ ] Add a text input mode to the input sheet (rename to a generic "quick input" sheet or add a text field + mic toggle); live preview chips: amount · date · category · wallet, with confidence hint for learned category.
- [ ] `add_transaction_screen.dart` `handleVoiceInput()`: also apply `walletId` (only if wallet exists in the selected workspace).
- [ ] Multi-result: if > 1 result, show a review list (edit/remove each) and save sequentially through the existing create path; reuse budget-exceeded handling. Decide: batch save in sheet vs. open add screen per item — prefer review list with batch save.
- [ ] Entry point from home/transactions FAB (optional, small).
- [ ] l10n: add all strings to `app_en.arb`, `app_vi.arb`, `app_ja.arb`; run `flutter gen-l10n`.
- [ ] Widget test for the sheet (text mode → apply → fields filled).

### Phase 6 — Validation & docs
- [ ] `flutter analyze` clean (infos fail CI).
- [ ] `flutter test test/voice_transaction_parser_test.dart` + new test files, then `flutter test --coverage`.
- [ ] Manual run on device: vi speech, typed text without diacritics, cold-start workspace (no history), workspace with history.
- [ ] Measure: classifier train time with 5k transactions (< 50 ms target), parse time (< 5 ms).
- [ ] Update `.codex/project-knowledge/workflows/transaction-input-recurring.md` (parser contract, classifier, `Last Verified`).
- [ ] Update `AGENTS.md` test list if new test files are added.

## Risks / Open Points
- Add screen can target a workspace different from the active one; classifier is trained on the active workspace — only use predictions when `selectedWorkspaceId == activeWorkspaceId`.
- Cold start: new users get no learned suggestions; synonyms table still applies.
- Shared workspaces: history mixes members' habits — acceptable (same category set).
- Japanese/English input: rules are vi-first; classifier is language-agnostic so it still helps once history exists.
- Privacy: everything on-device; no Data Safety change.

## Estimate
Phase 1: 0.5d · Phase 2: 0.5d · Phase 3: 0.5–1d · Phase 4: 0.5d · Phase 5: 1d · Phase 6: 0.5d → ~3.5–4 days.

## Execution evidence

- Phase 0: 60 representative fixtures recorded in `test/voice_transaction_parser_test.dart`, including Vietnamese, English, and Japanese. These are synthetic acceptance examples, not collected private user data. First 16 preserve baseline amount/type expectations; later phases activate the expanded expectations. Date offsets use 2026-10-09.
