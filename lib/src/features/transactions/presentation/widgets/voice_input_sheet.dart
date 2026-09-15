// path: lib/src/features/transactions/presentation/widgets/voice_input_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/services/voice_input_service.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

/// Bottom sheet: nhấn mic để nói, hiển thị transcript đang nghe, rồi trả
/// về [VoiceParseResult] khi người dùng bấm "Áp dụng". Màn hình gọi luôn
/// để lại quyền review/sửa các trường trước khi lưu giao dịch.
Future<VoiceParseResult?> showVoiceInputSheet(
  BuildContext context, {
  required List<Category> categories,
}) {
  return showModalBottomSheet<VoiceParseResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => VoiceInputSheet(categories: categories),
  );
}

class VoiceInputSheet extends HookWidget {
  const VoiceInputSheet({super.key, required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = useMemoized(() => VoiceInputService());
    useEffect(() => service.dispose, [service]);

    final status = useState(VoiceInputStatus.idle);
    final transcript = useState('');

    Future<void> startListening() async {
      transcript.value = '';
      final ready = await service.initialize();
      if (!ready) {
        status.value = VoiceInputStatus.error;
        return;
      }
      status.value = VoiceInputStatus.listening;
      await service.startListening(
        onResult: (text, isFinal) {
          transcript.value = text;
          if (isFinal) {
            status.value =
                text.trim().isEmpty ? VoiceInputStatus.error : VoiceInputStatus.done;
          }
        },
      );
    }

    useEffect(() {
      startListening();
      return null;
    }, const []);

    final parseResult = transcript.value.trim().isEmpty
        ? null
        : VoiceTransactionParser.parse(transcript.value, categories: categories);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.screenPadding,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.screenPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.voiceInputTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: GestureDetector(
                onTap: status.value == VoiceInputStatus.listening
                    ? null
                    : startListening,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: status.value == VoiceInputStatus.listening
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.mic,
                    size: 36,
                    color: status.value == VoiceInputStatus.listening
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              status.value == VoiceInputStatus.listening
                  ? l10n.voiceInputListening
                  : (transcript.value.isEmpty
                      ? l10n.voiceInputHintIdle
                      : transcript.value),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (status.value == VoiceInputStatus.error) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.voiceInputNoSpeechDetected,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: startListening,
                    child: Text(l10n.voiceInputTryAgain),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: parseResult == null
                        ? null
                        : () => Navigator.of(context).pop(parseResult),
                    child: Text(l10n.voiceInputApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
