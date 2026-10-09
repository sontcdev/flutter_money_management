// path: lib/src/features/transactions/presentation/widgets/voice_input_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/services/voice_input_service.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/transactions/services/category_suggestion_service.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

/// Bottom sheet: nhấn mic để nói, hiển thị transcript đang nghe, rồi trả
/// về [VoiceParseResult] khi người dùng bấm "Áp dụng". Màn hình gọi luôn
/// để lại quyền review/sửa các trường trước khi lưu giao dịch.
Future<VoiceParseResult?> showVoiceInputSheet(
  BuildContext context, {
  required List<Category> categories,
}) async {
  final results = await showQuickInputSheet(context, categories: categories);
  return results?.firstOrNull;
}

Future<List<VoiceParseResult>?> showQuickInputSheet(
  BuildContext context, {
  required List<Category> categories,
  List<Wallet> wallets = const [],
  CategoryClassifier? classifier,
}) {
  return showModalBottomSheet<List<VoiceParseResult>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => VoiceInputSheet(
      categories: categories,
      wallets: wallets,
      classifier: classifier,
    ),
  );
}

class VoiceInputSheet extends HookWidget {
  const VoiceInputSheet({
    super.key,
    required this.categories,
    this.wallets = const [],
    this.classifier,
  });

  final List<Category> categories;
  final List<Wallet> wallets;
  final CategoryClassifier? classifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = useMemoized(() => VoiceInputService());
    useEffect(() => service.dispose, [service]);
    final controller = useTextEditingController();
    useListenable(controller);
    final status = useState(VoiceInputStatus.idle);
    final initializing = useState(false);
    final errorText = useState<String?>(null);

    Future<void> toggleListening() async {
      if (status.value == VoiceInputStatus.listening) {
        await service.stopListening();
        if (context.mounted) status.value = VoiceInputStatus.done;
        return;
      }
      errorText.value = null;
      initializing.value = true;
      final ready = await service.initialize();
      if (!context.mounted) return;
      initializing.value = false;
      if (!ready) {
        errorText.value = l10n.voiceInputPermissionDenied;
        status.value = VoiceInputStatus.error;
        return;
      }
      status.value = VoiceInputStatus.listening;
      await service.startListening(
        onResult: (text, isFinal) {
          if (!context.mounted) return;
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
          if (isFinal) {
            errorText.value =
                text.trim().isEmpty ? l10n.voiceInputNoSpeechDetected : null;
            status.value = text.trim().isEmpty
                ? VoiceInputStatus.error
                : VoiceInputStatus.done;
          }
        },
      );
    }

    final results = controller.text.trim().isEmpty
        ? const <VoiceParseResult>[]
        : VoiceTransactionParser.parseMany(
            controller.text,
            categories: categories,
            wallets: wallets,
            classifier: classifier,
          );

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.screenPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.quickInputTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              enabled: status.value != VoiceInputStatus.listening,
              decoration: InputDecoration(
                labelText: l10n.quickInputTextLabel,
                hintText: l10n.quickInputExample,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: initializing.value ? null : toggleListening,
              icon: Icon(status.value == VoiceInputStatus.listening
                  ? Icons.stop
                  : Icons.mic_none_outlined),
              label: Text(status.value == VoiceInputStatus.listening
                  ? l10n.quickInputStop
                  : l10n.quickInputSpeak),
            ),
            if (status.value == VoiceInputStatus.listening)
              Text(l10n.voiceInputListening),
            if (status.value == VoiceInputStatus.error)
              Text(errorText.value ?? l10n.voiceInputNoSpeechDetected,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            for (final result in results) ...[
              const SizedBox(height: AppSpacing.md),
              Text(result.note ?? result.rawText),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  if (result.amountVnd != null)
                    Chip(
                        label: Text(
                            CurrencyFormatter.formatVND(result.amountVnd!))),
                  if (result.date != null)
                    Chip(
                        label:
                            Text(formatLocalizedDate(context, result.date!))),
                  if (result.categoryName != null)
                    Chip(label: Text(result.categoryName!)),
                  if (result.walletName != null)
                    Chip(label: Text(result.walletName!)),
                ],
              ),
              if (result.categoryConfidence != null)
                Text(l10n.quickInputLearned(
                    (result.categoryConfidence! * 100).round())),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: results.isEmpty ||
                      status.value == VoiceInputStatus.listening ||
                      initializing.value
                  ? null
                  : () => Navigator.of(context).pop(results),
              child: Text(results.length > 1
                  ? l10n.quickInputReview
                  : l10n.voiceInputApply),
            ),
          ],
        ),
      ),
    );
  }
}
