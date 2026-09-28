import 'package:flutter/services.dart';

class AppHaptics {
  /// Nhấp nhẹ khi chạm chọn tab hoặc toggle nhỏ
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Phản hồi vừa khi bấm nút chính, thêm bớt nước
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Phản hồi mạnh khi hoàn thành bài tập, đạt mục tiêu
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Rung thành công (mở khóa huy hiệu, ghi nhận món ăn)
  static Future<void> success() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Nhấp phản hồi lựa chọn (picker, date navigation)
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
