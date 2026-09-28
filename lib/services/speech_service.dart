import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> initialize({
    Function(String status)? onStatus,
    Function(String error)? onError,
  }) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          onStatus?.call(status);
        },
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          onError?.call(error.errorMsg);
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech initialization exception: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final ready = await initialize();
      if (!ready) return;
    }

    // Default to English locale
    String targetLocale = localeId ?? 'en_US';
    try {
      final locales = await _speech.locales();
      final hasEnglish = locales.any((l) => l.localeId.startsWith('en'));
      if (!hasEnglish && locales.isNotEmpty) {
        final systemLocale = await _speech.systemLocale();
        if (systemLocale != null) {
          targetLocale = systemLocale.localeId;
        }
      }
    } catch (_) {
      // Ignore locale check error if device does not support it
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: targetLocale,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
