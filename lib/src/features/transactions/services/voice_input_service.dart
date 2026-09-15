// path: lib/src/features/transactions/services/voice_input_service.dart

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_money_management/src/utils/app_logger.dart';

/// Trạng thái nhận diện giọng nói hiện tại.
enum VoiceInputStatus { idle, listening, done, error }

/// Bọc package `speech_to_text` cho luồng nhập giao dịch bằng giọng nói.
/// Mỗi lần gọi [startListening] tạo một phiên nghe mới; transcript tạm
/// thời được báo qua [onResult] cho tới khi người dùng ngừng nói.
class VoiceInputService {
  VoiceInputService() : _speech = stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _isInitialized = false;

  /// Khởi tạo engine speech-to-text và xin quyền mic/nhận diện giọng nói.
  /// Trả về false nếu thiết bị không hỗ trợ hoặc người dùng từ chối quyền.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => AppLogger.warn(
          'Speech recognition error: ${error.errorMsg}',
          name: 'MM.Voice',
        ),
        onStatus: (status) =>
            AppLogger.debug('Speech recognition status: $status', name: 'MM.Voice'),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize speech recognition',
        name: 'MM.Voice',
        error: e,
        stackTrace: stackTrace,
      );
      _isInitialized = false;
    }
    return _isInitialized;
  }

  bool get isListening => _speech.isListening;

  /// Bắt đầu nghe. [onResult] được gọi liên tục với transcript hiện tại
  /// ([isFinal] = true khi người dùng đã ngừng nói / hết thời gian chờ).
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'vi_VN',
  }) async {
    final ready = await initialize();
    if (!ready) return;

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        localeId: localeId,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  void dispose() {
    _speech.cancel();
  }
}
