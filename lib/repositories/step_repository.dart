import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_metrics_service.dart';

/// Repository quản lý bước chân, cảm biến phần cứng, thuật toán chống rung xe và lịch sử số bước.
class StepRepository {
  StepRepository._();
  static final StepRepository instance = StepRepository._();

  static const String _keyStepBaselineHardware = 'step_baseline_hardware';
  static const String _keyStepBaselineDate = 'step_baseline_date';
  static const String _keyTodaySteps = 'today_steps';
  static const String _keyStepRebootOffset = 'step_reboot_offset';
  static const String _keyDailyStepsHistory = 'daily_steps_history';

  // In-memory cache O(1)
  static Map<String, int>? _cachedDailyStepsMap;

  // Trạng thái lọc rung và chống quá tải đĩa (Anti-jitter & Debounce)
  static int? _lastHardwareReading;
  static DateTime? _lastReadingTime;
  static int? _lastPersistedSteps;
  static DateTime? _lastPersistTime;

  @visibleForTesting
  static bool disableAntiJitterForTesting = false;

  /// Xóa sạch bộ nhớ đệm ram
  static void invalidateCache() {
    _cachedDailyStepsMap = null;
    _lastHardwareReading = null;
    _lastReadingTime = null;
    _lastPersistedSteps = null;
    _lastPersistTime = null;
  }

  static String _formatDate([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Lấy số bước chân của ngày hôm nay
  Future<int> getTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    final savedDate = prefs.getString(_keyStepBaselineDate);
    if (savedDate != todayStr) {
      return 0;
    }
    return prefs.getInt(_keyTodaySteps) ?? 0;
  }

  /// Lưu số bước chân hôm nay
  Future<void> saveTodaySteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    await prefs.setString(_keyStepBaselineDate, todayStr);
    await prefs.setInt(_keyTodaySteps, steps);
    await saveDailySteps(todayStr, steps);
    _lastPersistedSteps = steps;
    _lastPersistTime = DateTime.now();
  }

  /// Tính toán và xử lý số bước từ cảm biến phần cứng (Hardware Step Counter)
  /// Tích hợp Anti-Jitter Rate Limiter và xử lý Reboot của điện thoại
  Future<int> processHardwareSteps(int hardwareSteps) async {
    if (hardwareSteps <= 0) return await getTodaySteps();

    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    final savedDate = prefs.getString(_keyStepBaselineDate);
    int? baseline = prefs.getInt(_keyStepBaselineHardware);
    int rebootOffset = prefs.getInt(_keyStepRebootOffset) ?? 0;

    // TRƯỜNG HỢP 1: Sang ngày mới hoặc lần đầu khởi động
    if (savedDate != todayStr || baseline == null) {
      baseline = hardwareSteps;
      rebootOffset = 0;
      await prefs.setString(_keyStepBaselineDate, todayStr);
      await prefs.setInt(_keyStepBaselineHardware, baseline);
      await prefs.setInt(_keyStepRebootOffset, 0);
      await prefs.setInt(_keyTodaySteps, 0);
      _lastHardwareReading = hardwareSteps;
      _lastReadingTime = DateTime.now();
      _lastPersistedSteps = 0;
      _lastPersistTime = DateTime.now();
      return 0;
    }

    // TRƯỜNG HỢP 2: Thiết bị khởi động lại (Reboot) khiến counter nhỏ hơn baseline
    if (hardwareSteps < baseline) {
      final previousToday = prefs.getInt(_keyTodaySteps) ?? 0;
      rebootOffset = previousToday;
      baseline = hardwareSteps;
      await prefs.setInt(_keyStepBaselineHardware, baseline);
      await prefs.setInt(_keyStepRebootOffset, rebootOffset);
    }

    // TRƯỜNG HỢP 3: Bộ lọc chống sốc / rung xe (Anti-Jitter / Cadence Rate Limiter)
    final now = DateTime.now();
    int sanitizedHardware = hardwareSteps;
    if (!disableAntiJitterForTesting && _lastHardwareReading != null && _lastReadingTime != null) {
      final elapsedMs = now.difference(_lastReadingTime!).inMilliseconds;
      final rawDiff = hardwareSteps - _lastHardwareReading!;
      if (elapsedMs > 0 && rawDiff > 0) {
        final elapsedSeconds = elapsedMs / 1000.0;
        final maxAllowedDiff = max(3, (elapsedSeconds * 5.0).round());
        if (rawDiff > maxAllowedDiff) {
          sanitizedHardware = _lastHardwareReading! + maxAllowedDiff;
        }
      }
    }
    _lastHardwareReading = sanitizedHardware;
    _lastReadingTime = now;

    final int calculatedSteps = (rebootOffset + (sanitizedHardware - baseline)).clamp(0, 100000);

    // Debounced disk saving: Giảm thiểu ghi I/O liên tục
    final bool shouldPersist = _lastPersistedSteps == null ||
        (calculatedSteps - _lastPersistedSteps!).abs() >= 3 ||
        _lastPersistTime == null ||
        now.difference(_lastPersistTime!).inSeconds >= 2;

    if (shouldPersist) {
      _lastPersistedSteps = calculatedSteps;
      _lastPersistTime = now;
      await prefs.setInt(_keyTodaySteps, calculatedSteps);
      await saveDailySteps(todayStr, calculatedSteps);
    }

    return calculatedSteps;
  }

  /// Ghi đè tức thì bước chân xuống đĩa
  Future<void> flushHardwareSteps() async {
    if (_lastPersistedSteps != null) {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _formatDate();
      await prefs.setInt(_keyTodaySteps, _lastPersistedSteps!);
      await saveDailySteps(todayStr, _lastPersistedSteps!);
    }
  }

  /// Lưu trữ số bước chân theo ngày YYYY-MM-DD
  Future<void> saveDailySteps(String dateStr, int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getStringList(_keyDailyStepsHistory) ?? [];
    List<Map<String, dynamic>> logs = [];
    for (final s in rawLogs) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        logs.add(m);
      } catch (_) {}
    }

    logs.removeWhere((m) => m['date'] == dateStr);
    logs.add({
      'date': dateStr,
      'steps': steps,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (logs.length > 90) {
      logs.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      logs = logs.sublist(0, 90);
    }

    final encoded = logs.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_keyDailyStepsHistory, encoded);

    // Cập nhật ram cache
    _cachedDailyStepsMap ??= {};
    _cachedDailyStepsMap![dateStr] = steps;
  }

  /// Lấy số bước chân theo ngày DateTime
  Future<int> getStepsByDate(DateTime date) async {
    final dateStr = _formatDate(date);
    if (dateStr == _formatDate()) {
      return await getTodaySteps();
    }

    final map = await getDailyStepsMap();
    return map[dateStr] ?? 0;
  }

  /// Lấy bản đồ lịch sử các ngày bước chân
  Future<Map<String, int>> getDailyStepsMap() async {
    if (_cachedDailyStepsMap != null) {
      return Map.from(_cachedDailyStepsMap!);
    }

    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getStringList(_keyDailyStepsHistory) ?? [];
    final Map<String, int> map = {};

    for (final s in rawLogs) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final d = m['date']?.toString();
        final st = (m['steps'] as num?)?.toInt() ?? 0;
        if (d != null) {
          map[d] = st;
        }
      } catch (_) {}
    }

    _cachedDailyStepsMap = map;
    return Map.from(map);
  }

  /// Ước tính calo tiêu hao từ số bước
  int calculateStepCalories(int steps, {double weightKg = 70.0}) {
    return UserMetricsService.calculateStepCalories(steps, weightKg: weightKg);
  }

  /// Ước tính khoảng cách đi được (km) từ số bước
  double calculateStepDistanceKm(int steps, {double heightCm = 175.0}) {
    return UserMetricsService.calculateStepDistanceKm(steps, heightCm: heightCm);
  }

  /// Kiểm tra xem có số bước chân nào vào ngày chỉ định không
  Future<bool> hasStepsOnDate(DateTime date) async {
    final steps = await getStepsByDate(date);
    return steps > 0;
  }

  /// Xóa sạch dữ liệu bước chân
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTodaySteps);
    await prefs.remove(_keyStepBaselineHardware);
    await prefs.remove(_keyStepBaselineDate);
    await prefs.remove(_keyStepRebootOffset);
    await prefs.remove(_keyDailyStepsHistory);
    invalidateCache();
  }
}
