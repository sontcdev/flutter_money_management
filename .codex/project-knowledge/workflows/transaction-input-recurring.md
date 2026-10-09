# Voice input and recurring transactions

## Quick transaction input

- [VoiceInputService](../../../lib/src/features/transactions/services/voice_input_service.dart) wraps `speech_to_text` with default `vi_VN`. Initialization requires supported hardware and microphone/speech permission; recognition accuracy still needs physical-device validation.
- [voice_input_sheet.dart](../../../lib/src/features/transactions/presentation/widgets/voice_input_sheet.dart) exposes `showQuickInputSheet`, returning `List<VoiceParseResult>?`. Typed input is available immediately; microphone access starts only after tapping Speak. Live previews show amount, date, category, wallet and learned-category confidence. `showVoiceInputSheet` remains a single-result compatibility wrapper.
- [VoiceTransactionParser](../../../lib/src/utils/voice_transaction_parser.dart) exposes compatible `parse` and multi-result `parseMany`, accepting categories, optional wallets/classifier and an injectable clock. Rules support Vietnamese amount slang, relative/explicit dates, income/expense keywords, fuzzy category/wallet names and wallet-type aliases. Currency markers preserve the entered number as VND; there is no FX conversion or transfer recognition.
- [text_similarity.dart](../../../lib/src/utils/text_similarity.dart) normalizes Vietnamese accents while preserving Japanese text and matches one-to-three-token names with a Levenshtein ratio threshold of 0.8.
- Bare weekdays resolve to the most recent occurrence on or before today. Explicit `tuần này` keeps the current week and `tuần trước` keeps the previous week; explicit calendar dates may remain in the future.
- Splitting cuts only when both the accumulated segment and the next chunk (up to the following separator or end of input) contain an amount. This preserves conjunctions in names in category-first and amount-first input. Amountless trailing text stays with the last segment; fewer than two segments fall back to the whole input. Mixed phrasing such as `cafe 30k và ăn trưa và uống 50k` remains ambiguous: it splits at the last `và`, yielding `cafe 30k và ăn trưa` and `uống 50k`. A unique explicit date/wallet propagates to missing segments; conflicting contexts remain local. Notes strip matched amount/date/wallet phrases and preserve original accents, falling back to the raw segment when empty.
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
