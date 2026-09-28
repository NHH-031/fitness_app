import 'package:flutter/services.dart';

class WidgetSyncService {
  static const MethodChannel _channel =
      MethodChannel('com.example.fitness_tracker/service');

  /// Đồng bộ tức thì dữ liệu bước chân và nước uống ra màn hình chính Android (Home Widget)
  static Future<void> updateHomeWidget() async {
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }
}
