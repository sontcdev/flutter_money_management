# Voice input and recurring transactions

## Quick transaction input

- [VoiceInputService](../../../lib/src/features/transactions/services/voice_input_service.dart) wraps `speech_to_text` with default `vi_VN`. Initialization requires supported hardware and microphone/speech permission; recognition accuracy still needs physical-device validation.
- [voice_input_sheet.dart](../../../lib/src/features/transactions/presentation/widgets/voice_input_sheet.dart) exposes `showQuickInputSheet`, returning `List<VoiceParseResult>?`. Typed input is available immediately; microphone access starts only after tapping Speak. Live previews show amount, date, category, wallet and learned-category confidence. `showVoiceInputSheet` remains a single-result compatibility wrapper.
- [VoiceTransactionParser](../../../lib/src/utils/voice_transaction_parser.dart) exposes compatible `parse` and multi-result `parseMany`, accepting categories, optional wallets/classifier and an injectable clock. Rules support Vietnamese amount slang, relative/explicit dates, income/expense keywords, fuzzy category/wallet names and wallet-type aliases. VND currency markers preserve the entered number; foreign currency has no amount or conversion. There is no transfer recognition.
- [text_similarity.dart](../../../lib/src/utils/text_similarity.dart) normalizes Vietnamese accents while preserving Japanese text and matches one-to-three-token names with a Levenshtein ratio threshold of 0.8.
### Frozen supported formats

- Amounts: digits plus `k`, `nghìn`/`ngàn`, `trăm`, `trăm nghìn`/`trăm ngàn`, `tr`/`triệu`/`củ`/`m`, `tỷ` or `lít`. Decimal units accept dot or comma (`1.5tr`, `1,5tr`). Integer million/billion amounts accept one-to-three attached tail digits (`1tr2`, `1tr25`, `1tr200`), or a spaced tail only at the end of a chunk (`1 triệu 5`). A tail cannot be followed by another amount unit. Other units and decimal bases do not consume digit tails; rejected tails remain flagged. `rưỡi` immediately after any unit adds half its multiplier and does not combine with a digit tail.
- Grouped digits accept `.`, `,` or single spaces with exactly three digits per group (`30 000`, `1 500 000`), with optional `đ`/`đồng`/`vnd`. Room context (`phòng 12 500`) keeps 12 and flags the second number. Foreign currency (`$20 sách`, `20 đô`, `20 usd`) and amounts at or below zero have a null amount; foreign text remains visible in the note. Explicit year/month-year contexts are excluded from amounts and warnings.
- Dates: `hôm nay`, `hôm qua`, `hôm kia`, `hôm trước`, `ngày mai`, `sáng/trưa/tối nay`, weekdays, `tuần trước`, `N tuần trước` (1–12), `N ngày trước` (1–90), `tháng trước`, `đầu tháng`, `cuối tháng`, `ngày N`, `dd/mm`, `dd/mm/yyyy`, and `ngày N tháng M [năm Y]`. Dates without a year resolve on or before today; `ngày N` searches preceding months when necessary, and a future day/month uses the preceding year. `tháng trước` clamps to the last day of that month. `cuối tháng` uses the most recent month end. Exceptions: explicit years remain unchanged, `ngày mai` is tomorrow, and an explicit weekday with `tuần này` retains the current week. Matched date phrases are removed from notes and excluded from amounts and warnings.
- Splitting: commas (`,` `，` `、`) split only when both chunks carry an amount; numeric decimal/grouping commas remain inside amounts. `và`, `+` and `;` do not split; multiple amounts set the warning. Amountless comma chunks remain attached. A unique date/wallet propagates to missing segments; conflicting contexts remain local.
- Types retain Vietnamese diacritics: `đồng` differs from `đóng`, and `bán` differs from `bạn`. Fully unaccented typing uses normalized keywords; `an voi ban` remains expense. Amount spans, including currency words, are excluded from type matching.
- Notes preserve accents and scripts, remove matched amount/date/wallet phrases and `v.v.`/`etc.`, collapse spaces and trim edge punctuation `,.;:-`. Empty cleaned notes retain the raw chunk. Warnings exclude ordinary small counts beside unit amounts, but retain rejected tails and ambiguous room/year numbers; they allow saving and clear after a confirmed manual edit.

### Known limitations

- Spoken word numbers (`ba mươi nghìn`, `hai triệu`) have a null amount; supported speech transcripts use digits.
- Bare numbers are literal VND (`500` means 500 VND). A bare count before a bare amount retains the first number and flags extras (`mua 3 ly cafe 90000` keeps 3 and warns); use `90k` for the amount.
- Unaccented `ban` does not decide the type; the user chooses on review. Accented `bán` remains income.
- Fully unaccented `N do` is foreign currency only when the chunk has no unit amount; `20 do` has no amount, while `mua 20 do an 50k` keeps 50,000 VND.
- Space grouping is disabled only after `phòng N`; `số 12 500` and `bàn 12 500` read as 12,500 VND.
- `vay`, `cho vay` and `trả nợ` have no type; the user chooses on review.
- `tháng M` alone is note text, not a date.
- Multiple amounts without a comma (`cafe 30k bánh 20k`) retain the first unit amount and flag extras. Unit amounts take precedence over ambiguous bare counts (`tiền nhà 2026 5tr` keeps 5,000,000 and warns).

- Speech-to-text rarely emits commas, so spoken multi-transaction input remains a single transaction unless the user edits the transcript and adds commas. Recognition behavior has not been verified on a physical device.
- [CategoryClassifier](../../../lib/src/features/transactions/services/category_suggestion_service.dart) trains in memory on transaction notes using unigram/bigram Naive Bayes, Laplace smoothing and doubled recent-six-month weights. It excludes transfers, deleted transactions and empty notes, abstains with fewer than three samples or confidence below 0.65, and filters predictions against current eligible categories/wallets. Explicit rules take precedence. Wallet votes are a fallback.
- [categoryClassifierProvider](../../../lib/src/features/transactions/providers/transaction_providers.dart) derives from `transactionsProvider`; core-provider invalidation rebuilds it without an additional query. [AddTransactionScreen](../../../lib/src/features/transactions/presentation/screens/add_transaction_screen.dart) uses it only when the selected workspace equals the active workspace and history has loaded.
- Single results fill the existing form, including the source wallet; the user saves explicitly. Multiple results open [quick_input_review_sheet.dart](../../../lib/src/features/transactions/presentation/widgets/quick_input_review_sheet.dart) for editing/removing. Saving requires a positive amount, matching category/type and eligible wallet, then calls the existing repository sequentially with the captured workspace override and budget confirmation. Confirmed saves are removed; declined/failed items remain for review or retry. It is not an atomic batch and does not provide server-side idempotency for ambiguous network failures. Batch items do not attach the form's receipt.
- No new dependencies, persistence, backend, schema or external classifier API. Speech recognition uses the existing operating-system service.
- [benchmark_natural_language_input.dart](../../../tool/benchmark_natural_language_input.dart) measures synthetic 5,000-transaction training and 1,000 warmed parses. Run `dart run tool/benchmark_natural_language_input.dart`; desktop timings are not mobile performance evidence.
- Run `flutter run -d <device-id> -t tool/quick_input_preview.dart` for synthetic-data typed/speech verification with optional history. It does not query or save backend data.

## Recurring flow

- [RecurringTransactionService](../../../lib/src/features/recurring/services/recurring_transaction_service.dart) chuẩn hóa ngày/tính kỳ qua [RecurringScheduleCalculator](../../../lib/src/features/recurring/services/recurring_schedule_calculator.dart), lưu rule rồi generate occurrences trong 30 ngày.
- [RecurringTransactionRepository](../../../lib/src/features/recurring/repositories/recurring_transaction_repository.dart) gọi RPC workspace-scoped để generate, skip và complete occurrences.
- Confirm occurrence tạo transaction trước, sau đó đánh dấu complete bằng generated transaction ID và generate tiếp. Đây là các request riêng, không phải một transaction nguyên tử phía client.
- Giới hạn hiện tại: `confirmOccurrence()` tạo Transaction không có `walletId`, dù schema mới yêu cầu wallet; cần đối chiếu luồng này khi xử lý lỗi recurring với wallets. RAG ghi nhận source, không coi tính năng này đã được xác minh chạy thành công.
- [RecurringReminderService](../../../lib/src/features/recurring/services/recurring_reminder_service.dart) xử lý reminders; lifecycle coordinator gọi đồng bộ reminders và refresh notification providers.
- [notification_providers.dart](../../../lib/src/features/notifications/providers/notification_providers.dart) và [notification_service.dart](../../../lib/src/features/notifications/services/notification_service.dart) là entrypoints thông báo.

## Focused tests

- [voice_transaction_parser_test.dart](../../../test/voice_transaction_parser_test.dart)
- [text_similarity_test.dart](../../../test/text_similarity_test.dart)
- [category_suggestion_service_test.dart](../../../test/category_suggestion_service_test.dart)
- [quick_input_sheet_test.dart](../../../test/quick_input_sheet_test.dart)

- [recurring_schedule_calculator_test.dart](../../../test/recurring_schedule_calculator_test.dart)
- [recurring_transaction_service_test.dart](../../../test/recurring_transaction_service_test.dart)
- [recurring_reminder_service_test.dart](../../../test/recurring_reminder_service_test.dart)
- [recurring_transaction_edit_screen_test.dart](../../../test/recurring_transaction_edit_screen_test.dart)
- [recurring_transactions_screen_test.dart](../../../test/recurring_transactions_screen_test.dart)

## Last Verified

2026-10-09 — quick-input source contracts, clean full analysis, 140 passing tests with coverage and successful release APK build. Focused tests cover typed field application, cold-start/history workspace isolation, batch editing/removal, partial-save retry, budget cancellation/override and compact light/dark layouts with keyboard and large text. Android emulator checks verify typed input, synthetic history suggestions and typing after microphone permission denial. Physical-device Vietnamese speech and live authenticated workspace behavior remain unverified; the user authorized emulator validation and temporarily accepted human-operated procedures on 2026-10-09 for Phase 6 completion. Recurring source notes above are unchanged; notification/device behavior was not revalidated.

2026-10-09 — review fixes verified with 106 passing parser tests and clean full analysis. Regression tests cover past bare weekdays, explicit week/calendar behavior, category-name conjunctions, numeric commas and amountless trailing text. Human-operated verification remains temporarily accepted under the user instruction above; this acceptance does not establish physical-device speech accuracy.

2026-10-09 — amount-first splitting review fix verified with 110 passing parser tests and clean full analysis. Tests cover amount-first category names, amount-first transactions on both sides, all Fix 2 examples, trailing text and the documented mixed-phrasing limitation.

2026-10-09 — comma-only splitting verified with 121 passing parser/widget tests and clean full analysis. Tests cover every retired separator, conjunctions in category names, amountless comma chunks, numeric commas, shared/conflicting contexts and batch review. Human-operated procedures remain temporarily accepted; physical-device speech accuracy remains unverified.

2026-10-09 — extra-amount warnings, comma edge cases, punctuation-adjacent dates and note cleanup verified with 144 passing parser/widget tests and clean full analysis. Warning checks cover light/dark themes, compact layouts with keyboard and enlarged text, saving and confirmed edits. Android emulator preview builds and launches; typed multi-amount input shows the warning, while comma-separated input produces two results without it. Human-operated procedures remain temporarily accepted; physical-device speech accuracy remains unverified.

2026-10-09 — unit-tail scaling, compound units, spaced amounts, year warning filters and accepted comma splitting verified with 166 passing parser/widget tests and clean full analysis. Android emulator preview builds and launches; `cafe 30k 50k` keeps 30,000 VND, cleans the note to `Cafe` and shows the warning; `cafe 1tr200` shows 1,200,000 VND with no warning. Human-operated procedures remain temporarily accepted; physical-device speech remains unverified.

2026-10-09 — tail guards verified with 180 passing parser/widget tests and clean full analysis. Fixtures cover integer-only million/billion tails, plain `tram`, decimals, end-of-chunk spaced tails, preserved count notes, rejected-tail warnings and unchanged comma splitting. Android emulator preview builds and launches; `mua 1tr 2 cai ao` keeps 1,000,000 VND, note `Mua 2 cai ao` and the warning, while `cafe 1tr 2` shows 1,200,000 VND, note `Cafe` and no warning. Human-operated procedures remain temporarily accepted; physical-device speech remains unverified.

2026-10-10 — final consolidated formats verified against [voice_transaction_parser.dart](../../../lib/src/utils/voice_transaction_parser.dart), [voice_transaction_parser_test.dart](../../../test/voice_transaction_parser_test.dart) and [quick_input_sheet_test.dart](../../../test/quick_input_sheet_test.dart): 97 frozen-format corpus rows, 277 passing parser/widget tests and clean full analysis. Android emulator synthetic preview builds and launches; typed `cafe 1 500 000` displays 1,500,000 VND with note `Cafe`. Human-operated procedures remain temporarily accepted; physical-device speech remains unverified. Existing explicit-year and explicit-week exceptions are documented above.

2026-10-10 — diacritic currency/type guards verified against the parser and parser/widget tests: 107 frozen-format corpus rows, 287 passing tests and clean full analysis. `đồ` no longer triggers foreign currency; unaccented `ban` leaves type undecided. Raw-text currency guards also apply during comma splitting. Physical-device speech remains unverified.
