# Voice input and recurring transactions

## Quick transaction input

- [VoiceInputService](../../../lib/src/features/transactions/services/voice_input_service.dart) wraps `speech_to_text` with default `vi_VN`. Initialization requires supported hardware and microphone/speech permission; recognition accuracy still needs physical-device validation.
- [voice_input_sheet.dart](../../../lib/src/features/transactions/presentation/widgets/voice_input_sheet.dart) exposes `showQuickInputSheet`, returning `List<VoiceParseResult>?`. Typed input is available immediately; microphone access starts only after tapping Speak. Live previews show amount, date, category, wallet and learned-category confidence. `showVoiceInputSheet` remains a single-result compatibility wrapper.
- [VoiceTransactionParser](../../../lib/src/utils/voice_transaction_parser.dart) exposes compatible `parse` and multi-result `parseMany`, accepting categories, optional wallets/classifier and an injectable clock. Rules support Vietnamese amount slang, relative/explicit dates, income/expense keywords, fuzzy category/wallet names and wallet-type aliases. Currency markers preserve the entered number as VND; there is no FX conversion or transfer recognition.
- [text_similarity.dart](../../../lib/src/utils/text_similarity.dart) normalizes Vietnamese accents while preserving Japanese text and matches one-to-three-token names with a Levenshtein ratio threshold of 0.8.
- Bare weekdays resolve to the most recent occurrence on or before today. Explicit `tuần này` keeps the current week and `tuần trước` keeps the previous week; explicit calendar dates may remain in the future.
- Splitting uses only commas (`,` `，` `、`) not followed by a digit, or between a letter and a digit (`30k,50k`). Decimal and grouped numeric commas stay inside the amount. A cut requires an amount in both the accumulated segment and the next comma-delimited chunk. Conjunctions such as `và` stay intact in names; semicolons, plus signs and newlines do not split. Amountless comma chunks stay with their transaction; fewer than two segments fall back to the whole input. A unique explicit date/wallet propagates to missing segments; conflicting contexts remain local. Notes strip matched amount/date/wallet phrases and preserve original accents, falling back to the raw segment when empty.
- Million-unit aliases (`trieu`, `tr`, `cu`, `m`) and `ty` accept one-to-three trailing digits only when no amount unit follows those digits. Tails scale by digit count relative to the unit (`1tr25` = 1,250,000; `1ty2` = 1,200,000,000). Other units do not consume tails; compound `tram nghin` / `tram ngan` count as one unit of 100,000. Spaced unit amounts keep the first amount, flag extras and remove all matched unit amounts from the note; an empty cleaned note still falls back to the raw segment. The accepted letter-comma-digit split remains `mua 2tr,5 cafe 30k` → 2,000,000 with note `Mua`, then 30,000 with note `5 cafe`.
- Segments with multiple unit-bearing amounts or bare amounts of at least 1000 show a localized extra-amount warning in the input and review sheets. Dates, explicit year/month-year contexts and small bare counts such as `2 ly` are excluded. Ambiguous bare numbers such as room number `1203` can still trigger the warning. The warning does not block saving or insert separators; confirming a manual edit clears it. Notes collapse spaces before punctuation and trim punctuation at their edges.
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
