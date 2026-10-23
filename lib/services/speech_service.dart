import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'locale_service.dart';

/// Nhận dạng giọng nói qua SpeechRecognizerBridge (Kotlin).
/// Native ưu tiên dịch vụ của Google vì dịch vụ mặc định của một số hãng (vd. Xiaomi)
/// bỏ qua tiếng Việt.
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.example.fitness_tracker/speech');
  static const EventChannel _eventChannel =
      EventChannel('com.example.fitness_tracker/speech_events');

  StreamSubscription<dynamic>? _subscription;
  bool _isInitialized = false;
  bool _isListening = false;

  // Chỉ một widget dùng micro tại một thời điểm: giữ callback của widget đó
  // để mỗi lần startListening gắn lại cho đúng widget.
  Function(String status)? _onStatus;
  Function(String error)? _onError;
  Function(String text, bool isFinal)? _onResult;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> initialize({
    Function(String status)? onStatus,
    Function(String error)? onError,
  }) async {
    _onStatus = onStatus ?? _onStatus;
    _onError = onError ?? _onError;
    if (_isInitialized) return true;

    try {
      final available = await _channel.invokeMethod<bool>('isAvailable') ?? false;
      if (!available) return false;
      _subscription ??= _eventChannel.receiveBroadcastStream().listen(
            _handleEvent,
            onError: (Object e) => debugPrint('Speech event error: $e'),
          );
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Speech initialization exception: $e');
      return false;
    }
  }

  /// Trả về false khi máy không có dịch vụ nhận dạng giọng nói hoặc chưa cấp quyền micro.
  Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String status)? onStatus,
    Function(String error)? onError,
    String? localeId,
  }) async {
    final ready = await initialize(onStatus: onStatus, onError: onError);
    if (!ready) return false;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    _onResult = onResult;
    final locale = localeId ?? (LocaleService.isVietnamese ? 'vi-VN' : 'en-US');
    try {
      final started =
          await _channel.invokeMethod<bool>('start', {'locale': locale}) ?? false;
      _isListening = started;
      return started;
    } catch (e) {
      debugPrint('Speech start exception: $e');
      return false;
    }
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final value = event['value'] as String? ?? '';
    switch (event['type']) {
      case 'status':
        if (value == 'done' || value == 'notListening') _isListening = false;
        debugPrint('Speech status: $value');
        _onStatus?.call(value);
      case 'result':
        _onResult?.call(event['text'] as String? ?? '', event['final'] == true);
      case 'error':
        _isListening = false;
        debugPrint('Speech error: $value');
        _onError?.call(value);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('Speech stop exception: $e');
    }
  }

  Future<void> cancelListening() async {
    if (!_isListening) return;
    _isListening = false;
    try {
      await _channel.invokeMethod('cancel');
    } catch (e) {
      debugPrint('Speech cancel exception: $e');
    }
  }
}
