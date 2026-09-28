import 'package:flutter/services.dart';

class BackgroundService {
  static const MethodChannel _channel =
      MethodChannel('com.example.fitness_tracker/service');

  /// Khởi chạy Foreground Service đếm bước chân liên tục
  static Future<void> startStepCounterService() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (_) {}
  }

  /// Kiểm tra xem ứng dụng đã được miễn trừ tối ưu hóa pin (chạy ngầm không giới hạn) chưa
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool? isIgnoring =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return isIgnoring ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Yêu cầu hệ thống mở hộp thoại / cài đặt để bỏ qua tối ưu hóa pin
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final bool? success =
          await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
