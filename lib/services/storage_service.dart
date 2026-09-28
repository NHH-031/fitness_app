import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../widgets/health_score_widget.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';
import 'locale_service.dart';
import 'widget_sync_service.dart';

class StorageService {
  // Master notification for general updates & backward compatibility
  static final ValueNotifier<int> dataUpdateNotifier = ValueNotifier<int>(0);

  // Scoped domain notifiers for high-performance localized rendering
  static final ValueNotifier<int> stepUpdateNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> waterUpdateNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> foodUpdateNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> workoutUpdateNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> chatUpdateNotifier = ValueNotifier<int>(0);

  static void notifyDataChanged() {
    dataUpdateNotifier.value++;
  }

  static void notifyStepChanged() {
    stepUpdateNotifier.value++;
    dataUpdateNotifier.value++;
    WidgetSyncService.updateHomeWidget();
  }

  static void notifyWaterChanged() {
    waterUpdateNotifier.value++;
    dataUpdateNotifier.value++;
    WidgetSyncService.updateHomeWidget();
  }

  static void notifyFoodChanged() {
    foodUpdateNotifier.value++;
    dataUpdateNotifier.value++;
  }

  static void notifyWorkoutChanged() {
    workoutUpdateNotifier.value++;
    dataUpdateNotifier.value++;
  }

  static void notifyProfileChanged() {
    profileUpdateNotifier.value++;
    dataUpdateNotifier.value++;
  }

  static void notifyChatChanged() {
    chatUpdateNotifier.value++;
    dataUpdateNotifier.value++;
  }

  // --- IN-MEMORY STRUCTURED CACHES & DAY INDEXES (TỐI ƯU HÓA TRUY VẤN O(1)) ---
  static Map<String, List<FoodLogEntry>>? _cachedFoodByDate;
  static Map<String, List<Map<String, dynamic>>>? _cachedWorkoutsByDate;
  static Map<String, int>? _cachedDailyStepsMap;

  /// Xóa sạch bộ nhớ đệm khi đăng xuất hoặc xóa dữ liệu
  static void invalidateMemoryCaches() {
    _cachedFoodByDate = null;
    _cachedWorkoutsByDate = null;
    _cachedDailyStepsMap = null;
  }

  static const String _keyAppLanguage = 'app_language';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyLastLoginDate = 'last_login_date';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyWaterReminderEnabled = 'water_reminder_enabled';
  static const String _keyWaterReminderInterval = 'water_reminder_interval';
  static const String _keyWaterCupsToday = 'water_cups_today';
  static const String _keyWaterVolumeMl = 'water_volume_ml_today';
  static const String _keyWaterDate = 'water_date';
  static const String _keyWaterHistory = 'daily_water_history';
  static const String _keyIsGuestMode = 'is_guest_mode';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyStepBaselineHardware = 'step_baseline_hardware';
  static const String _keyStepBaselineDate = 'step_baseline_date';
  static const String _keyTodaySteps = 'today_steps';
  static const String _keyDailySummaries = 'daily_activity_summaries';
  static const String _keyDailyStepsHistory = 'daily_steps_history';
  static const String _keyUserJoinedDate = 'user_joined_date';
  static const String _keyStepRebootOffset = 'step_reboot_offset';
  static const String _keyGeminiApiKey = 'gemini_api_key';

  /// Lấy khóa Gemini API tùy chỉnh đã lưu trong máy
  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
  }

  /// Lưu trữ hoặc xóa khóa Gemini API tùy chỉnh
  static Future<void> saveGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_keyGeminiApiKey);
    } else {
      await prefs.setString(_keyGeminiApiKey, trimmed);
    }
    GeminiService.setApiKey(trimmed);
  }

  // Trạng thái lọc rung và chống quá tải đĩa (Anti-jitter & Debounce)
  static int? _lastHardwareReading;
  static DateTime? _lastReadingTime;
  static int? _lastPersistedSteps;
  static DateTime? _lastPersistTime;

  // --- QUẢN LÝ BƯỚC CHÂN BỀN VỮNG (PERSISTENT STEP TRACKING KỂ CẢ KHI TẮT APP) ---
  static Future<int> getTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_keyStepBaselineDate);
    if (savedDate != todayStr) {
      return 0;
    }
    return prefs.getInt(_keyTodaySteps) ?? 0;
  }

  static Future<void> saveTodaySteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_keyStepBaselineDate, todayStr);
    await prefs.setInt(_keyTodaySteps, steps);
    await saveDailySteps(todayStr, steps);
    _lastPersistedSteps = steps;
    _lastPersistTime = DateTime.now();
  }

  /// Tính toán và lưu trữ số bước trong ngày dựa trên cảm biến phần cứng (kể cả khi đã tắt app)
  /// Tích hợp bộ lọc chống giật (Anti-Jitter Rate Limiter) và bảo toàn bước khi điện thoại khởi động lại
  static Future<int> processHardwareSteps(int hardwareSteps) async {
    if (hardwareSteps <= 0) return await getTodaySteps();

    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
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

    // TRƯỜNG HỢP 2: Thiết bị khởi động lại (Reboot) khiến phần cứng reset counter về giá trị nhỏ hơn baseline
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
    if (_lastHardwareReading != null && _lastReadingTime != null) {
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

    // Debounced disk saving: Giảm thiểu ghi I/O liên tục, chỉ ghi khi tăng >= 3 bước hoặc sau 2 giây
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

  /// Ép buộc lưu dữ liệu bước chân xuống đĩa ngay lập tức
  static Future<void> flushHardwareSteps() async {
    if (_lastPersistedSteps != null) {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setInt(_keyTodaySteps, _lastPersistedSteps!);
      await saveDailySteps(todayStr, _lastPersistedSteps!);
    }
  }

  // --- QUẢN LÝ ONBOARDING (THIẾT LẬP HỒ SƠ LẦN ĐẦU) ---
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  static Future<void> setCompletedOnboarding(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasCompletedOnboarding, completed);
    notifyDataChanged();
  }

  // --- QUẢN LÝ CHẾ ĐỘ KHÁCH (GUEST MODE) ---
  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuestMode) ?? false;
  }

  static Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuestMode, isGuest);
    notifyDataChanged();
  }

  // --- QUẢN LÝ THỜI GIAN THAM GIA & DỮ LIỆU THỰC TẾ (REAL USAGE TIMELINE) ---

  /// Lấy ngày người dùng bắt đầu tham gia (từ lúc đăng nhập hoặc tạo hồ sơ thực tế)
  static Future<DateTime> getUserJoinedDate() async {
    final prefs = await SharedPreferences.getInstance();

    // Mốc ngày sớm nhất từ các hoạt động thực tế hoặc thiết lập người dùng
    DateTime? earliest;

    final saved = prefs.getString(_keyUserJoinedDate);
    if (saved != null) {
      final parsed = DateTime.tryParse(saved);
      if (parsed != null) {
        earliest = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    // Kiểm tra creationTime của tài khoản Firebase hiện tại nếu có
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser?.metadata.creationTime != null) {
        final ct = firebaseUser!.metadata.creationTime!;
        final date = DateTime(ct.year, ct.month, ct.day);
        if (earliest == null || date.isBefore(earliest)) {
          earliest = date;
        }
      }
    } catch (_) {}

    // Quét toàn bộ lịch sử hoạt động thực tế để tìm mốc bắt đầu sớm nhất:
    final rawFood = prefs.getStringList(_keyFoodLogs) ?? [];
    for (final s in rawFood) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final t = DateTime.tryParse(m['timestamp']?.toString() ?? '');
        if (t != null) {
          final clean = DateTime(t.year, t.month, t.day);
          if (earliest == null || clean.isBefore(earliest)) {
            earliest = clean;
          }
        }
      } catch (_) {}
    }

    final rawWorkouts = prefs.getStringList(_keyWorkoutLogs) ?? [];
    for (final s in rawWorkouts) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final t = DateTime.tryParse(m['timestamp']?.toString() ?? '');
        if (t != null) {
          final clean = DateTime(t.year, t.month, t.day);
          if (earliest == null || clean.isBefore(earliest)) {
            earliest = clean;
          }
        }
      } catch (_) {}
    }

    final rawWater = prefs.getStringList(_keyWaterHistory) ?? [];
    for (final s in rawWater) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final dStr = m['date']?.toString();
        if (dStr != null) {
          final t = DateTime.tryParse(dStr);
          if (t != null) {
            final clean = DateTime(t.year, t.month, t.day);
            if (earliest == null || clean.isBefore(earliest)) {
              earliest = clean;
            }
          }
        }
      } catch (_) {}
    }

    final rawSteps = prefs.getStringList(_keyDailyStepsHistory) ?? [];
    for (final s in rawSteps) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final dStr = m['date']?.toString();
        if (dStr != null) {
          final t = DateTime.tryParse(dStr);
          if (t != null) {
            final clean = DateTime(t.year, t.month, t.day);
            if (earliest == null || clean.isBefore(earliest)) {
              earliest = clean;
            }
          }
        }
      } catch (_) {}
    }

    final rawSummaries = prefs.getStringList(_keyDailySummaries) ?? [];
    for (final s in rawSummaries) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final summary = DailyActivitySummary.fromJson(m);
        if (summary.hasActivity) {
          final t = DateTime.tryParse(summary.date);
          if (t != null) {
            final clean = DateTime(t.year, t.month, t.day);
            if (earliest == null || clean.isBefore(earliest)) {
              earliest = clean;
            }
          }
        }
      } catch (_) {}
    }

    final rawLogin = prefs.getString(_keyLastLoginDate);
    if (rawLogin != null) {
      final t = DateTime.tryParse(rawLogin);
      if (t != null) {
        final streak = prefs.getInt(_keyCurrentStreak) ?? 1;
        final estJoined = t.subtract(Duration(days: max(0, streak - 1)));
        final clean = DateTime(estJoined.year, estJoined.month, estJoined.day);
        if (earliest == null || clean.isBefore(earliest)) {
          earliest = clean;
        }
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resolved = earliest ?? today;
    await prefs.setString(_keyUserJoinedDate, getTodayDateString(resolved));
    return resolved;
  }

  static Future<void> setUserJoinedDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanDate = DateTime(date.year, date.month, date.day);
    await prefs.setString(_keyUserJoinedDate, getTodayDateString(cleanDate));
    notifyDataChanged();
  }

  /// Kiểm tra xem người dùng có bất kỳ hoạt động thực tế nào trong ngày này không
  static Future<bool> hasActivityOnDate(DateTime date) async {
    final dateStr = getTodayDateString(date);
    final isToday = dateStr == getTodayDateString();
    if (isToday) return true; // Hôm nay luôn được coi là ngày người dùng đang dùng app

    final joinedDate = await getUserJoinedDate();
    final joinedStr = getTodayDateString(joinedDate);
    if (dateStr == joinedStr) {
      return true; // Ngày tạo tài khoản / bắt đầu tham gia app luôn là ngày hoạt động
    }

    final steps = await getStepsByDate(date);
    if (steps > 0) return true;

    final caloIn = await getTotalCaloriesInByDate(date);
    if (caloIn > 0) return true;

    final workouts = await getWorkoutLogsByDate(date);
    if (workouts.isNotEmpty) return true;

    final water = await getWaterCupsByDate(date);
    if (water > 0) return true;

    final prefs = await SharedPreferences.getInstance();
    final rawSummaries = prefs.getStringList(_keyDailySummaries) ?? [];
    for (final s in rawSummaries) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        if (m['date'] == dateStr) {
          final summary = DailyActivitySummary.fromJson(m);
          if (summary.hasActivity) return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// Dọn sạch các snapshot giả (ngày không có bất kỳ hoạt động nào) đã bị lưu tự động trước đó
  static Future<void> purgeFakeSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSummaries = prefs.getStringList(_keyDailySummaries) ?? [];
    if (rawSummaries.isEmpty) return;

    final joinedDate = await getUserJoinedDate();
    final todayStr = getTodayDateString();

    final List<DailyActivitySummary> validList = [];
    for (final str in rawSummaries) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        final summary = DailyActivitySummary.fromJson(map);
        final date = DateTime.tryParse(summary.date);
        if (date == null) continue;
        final cleanDate = DateTime(date.year, date.month, date.day);

        // Bỏ qua nếu trước ngày người dùng tham gia
        if (cleanDate.isBefore(joinedDate)) continue;

        // Giữ lại nếu là hôm nay hoặc ngày đó thực sự có hoạt động
        if (summary.date == todayStr || summary.hasActivity) {
          validList.add(summary);
        }
      } catch (_) {}
    }

    final encoded = validList.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_keyDailySummaries, encoded);
  }

  // --- QUẢN LÝ NGÔN NGỮ (APP LANGUAGE) ---

  static Future<void> saveAppLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLanguage, langCode);
    notifyDataChanged();
  }

  static Future<String> getAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppLanguage) ?? 'vi';
  }

  // --- QUẢN LÝ HỒ SƠ NGƯỜI DÙNG (BIOMETRIC PROFILE) ---

  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfile, jsonEncode(profile.toJson()));
    FirestoreService().saveUserProfile(profile);
    notifyDataChanged();
  }

  static Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUserProfile);
    if (jsonStr == null || jsonStr.isEmpty) {
      return UserProfile.defaultProfile();
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return UserProfile.defaultProfile();
    }
  }

  /// Tính toán số ngày hoạt động liên tiếp thực tế đếm ngược từ hôm nay
  static Future<int> calculateConsecutiveActiveStreak() async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    int streak = 1; // Hôm nay người dùng đang mở ứng dụng
    DateTime checkDay = todayUtc.subtract(const Duration(days: 1));
    while (true) {
      final active = await hasActivityOnDate(checkDay);
      if (active) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  static Future<int> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final String? lastLoginStr = prefs.getString(_keyLastLoginDate);
    int currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;

    final now = DateTime.now();
    final todayStr = getTodayDateString(now);
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    final joinedDate = await getUserJoinedDate();
    final joinedUtc = DateTime.utc(joinedDate.year, joinedDate.month, joinedDate.day);
    final daysSinceJoined = max(1, todayUtc.difference(joinedUtc).inDays + 1);

    // Tính toán chuỗi hoạt động liên tiếp thực tế dựa trên dữ liệu thật
    final activityStreak = await calculateConsecutiveActiveStreak();

    // TRƯỜNG HỢP 1: Lần đầu đăng nhập hoặc chưa từng lưu mốc ngày đăng nhập
    if (lastLoginStr == null || currentStreak <= 0) {
      currentStreak = max(activityStreak, daysSinceJoined == 2 ? 2 : 1);
      if (currentStreak > daysSinceJoined) currentStreak = daysSinceJoined;
      if (currentStreak < 1) currentStreak = 1;
      await prefs.setString(_keyLastLoginDate, todayStr);
      await prefs.setInt(_keyCurrentStreak, currentStreak);
      FirestoreService().updateStreak(currentStreak, todayStr);
      notifyDataChanged();
      return currentStreak;
    }

    final lastLoginDate = DateTime.tryParse(lastLoginStr);
    if (lastLoginDate == null) {
      currentStreak = max(activityStreak, daysSinceJoined == 2 ? 2 : 1);
      if (currentStreak > daysSinceJoined) currentStreak = daysSinceJoined;
      if (currentStreak < 1) currentStreak = 1;
      await prefs.setString(_keyLastLoginDate, todayStr);
      await prefs.setInt(_keyCurrentStreak, currentStreak);
      FirestoreService().updateStreak(currentStreak, todayStr);
      notifyDataChanged();
      return currentStreak;
    }

    final lastUtc = DateTime.utc(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
    final dayDiff = todayUtc.difference(lastUtc).inDays;

    if (dayDiff == 0) {
      // TRƯỜNG HỢP 2: Người dùng vào lại ứng dụng trong cùng ngày hôm nay
      if (activityStreak > currentStreak) {
        currentStreak = activityStreak;
      }
      if (daysSinceJoined == 2 && currentStreak < 2) {
        currentStreak = 2;
      }
      if (currentStreak > daysSinceJoined) {
        currentStreak = daysSinceJoined;
      }
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    } else if (dayDiff == 1) {
      // TRƯỜNG HỢP 3: Hôm nay là ngày tiếp theo (mỗi ngày vào ứng dụng 1 lần) -> Cộng 1 ngày vào chuỗi
      currentStreak++;
      if (activityStreak > currentStreak) {
        currentStreak = activityStreak;
      }
      if (currentStreak > daysSinceJoined) {
        currentStreak = daysSinceJoined;
      }
      await prefs.setString(_keyLastLoginDate, todayStr);
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    } else if (dayDiff > 1) {
      // TRƯỜNG HỢP 4: Bỏ lỡ ít nhất 1 ngày -> Kiểm tra nếu thực tế vẫn có hoạt động liên tiếp
      if (activityStreak > 1) {
        currentStreak = min(activityStreak, daysSinceJoined);
      } else {
        currentStreak = 1;
      }
      await prefs.setString(_keyLastLoginDate, todayStr);
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    } else {
      // dayDiff < 0: Thiết bị lùi giờ
      await prefs.setString(_keyLastLoginDate, todayStr);
      if (activityStreak > currentStreak) {
        currentStreak = activityStreak;
      }
      if (currentStreak > daysSinceJoined) {
        currentStreak = daysSinceJoined;
      }
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    }

    if (currentStreak < 1) {
      currentStreak = 1;
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    }

    FirestoreService().updateStreak(currentStreak, todayStr);
    notifyDataChanged();
    return currentStreak;
  }

  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    int currentStreak = prefs.getInt(_keyCurrentStreak) ?? 1;
    if (currentStreak <= 0) currentStreak = 1;

    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final joinedDate = await getUserJoinedDate();
    final joinedUtc = DateTime.utc(joinedDate.year, joinedDate.month, joinedDate.day);
    final daysSinceJoined = max(1, todayUtc.difference(joinedUtc).inDays + 1);

    final activityStreak = await calculateConsecutiveActiveStreak();
    if (activityStreak > currentStreak) {
      currentStreak = activityStreak;
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    }

    if (daysSinceJoined == 2 && currentStreak < 2) {
      currentStreak = 2;
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    }

    if (currentStreak > daysSinceJoined) {
      currentStreak = daysSinceJoined;
      await prefs.setInt(_keyCurrentStreak, currentStreak);
    }
    return currentStreak;
  }

  static Future<void> resetStreakToInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = getTodayDateString();
    await prefs.setInt(_keyCurrentStreak, 1);
    await prefs.setString(_keyLastLoginDate, todayStr);
    FirestoreService().updateStreak(1, todayStr);
    notifyDataChanged();
  }

  /// Xóa toàn bộ dữ liệu người dùng cục bộ khi đăng xuất để bảo đảm tài khoản mới không bị dính dữ liệu cũ
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentStreak);
    await prefs.remove(_keyLastLoginDate);
    await prefs.remove(_keyUserJoinedDate);
    await prefs.remove(_keyDailySummaries);
    await prefs.remove(_keyFoodLogs);
    await prefs.remove(_keyWorkoutLogs);
    await prefs.remove(_keyWaterCupsToday);
    await prefs.remove(_keyWaterVolumeMl);
    await prefs.remove(_keyWaterDate);
    await prefs.remove(_keyWaterHistory);
    await prefs.remove(_keyTodaySteps);
    await prefs.remove(_keyStepBaselineHardware);
    await prefs.remove(_keyStepBaselineDate);
    await prefs.remove(_keyDailyStepsHistory);
    await prefs.remove(_keyUserProfile);
    await prefs.remove(_keyNutritionGoal);
    await prefs.remove(_keyIsGuestMode);
    invalidateMemoryCaches();
    notifyDataChanged();
  }

  // --- QUẢN LÝ NHẮC NHỞ & UỐNG NƯỚC ---

  static Future<bool> isWaterReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWaterReminderEnabled) ?? true;
  }

  static Future<void> setWaterReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWaterReminderEnabled, enabled);
  }

  static Future<int> getWaterReminderInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWaterReminderInterval) ?? 2; // Mặc định mỗi 2 tiếng
  }

  static Future<void> setWaterReminderInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWaterReminderInterval, hours);
  }

  static String getTodayDateString([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  static String _normalizeDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return "$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
      }
    } catch (_) {}
    return dateStr;
  }

  /// Kiểm tra và tự động chốt sổ lịch sử nước ngày cũ, reset về 0 cho ngày mới (0h)
  static Future<bool> checkAndResetWaterDaily({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = getTodayDateString(now);
    final rawSavedDate = prefs.getString(_keyWaterDate);
    final savedDate = rawSavedDate != null ? _normalizeDate(rawSavedDate) : null;

    if (savedDate == todayStr) {
      return false;
    }

    if (savedDate != null && savedDate.isNotEmpty) {
      final oldCups = prefs.getInt(_keyWaterCupsToday) ?? 0;
      final oldMl = prefs.getInt(_keyWaterVolumeMl) ?? (oldCups * 250);

      await _archiveWaterLog(
        dateStr: savedDate,
        cups: oldCups,
        volumeMl: oldMl,
      );
    }

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterCupsToday, 0);
    await prefs.setInt(_keyWaterVolumeMl, 0);

    await _archiveWaterLog(
      dateStr: todayStr,
      cups: 0,
      volumeMl: 0,
    );

    notifyDataChanged();
    return true;
  }

  static Future<void> _archiveWaterLog({
    required String dateStr,
    required int cups,
    required int volumeMl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getStringList(_keyWaterHistory) ?? [];
    List<DailyWaterLog> logs = [];
    for (final str in rawLogs) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        logs.add(DailyWaterLog.fromJson(map));
      } catch (_) {}
    }

    logs.removeWhere((l) => l.date == dateStr);
    logs.add(DailyWaterLog(
      date: dateStr,
      cups: cups,
      volumeMl: volumeMl,
      updatedAt: DateTime.now(),
    ));

    logs.sort((a, b) => b.date.compareTo(a.date));
    if (logs.length > 60) {
      logs = logs.sublist(0, 60);
    }

    final encoded = logs.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_keyWaterHistory, encoded);

    // Đồng bộ tức thì lên Cloud Firestore
    FirestoreService().saveWaterData(dateStr, volumeMl, cups);
  }

  static Future<List<DailyWaterLog>> getWaterHistoryLogs() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getStringList(_keyWaterHistory) ?? [];
    List<DailyWaterLog> logs = [];
    for (final str in rawLogs) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        logs.add(DailyWaterLog.fromJson(map));
      } catch (_) {}
    }
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  static Future<int> getWaterCupsToday() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWaterCupsToday) ?? 0;
  }

  static Future<int> getTodayWaterVolume() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyWaterVolumeMl)) {
      int cups = prefs.getInt(_keyWaterCupsToday) ?? 0;
      int initialMl = cups * 250;
      await prefs.setInt(_keyWaterVolumeMl, initialMl);
      return initialMl;
    }
    return prefs.getInt(_keyWaterVolumeMl) ?? 0;
  }

  static Future<int> addWaterVolume(int ml) async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = getTodayDateString();
    int current = prefs.getInt(_keyWaterVolumeMl) ?? 0;
    current = (current + ml).clamp(0, 10000);
    int cups = (current / 250).ceil();

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterVolumeMl, current);
    await prefs.setInt(_keyWaterCupsToday, cups);

    await _archiveWaterLog(
      dateStr: todayStr,
      cups: cups,
      volumeMl: current,
    );

    notifyWaterChanged();
    return current;
  }

  static Future<int> removeWaterVolume(int ml) async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = getTodayDateString();
    int current = prefs.getInt(_keyWaterVolumeMl) ?? 0;
    current = (current - ml).clamp(0, 10000);
    int cups = (current / 250).ceil();

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterVolumeMl, current);
    await prefs.setInt(_keyWaterCupsToday, cups);

    await _archiveWaterLog(
      dateStr: todayStr,
      cups: cups,
      volumeMl: current,
    );

    notifyWaterChanged();
    return current;
  }

  static Future<void> resetWaterVolume() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = getTodayDateString();
    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterVolumeMl, 0);
    await prefs.setInt(_keyWaterCupsToday, 0);

    await _archiveWaterLog(
      dateStr: todayStr,
      cups: 0,
      volumeMl: 0,
    );

    notifyWaterChanged();
  }

  static Future<int> addWaterCup() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = getTodayDateString();
    int current = prefs.getInt(_keyWaterCupsToday) ?? 0;
    current++;
    final volumeMl = current * 250;

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterCupsToday, current);
    await prefs.setInt(_keyWaterVolumeMl, volumeMl);

    await _archiveWaterLog(
      dateStr: todayStr,
      cups: current,
      volumeMl: volumeMl,
    );

    notifyWaterChanged();
    return current;
  }

  static Future<int> removeWaterCup() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = getTodayDateString();
    int current = prefs.getInt(_keyWaterCupsToday) ?? 0;
    if (current > 0) {
      current--;
      final volumeMl = current * 250;
      await prefs.setString(_keyWaterDate, todayStr);
      await prefs.setInt(_keyWaterCupsToday, current);
      await prefs.setInt(_keyWaterVolumeMl, volumeMl);

      await _archiveWaterLog(
        dateStr: todayStr,
        cups: current,
        volumeMl: volumeMl,
      );

      notifyWaterChanged();
    }
    return current;
  }

  static Future<int> addWaterCupForDate(DateTime date) async {
    final dateStr = getTodayDateString(date);
    if (dateStr == getTodayDateString()) {
      return await addWaterCup();
    }
    int current = await getWaterCupsByDate(date);
    current++;
    final volumeMl = current * 250;
    await _archiveWaterLog(
      dateStr: dateStr,
      cups: current,
      volumeMl: volumeMl,
    );
    notifyWaterChanged();
    notifyDataChanged();
    return current;
  }

  static Future<int> removeWaterCupForDate(DateTime date) async {
    final dateStr = getTodayDateString(date);
    if (dateStr == getTodayDateString()) {
      return await removeWaterCup();
    }
    int current = await getWaterCupsByDate(date);
    if (current > 0) {
      current--;
      final volumeMl = current * 250;
      await _archiveWaterLog(
        dateStr: dateStr,
        cups: current,
        volumeMl: volumeMl,
      );
      notifyWaterChanged();
      notifyDataChanged();
    }
    return current;
  }

  // --- WORKOUT LOGGING & ACHIEVEMENTS ---
  static const String _keyWorkoutLogs = 'completed_workout_logs';

  static Future<void> logCompletedWorkout({
    required int durationMinutes,
    required String title,
    int? calories,
    DateTime? timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final time = timestamp ?? DateTime.now();

    final List<String> logs = prefs.getStringList(_keyWorkoutLogs) ?? [];
    final workoutMap = <String, dynamic>{
      'title': title,
      'duration': durationMinutes,
      'calories': calories ?? (durationMinutes * 7),
      'timestamp': time.toIso8601String(),
    };
    final newEntry = jsonEncode(workoutMap);
    logs.add(newEntry);
    await prefs.setStringList(_keyWorkoutLogs, logs);

    // Cập nhật trực tiếp vào Index Cache O(1)
    if (_cachedWorkoutsByDate != null) {
      final dateKey = getTodayDateString(time);
      _cachedWorkoutsByDate!.putIfAbsent(dateKey, () => []).insert(0, workoutMap);
    }

    FirestoreService().saveWorkoutLog(workoutMap);
    notifyWorkoutChanged();
  }

  static Future<List<Map<String, dynamic>>> getWorkoutLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> logs = prefs.getStringList(_keyWorkoutLogs) ?? [];
    return logs.map((str) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((item) => item.isNotEmpty).toList();
  }

  /// Returns completed workouts specifically recorded today, sorted newest first
  static Future<List<Map<String, dynamic>>> getTodayWorkoutLogs() async {
    final logs = await getWorkoutLogs();
    final now = DateTime.now();
    final List<Map<String, dynamic>> todayLogs = [];
    for (final log in logs) {
      if (log['timestamp'] != null) {
        final date = DateTime.tryParse(log['timestamp'] as String);
        if (date != null &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          todayLogs.add(log);
        }
      }
    }
    todayLogs.sort((a, b) {
      final tA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(2000);
      final tB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(2000);
      return tB.compareTo(tA);
    });
    return todayLogs;
  }

  static Future<void> deleteWorkoutLog(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawLogs = prefs.getStringList(_keyWorkoutLogs) ?? [];
    rawLogs.removeWhere((str) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return map['timestamp'] == timestamp;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_keyWorkoutLogs, rawLogs);
    FirestoreService().deleteWorkoutLog(timestamp);
    notifyDataChanged();
  }

  /// Calculates total calories burned from workouts completed today
  static Future<int> getTodayWorkoutsCalories() async {
    final logs = await getWorkoutLogs();
    final now = DateTime.now();
    int totalCalories = 0;
    for (final log in logs) {
      if (log['timestamp'] != null) {
        final date = DateTime.tryParse(log['timestamp'] as String);
        if (date != null &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          final cal = (log['calories'] as num?)?.toInt() ??
              (((log['duration'] as num?)?.toInt() ?? 0) * 7);
          totalCalories += cal;
        }
      }
    }
    return totalCalories;
  }

  /// Calculates total workout minutes completed today
  static Future<int> getTodayWorkoutsMinutes() async {
    final logs = await getWorkoutLogs();
    final now = DateTime.now();
    int totalMinutes = 0;
    for (final log in logs) {
      if (log['timestamp'] != null && log['duration'] != null) {
        final date = DateTime.tryParse(log['timestamp'] as String);
        if (date != null &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          totalMinutes += (log['duration'] as num).toInt();
        }
      }
    }
    return totalMinutes;
  }

  /// Calculates total active minutes for the current week (Monday 00:00 to now)
  static Future<int> getWeeklyActiveMinutes() async {
    final logs = await getWorkoutLogs();
    final now = DateTime.now();
    // Monday of the current week
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    int totalMinutes = 0;
    for (final log in logs) {
      if (log['timestamp'] != null && log['duration'] != null) {
        final date = DateTime.tryParse(log['timestamp'] as String);
        if (date != null && date.isAfter(monday)) {
          totalMinutes += (log['duration'] as num).toInt();
        }
      }
    }
    return totalMinutes;
  }

  /// Returns the set of weekday integers (1 = Mon, ..., 7 = Sun) that have workouts this week
  static Future<Set<int>> getWeeklyWorkoutDays() async {
    final logs = await getWorkoutLogs();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final Set<int> days = {};
    for (final log in logs) {
      if (log['timestamp'] != null) {
        final date = DateTime.tryParse(log['timestamp'] as String);
        if (date != null && date.isAfter(monday)) {
          days.add(date.weekday);
        }
      }
    }
    return days;
  }

  /// Returns number of workouts completed this week
  static Future<int> getWeeklyWorkoutCount() async {
    final logs = await getWorkoutLogs();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    int count = 0;
    for (final log in logs) {
      if (log['timestamp'] != null) {
        final date = DateTime.tryParse(log['timestamp'] as String);
        if (date != null && date.isAfter(monday)) {
          count++;
        }
      }
    }
    return count;
  }

  /// Checks if the user ever completed a morning workout before 7:00 AM
  static Future<bool> hasCompletedMorningWorkout() async {
    final logs = await getWorkoutLogs();
    for (final log in logs) {
      if (log['timestamp'] != null) {
        final date = DateTime.tryParse(log['timestamp'] as String);
        if (date != null && date.hour < 7) {
          return true;
        }
      }
    }
    return false;
  }

  /// Evaluates and returns the status of all 4 achievement badges
  static Future<List<AchievementBadge>> getAchievementBadges({
    int currentSteps = 0,
    int? currentStreak,
  }) async {
    final streak = currentStreak ?? await getCurrentStreak();
    final weeklyWorkouts = await getWeeklyWorkoutCount();
    final hasDawnWorkout = await hasCompletedMorningWorkout();
    final isVi = LocaleService.isVietnamese;

    return [
      // 1. 10k Steps Warrior
      AchievementBadge(
        id: '10k_steps',
        title: isVi ? 'Chiến Binh 10k Bước' : '10k Steps Warrior',
        description: isVi
            ? 'Chinh phục cột mốc 10.000 bước chân trong một ngày.'
            : 'Conquer the 10,000 steps milestone in a single day.',
        iconEmoji: '🥇',
        isUnlocked: currentSteps >= 10000,
        currentProgress: currentSteps.clamp(0, 10000),
        maxProgress: 10000,
        progressText: currentSteps >= 10000
            ? (isVi ? 'Đã hoàn thành!' : 'Completed!')
            : (isVi ? '$currentSteps / 10.000 bước' : '$currentSteps / 10,000 steps'),
        themeColor: const Color(0xFFFFD700),
      ),
      // 2. Cardio Master
      AchievementBadge(
        id: 'cardio_master',
        title: isVi ? 'Bậc Thầy Cardio' : 'Cardio Master',
        description: isVi
            ? 'Hoàn thành ít nhất 3 buổi tập trong một tuần.'
            : 'Complete at least 3 workouts in a single week.',
        iconEmoji: '⚡',
        isUnlocked: weeklyWorkouts >= 3,
        currentProgress: weeklyWorkouts.clamp(0, 3),
        maxProgress: 3,
        progressText: weeklyWorkouts >= 3
            ? (isVi ? 'Đã hoàn thành!' : 'Completed!')
            : (isVi ? '$weeklyWorkouts / 3 buổi tập' : '$weeklyWorkouts / 3 workouts'),
        themeColor: const Color(0xFF00C6FF),
      ),
      // 3. Dawn Warrior
      AchievementBadge(
        id: 'dawn_warrior',
        title: isVi ? 'Chiến Binh Bình Minh' : 'Dawn Warrior',
        description: isVi
            ? 'Hoàn thành buổi tập luyện trước 7:00 sáng.'
            : 'Complete a workout session before 7:00 AM.',
        iconEmoji: '🌅',
        isUnlocked: hasDawnWorkout,
        currentProgress: hasDawnWorkout ? 1 : 0,
        maxProgress: 1,
        progressText: hasDawnWorkout
            ? (isVi ? 'Đã hoàn thành!' : 'Completed!')
            : (isVi ? 'Hoàn thành trước 7:00' : 'Finish before 7:00 AM'),
        themeColor: const Color(0xFFFF9500),
      ),
      // 4. Eternal Flame
      AchievementBadge(
        id: 'eternal_flame',
        title: isVi ? 'Ngọn Lửa Bất Diệt' : 'Eternal Flame',
        description: isVi
            ? 'Duy trì chuỗi tập luyện 7 ngày liên tiếp không ngắt quãng.'
            : 'Maintain an unbroken streak of 7 consecutive days.',
        iconEmoji: '🔥',
        isUnlocked: streak >= 7,
        currentProgress: streak.clamp(0, 7),
        maxProgress: 7,
        progressText: streak >= 7
            ? (isVi ? 'Đã hoàn thành!' : 'Completed!')
            : (isVi ? '$streak / 7 ngày chuỗi' : '$streak / 7 days streak'),
        themeColor: const Color(0xFFFF2D55),
      ),
    ];
  }

  // --- REAL-TIME NUTRITION & FOOD LOGGING ---
  static const String _keyFoodLogs = 'user_food_logs';
  static const String _keyNutritionGoal = 'user_nutrition_goal';

  static Future<void> saveNutritionGoal(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNutritionGoal, goal);
    notifyDataChanged();
  }

  static Future<String> getNutritionGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNutritionGoal) ?? 'balanced';
  }

  static Future<void> logFoodItem(
    FoodInfo food, {
    DateTime? timestamp,
    String? mealType,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final time = timestamp ?? DateTime.now();
    final List<String> logs = prefs.getStringList(_keyFoodLogs) ?? [];

    final resolvedMeal = mealType ?? FoodLogEntry.inferMealType(time);

    final entry = FoodLogEntry(
      id: '${time.millisecondsSinceEpoch}_${food.name.hashCode}',
      name: food.name,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      timestamp: time,
      mealType: resolvedMeal,
      imagePath: imagePath,
    );

    logs.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_keyFoodLogs, logs);

    // Cập nhật tức thời vào Cache Index O(1)
    if (_cachedFoodByDate != null) {
      final dateKey = getTodayDateString(time);
      _cachedFoodByDate!.putIfAbsent(dateKey, () => []).insert(0, entry);
    }

    FirestoreService().saveFoodLog(entry);
    notifyFoodChanged();
  }

  static Future<List<FoodLogEntry>> getTodayFoodLogs() async {
    return getFoodLogsByDate(DateTime.now());
  }

  static Future<List<FoodLogEntry>> getTodayFoodLogsByMeal(String mealType) async {
    final todayLogs = await getTodayFoodLogs();
    return todayLogs
        .where((entry) => entry.mealType.toLowerCase() == mealType.toLowerCase())
        .toList();
  }

  static Future<int> getTodayMealCalories(String mealType) async {
    final items = await getTodayFoodLogsByMeal(mealType);
    int sum = 0;
    for (final item in items) {
      sum += item.calories;
    }
    return sum;
  }

  static Future<void> deleteFoodLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawLogs = prefs.getStringList(_keyFoodLogs) ?? [];
    rawLogs.removeWhere((str) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return map['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_keyFoodLogs, rawLogs);

    // Xóa trong bộ nhớ đệm
    if (_cachedFoodByDate != null) {
      for (final list in _cachedFoodByDate!.values) {
        list.removeWhere((entry) => entry.id == id);
      }
    }

    FirestoreService().deleteFoodLog(id);
    notifyFoodChanged();
  }

  static Future<int> getTodayTotalCaloriesIn() async {
    final items = await getTodayFoodLogs();
    int sum = 0;
    for (final item in items) {
      sum += item.calories;
    }
    return sum;
  }

  static Future<Map<String, int>> getTodayTotalMacros() async {
    final items = await getTodayFoodLogs();
    int p = 0;
    int c = 0;
    int f = 0;
    for (final item in items) {
      p += item.protein;
      c += item.carbs;
      f += item.fat;
    }
    return {'protein': p, 'carbs': c, 'fat': f};
  }

  /// Real-time Calories Burn calculation:
  /// BMR (prorated to time of day based on personal UserProfile) + Steps (0.04 kcal/step) + Completed Workouts
  static Future<int> calculateRealTimeCaloriesBurned({
    required int currentSteps,
    DateTime? now,
  }) async {
    return calculateCaloriesBurnedByDate(
      date: now ?? DateTime.now(),
      steps: currentSteps,
    );
  }

  // --- TRUY VẤN DỮ LIỆU THEO NGÀY (DAILY QUERIES & SNAPSHOT DATABASE) ---

  static Future<void> saveDailySteps(String dateStr, int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyDailyStepsHistory) ?? [];
    Map<String, int> stepsMap = _cachedDailyStepsMap != null
        ? Map<String, int>.from(_cachedDailyStepsMap!)
        : {};

    if (stepsMap.isEmpty) {
      for (final str in rawList) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          if (map['date'] != null && map['steps'] != null) {
            stepsMap[map['date'].toString()] = (map['steps'] as num).toInt();
          }
        } catch (_) {}
      }
    }

    stepsMap[dateStr] = steps;
    _cachedDailyStepsMap = stepsMap;

    final List<String> encoded = stepsMap.entries.map((e) {
      return jsonEncode({'date': e.key, 'steps': e.value});
    }).toList();
    await prefs.setStringList(_keyDailyStepsHistory, encoded);
    notifyStepChanged();
  }

  static Future<int> getStepsByDate(DateTime target) async {
    final dateStr = getTodayDateString(target);
    final isToday = dateStr == getTodayDateString();
    if (isToday) {
      return await getTodaySteps();
    }

    if (_cachedDailyStepsMap != null && _cachedDailyStepsMap!.containsKey(dateStr)) {
      return _cachedDailyStepsMap![dateStr]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyDailyStepsHistory) ?? [];
    final Map<String, int> map = {};
    for (final str in rawList) {
      try {
        final m = jsonDecode(str) as Map<String, dynamic>;
        if (m['date'] != null && m['steps'] != null) {
          map[m['date'].toString()] = (m['steps'] as num).toInt();
        }
      } catch (_) {}
    }
    _cachedDailyStepsMap = map;
    return map[dateStr] ?? 0;
  }

  static Future<List<FoodLogEntry>> getFoodLogsByDate(DateTime target) async {
    final dateStr = getTodayDateString(target);

    // 1. Trả về tức thời từ cache O(1) nếu đã nạp
    if (_cachedFoodByDate != null) {
      return List<FoodLogEntry>.from(_cachedFoodByDate![dateStr] ?? []);
    }

    // 2. Nạp và lập chỉ mục (index) theo ngày 1 lần duy nhất
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawLogs = prefs.getStringList(_keyFoodLogs) ?? [];
    final Map<String, List<FoodLogEntry>> mapIndex = {};

    for (final str in rawLogs) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        final entry = FoodLogEntry.fromJson(map);
        final k = getTodayDateString(entry.timestamp);
        mapIndex.putIfAbsent(k, () => []).add(entry);
      } catch (_) {}
    }

    for (final list in mapIndex.values) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    _cachedFoodByDate = mapIndex;
    return List<FoodLogEntry>.from(_cachedFoodByDate![dateStr] ?? []);
  }

  static Future<int> getTotalCaloriesInByDate(DateTime target) async {
    final items = await getFoodLogsByDate(target);
    int sum = 0;
    for (final item in items) {
      sum += item.calories;
    }
    return sum;
  }

  static Future<Map<String, int>> getTotalMacrosByDate(DateTime target) async {
    final items = await getFoodLogsByDate(target);
    int p = 0;
    int c = 0;
    int f = 0;
    for (final item in items) {
      p += item.protein;
      c += item.carbs;
      f += item.fat;
    }
    return {'protein': p, 'carbs': c, 'fat': f};
  }

  static Future<List<Map<String, dynamic>>> getWorkoutLogsByDate(DateTime target) async {
    final dateStr = getTodayDateString(target);

    // 1. Trả về tức thời từ cache O(1) nếu đã có
    if (_cachedWorkoutsByDate != null) {
      return List<Map<String, dynamic>>.from(_cachedWorkoutsByDate![dateStr] ?? []);
    }

    // 2. Nạp và lập chỉ mục theo ngày
    final logs = await getWorkoutLogs();
    final Map<String, List<Map<String, dynamic>>> mapIndex = {};

    for (final log in logs) {
      if (log['timestamp'] != null) {
        final d = DateTime.tryParse(log['timestamp'] as String);
        if (d != null) {
          final k = getTodayDateString(d);
          mapIndex.putIfAbsent(k, () => []).add(log);
        }
      }
    }

    for (final list in mapIndex.values) {
      list.sort((a, b) {
        final tA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(2000);
        final tB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(2000);
        return tB.compareTo(tA);
      });
    }

    _cachedWorkoutsByDate = mapIndex;
    return List<Map<String, dynamic>>.from(_cachedWorkoutsByDate![dateStr] ?? []);
  }

  static Future<int> getWorkoutCaloriesByDate(DateTime target) async {
    final logs = await getWorkoutLogsByDate(target);
    int total = 0;
    for (final log in logs) {
      final cal = (log['calories'] as num?)?.toInt() ??
          (((log['duration'] as num?)?.toInt() ?? 0) * 7);
      total += cal;
    }
    return total;
  }

  static Future<int> getWorkoutMinutesByDate(DateTime target) async {
    final logs = await getWorkoutLogsByDate(target);
    int total = 0;
    for (final log in logs) {
      total += (log['duration'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  static Future<int> getWaterCupsByDate(DateTime target) async {
    final dateStr = getTodayDateString(target);
    if (dateStr == getTodayDateString()) {
      return await getWaterCupsToday();
    }
    final logs = await getWaterHistoryLogs();
    for (final log in logs) {
      if (log.date == dateStr) {
        return log.cups;
      }
    }
    return 0;
  }

  static Future<int> getWaterVolumeByDate(DateTime target) async {
    final dateStr = getTodayDateString(target);
    if (dateStr == getTodayDateString()) {
      return await getTodayWaterVolume();
    }
    final logs = await getWaterHistoryLogs();
    for (final log in logs) {
      if (log.date == dateStr) {
        return log.volumeMl;
      }
    }
    return 0;
  }

  static Future<int> calculateCaloriesBurnedByDate({
    required DateTime date,
    int? steps,
  }) async {
    final isToday = getTodayDateString(date) == getTodayDateString();
    final targetDay = DateTime(date.year, date.month, date.day);
    final joinedDate = await getUserJoinedDate();

    // Nếu ngày này TRƯỚC ngày tham gia -> 0 kcal (chưa có tài khoản)
    if (targetDay.isBefore(joinedDate)) {
      return 0;
    }

    // Nếu là ngày quá khứ mà người dùng hoàn toàn KHÔNG sử dụng/không có bất kỳ hoạt động nào -> 0 kcal!
    if (!isToday) {
      final active = await hasActivityOnDate(date);
      if (!active) {
        return 0; // Không tự động sinh 1788 kcal BMR giả
      }
    }

    final currentSteps = steps ?? await getStepsByDate(date);
    final userProfile = await getUserProfile();
    final double userBmr = userProfile.bmr;

    final double fractionOfDay = isToday
        ? ((date.hour * 60 + date.minute) / 1440.0).clamp(0.05, 1.0)
        : 1.0;

    final int bmrAccumulated = (userBmr * fractionOfDay).round();
    final int stepsBurn = (currentSteps * 0.04).round();
    final int workoutsBurn = await getWorkoutCaloriesByDate(date);

    return bmrAccumulated + stepsBurn + workoutsBurn;
  }

  static Future<DailyActivitySummary> getDailySummary(DateTime date) async {
    final dateStr = getTodayDateString(date);
    final isToday = dateStr == getTodayDateString();
    final targetDay = DateTime(date.year, date.month, date.day);
    final joinedDate = await getUserJoinedDate();

    // 1. Nếu ngày này TRƯỚC ngày tham gia -> trả về rỗng
    if (targetDay.isBefore(joinedDate)) {
      return DailyActivitySummary(
        date: dateStr,
        steps: 0,
        distanceKm: 0.0,
        stepCalories: 0,
        caloriesIn: 0,
        caloriesOut: 0,
        bmr: 0,
        workoutCalories: 0,
        workoutMinutes: 0,
        waterMl: 0,
        waterCups: 0,
        healthScore: 0,
        healthStatus: LocaleService.tr('status_not_joined'),
        netBalance: 0,
        updatedAt: DateTime.now(),
      );
    }

    // 2. Nếu là ngày quá khứ và người dùng không có hoạt động nào -> trả về rỗng không tính BMR giả
    final active = isToday || await hasActivityOnDate(date);
    if (!isToday && !active) {
      return DailyActivitySummary(
        date: dateStr,
        steps: 0,
        distanceKm: 0.0,
        stepCalories: 0,
        caloriesIn: 0,
        caloriesOut: 0,
        bmr: 0,
        workoutCalories: 0,
        workoutMinutes: 0,
        waterMl: 0,
        waterCups: 0,
        healthScore: 0,
        healthStatus: LocaleService.tr('status_no_activity'),
        netBalance: 0,
        updatedAt: DateTime.now(),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final rawSummaries = prefs.getStringList(_keyDailySummaries) ?? [];

    // Nếu không phải hôm nay, tìm snapshot đã lưu trước (chỉ chấp nhận nếu có hoạt động)
    if (!isToday) {
      for (final str in rawSummaries) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          if (map['date'] == dateStr) {
            final existing = DailyActivitySummary.fromJson(map);
            if (existing.hasActivity) {
              return existing;
            }
          }
        } catch (_) {}
      }
    }

    // Nếu là hôm nay hoặc ngày quá khứ có hoạt động thật sự nhưng chưa lưu snapshot:
    final steps = await getStepsByDate(date);
    final distanceKm = steps * 0.00075;
    final stepCalories = (steps * 0.04).round();
    final caloriesIn = await getTotalCaloriesInByDate(date);
    final workoutCalories = await getWorkoutCaloriesByDate(date);
    final workoutMinutes = await getWorkoutMinutesByDate(date);
    final waterCups = await getWaterCupsByDate(date);
    final waterMl = await getWaterVolumeByDate(date);
    final userProfile = await getUserProfile();
    final bmr = userProfile.bmr.round();

    final caloriesOut = await calculateCaloriesBurnedByDate(
      date: date,
      steps: steps,
    );
    final netBalance = caloriesIn - caloriesOut;

    final macros = await getTotalMacrosByDate(date);
    final streak = await getCurrentStreak();
    final workouts = await getWorkoutLogsByDate(date);

    final scoreEvaluation = HealthScoreCalculator.evaluate(
      currentSteps: steps,
      goalSteps: 10000,
      caloriesIn: caloriesIn,
      targetCalories: userProfile.targetCalories,
      proteinGrams: macros['protein'] ?? 0,
      targetProtein: userProfile.targetProtein,
      workoutMinutes: workoutMinutes,
      workoutCount: workouts.length,
      waterCups: waterCups,
      streakDays: streak,
    );

    final summary = DailyActivitySummary(
      date: dateStr,
      steps: steps,
      distanceKm: distanceKm,
      stepCalories: stepCalories,
      caloriesIn: caloriesIn,
      caloriesOut: caloriesOut,
      bmr: bmr,
      workoutCalories: workoutCalories,
      workoutMinutes: workoutMinutes,
      waterMl: waterMl,
      waterCups: waterCups,
      healthScore: scoreEvaluation.totalScore,
      healthStatus: scoreEvaluation.statusText,
      netBalance: netBalance,
      updatedAt: DateTime.now(),
    );

    // Chỉ lưu snapshot cho ngày quá khứ nếu ngày đó thực sự có hoạt động
    if (!isToday && active && summary.hasActivity) {
      await saveDailySummary(summary);
    }

    return summary;
  }

  static Future<void> saveDailySummary(DailyActivitySummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    final rawSummaries = prefs.getStringList(_keyDailySummaries) ?? [];
    List<DailyActivitySummary> list = [];
    for (final str in rawSummaries) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        list.add(DailyActivitySummary.fromJson(map));
      } catch (_) {}
    }
    list.removeWhere((item) => item.date == summary.date);
    list.add(summary);
    list.sort((a, b) => b.date.compareTo(a.date));
    if (list.length > 60) {
      list = list.sublist(0, 60);
    }
    final encoded = list.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_keyDailySummaries, encoded);

    // Nếu snapshot có hoạt động và ngày sớm hơn joined date hiện tại, tự động dời joined date lại
    if (summary.hasActivity) {
      final summaryDate = DateTime.tryParse(summary.date);
      if (summaryDate != null) {
        final currentJoined = await getUserJoinedDate();
        if (summaryDate.isBefore(currentJoined)) {
          await setUserJoinedDate(summaryDate);
        }
      }
    }

    // Đồng bộ lên Cloud Firestore
    FirestoreService().saveDailySummary(summary);
  }

  /// Lấy danh sách tóm tắt các ngày thực tế từ lúc người dùng bắt đầu tham gia đến nay
  static Future<List<DailyActivitySummary>> getDailySummariesList({
    int days = 14,
    bool limitToJoined = true,
  }) async {
    await purgeFakeSummaries();

    final List<DailyActivitySummary> results = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final joinedDate = await getUserJoinedDate();

    // Giới hạn số ngày chỉ lấy từ lúc người dùng bắt đầu tham gia
    int maxDays = days;
    if (limitToJoined) {
      final daysSinceJoined = today.difference(joinedDate).inDays + 1;
      maxDays = min(days, max(1, daysSinceJoined));
    }

    for (int i = 0; i < maxDays; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final summary = await getDailySummary(targetDate);
      results.add(summary);
    }
    return results;
  }

  static const String _keyDailyAiBriefingPrefix = 'daily_ai_briefing_';

  /// Lấy bản tin AI Coach đã được lưu trữ trong cache cho ngày cụ thể (Zero-latency offline cache)
  static Future<DailyAiBriefing?> getCachedDailyAiBriefing(String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyDailyAiBriefingPrefix$dateStr');
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return DailyAiBriefing.fromJson(map);
      }
    } catch (e) {
      debugPrint("Lỗi đọc cache DailyAiBriefing: $e");
    }
    return null;
  }

  /// Lưu trữ bản tin AI Coach vào bộ nhớ đệm
  static Future<void> saveDailyAiBriefing(DailyAiBriefing briefing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(briefing.toJson());
      await prefs.setString('$_keyDailyAiBriefingPrefix${briefing.dateStr}', encoded);
    } catch (e) {
      debugPrint("Lỗi lưu cache DailyAiBriefing: $e");
    }
  }

  /// Lấy hoặc tự động phân tích tạo bản tin Daily AI PT Briefing
  static Future<DailyAiBriefing> getOrGenerateDailyAiBriefing({
    required DateTime forDate,
    bool forceRefresh = false,
  }) async {
    final dateStr = forDate.toIso8601String().split('T')[0];
    if (!forceRefresh) {
      final cached = await getCachedDailyAiBriefing(dateStr);
      if (cached != null) {
        return cached;
      }
    }

    final yesterday = forDate.subtract(const Duration(days: 1));
    final yesterdayDateStr = yesterday.toIso8601String().split('T')[0];

    final yesterdaySummary = await getDailySummary(yesterday);
    final userProfile = await getUserProfile();
    final streak = await getCurrentStreak();

    final briefing = await GeminiService.generateDailyBriefing(
      dateStr: dateStr,
      yesterdayDateStr: yesterdayDateStr,
      profile: userProfile,
      steps: yesterdaySummary.steps,
      caloriesIn: yesterdaySummary.caloriesIn,
      caloriesBurned: yesterdaySummary.caloriesOut,
      waterCups: yesterdaySummary.waterCups,
      healthScore: yesterdaySummary.healthScore,
      streakDays: streak,
      isVietnamese: LocaleService.isVietnamese,
    );

    await saveDailyAiBriefing(briefing);
    return briefing;
  }

  static const String _keyWeightLogs = 'user_weight_logs_history';

  /// Lưu bản ghi cân nặng mới và cập nhật hồ sơ người dùng
  static Future<void> logWeight(double weight, {DateTime? date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetDate = date ?? DateTime.now();
      final dateStr = targetDate.toIso8601String().split('T')[0];
      
      final rawLogs = prefs.getStringList(_keyWeightLogs) ?? [];
      List<Map<String, dynamic>> logs = [];
      for (final s in rawLogs) {
        try {
          logs.add(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {}
      }

      logs.removeWhere((item) => item['date'] == dateStr);
      logs.add({
        'date': dateStr,
        'weight': weight,
        'timestamp': targetDate.toIso8601String(),
      });
      logs.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));

      await prefs.setStringList(
        _keyWeightLogs,
        logs.map((e) => jsonEncode(e)).toList(),
      );

      final profile = await getUserProfile();
      final updatedProfile = profile.copyWith(weight: weight);
      await saveUserProfile(updatedProfile);

      notifyProfileChanged();
    } catch (e) {
      debugPrint("Lỗi lưu nhật ký cân nặng: $e");
    }
  }

  /// Lấy danh sách lịch sử cân nặng
  static Future<List<Map<String, dynamic>>> getWeightLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawLogs = prefs.getStringList(_keyWeightLogs) ?? [];
      List<Map<String, dynamic>> logs = [];
      for (final s in rawLogs) {
        try {
          logs.add(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {}
      }
      if (logs.isEmpty) {
        final profile = await getUserProfile();
        final now = DateTime.now();
        final dateStr = now.toIso8601String().split('T')[0];
        logs.add({
          'date': dateStr,
          'weight': profile.weight,
          'timestamp': now.toIso8601String(),
        });
      }
      logs.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
      return logs;
    } catch (e) {
      debugPrint("Lỗi đọc lịch sử cân nặng: $e");
      return [];
    }
  }

  // --- AI CHATBOT HISTORY (LOCAL CACHE + CLOUD FIRESTORE) ---

  static const String _keyAiChatHistory = 'ai_chat_history';

  /// Lưu tin nhắn AI Chat vào Local Cache (SharedPreferences)
  static Future<void> saveLocalChatMessage(ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyAiChatHistory) ?? [];
      final list = rawList
          .map((s) {
            try {
              return ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<ChatMessage>()
          .toList();

      final idx = list.indexWhere((m) => m.id == message.id);
      if (idx >= 0) {
        list[idx] = message;
      } else {
        list.add(message);
      }

      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Giữ tối đa 200 tin nhắn gần nhất trong local cache
      final trimmed = list.length > 200 ? list.sublist(list.length - 200) : list;
      final encoded = trimmed.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_keyAiChatHistory, encoded);
      notifyChatChanged();
    } catch (e) {
      debugPrint("Lỗi lưu tin nhắn chat cục bộ: $e");
    }
  }

  /// Lấy danh sách lịch sử tin nhắn AI Chat từ Local Cache
  static Future<List<ChatMessage>> getLocalChatHistory({int limit = 100}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyAiChatHistory) ?? [];
      final list = rawList
          .map((s) {
            try {
              return ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<ChatMessage>()
          .toList();

      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (list.length > limit) {
        return list.sublist(list.length - limit);
      }
      return list;
    } catch (e) {
      debugPrint("Lỗi đọc lịch sử chat cục bộ: $e");
      return [];
    }
  }

  /// Lưu nhiều tin nhắn từ Cloud về Local Cache (dùng khi Sync)
  static Future<void> saveMultipleLocalChatMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getLocalChatHistory(limit: 500);
      final Map<String, ChatMessage> map = {for (var m in existing) m.id: m};

      for (final m in messages) {
        map[m.id] = m;
      }

      final combined = map.values.toList();
      combined.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final trimmed = combined.length > 200 ? combined.sublist(combined.length - 200) : combined;
      final encoded = trimmed.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_keyAiChatHistory, encoded);
      notifyChatChanged();
    } catch (e) {
      debugPrint("Lỗi đồng bộ nhiều tin nhắn chat: $e");
    }
  }

  /// Xóa toàn bộ lịch sử AI Chat cục bộ
  static Future<void> clearLocalChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAiChatHistory);
      notifyChatChanged();
    } catch (e) {
      debugPrint("Lỗi xóa lịch sử chat cục bộ: $e");
    }
  }

  /// Phương thức Hybrid tổng hợp: Lưu tin nhắn vừa vào Local vừa đẩy lên Cloud Firestore
  static Future<void> saveChatMessage(ChatMessage message) async {
    // 1. Lưu Local Cache ngay lập tức (hiển thị tức thì, bảo đảm hoạt động kể cả khi Offline/Guest mode)
    await saveLocalChatMessage(message);

    // 2. Nếu đã đăng nhập Firebase, tự động đẩy lên Cloud Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().saveChatMessage(message);
      }
    } catch (e) {
      debugPrint("Lưu chat lên Cloud Firestore bỏ qua hoặc thất bại: $e");
    }
  }

  /// Phương thức Hybrid tổng hợp: Xóa lịch sử trên cả Local và Cloud Firestore
  static Future<void> clearAllChatHistory() async {
    await clearLocalChatHistory();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().clearChatHistory();
      }
    } catch (e) {
      debugPrint("Xóa chat trên Cloud Firestore lỗi: $e");
    }
  }
}

class FoodLogEntry {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime timestamp;
  final String mealType;
  final String? imagePath;

  const FoodLogEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
    this.mealType = 'Breakfast',
    this.imagePath,
  });

  static String inferMealType(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 11) {
      return 'Breakfast';
    } else if (hour >= 11 && hour < 16) {
      return 'Lunch';
    } else if (hour >= 17 && hour < 22) {
      return 'Dinner';
    } else {
      return 'Snack';
    }
  }

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
        DateTime.now();
    return FoodLogEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Food Item',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      timestamp: time,
      mealType: json['mealType']?.toString() ?? inferMealType(time),
      imagePath: json['imagePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'timestamp': timestamp.toIso8601String(),
        'mealType': mealType,
        'imagePath': imagePath,
      };
}

class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final bool isUnlocked;
  final int currentProgress;
  final int maxProgress;
  final String progressText;
  final Color themeColor;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.isUnlocked,
    required this.currentProgress,
    required this.maxProgress,
    required this.progressText,
    required this.themeColor,
  });
}

class DailyWaterLog {
  final String date;
  final int cups;
  final int volumeMl;
  final DateTime updatedAt;

  const DailyWaterLog({
    required this.date,
    required this.cups,
    required this.volumeMl,
    required this.updatedAt,
  });

  bool get isGoalReached => cups >= 8 || volumeMl >= 2000;

  Map<String, dynamic> toJson() => {
        'date': date,
        'cups': cups,
        'volumeMl': volumeMl,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DailyWaterLog.fromJson(Map<String, dynamic> json) {
    return DailyWaterLog(
      date: json['date']?.toString() ?? '',
      cups: (json['cups'] as num?)?.toInt() ?? 0,
      volumeMl: (json['volumeMl'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class DailyActivitySummary {
  final String date;
  final int steps;
  final double distanceKm;
  final int stepCalories;
  final int caloriesIn;
  final int caloriesOut;
  final int bmr;
  final int workoutCalories;
  final int workoutMinutes;
  final int waterMl;
  final int waterCups;
  final int healthScore;
  final String healthStatus;
  final int netBalance;
  final DateTime updatedAt;

  const DailyActivitySummary({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.stepCalories,
    required this.caloriesIn,
    required this.caloriesOut,
    required this.bmr,
    required this.workoutCalories,
    required this.workoutMinutes,
    required this.waterMl,
    required this.waterCups,
    required this.healthScore,
    required this.healthStatus,
    required this.netBalance,
    required this.updatedAt,
  });

  /// Kiểm tra xem ngày này có hoạt động thực tế nào từ người dùng không
  bool get hasActivity =>
      steps > 0 ||
      caloriesIn > 0 ||
      workoutMinutes > 0 ||
      workoutCalories > 0 ||
      waterCups > 0;

  Map<String, dynamic> toJson() => {
        'date': date,
        'steps': steps,
        'distanceKm': distanceKm,
        'stepCalories': stepCalories,
        'caloriesIn': caloriesIn,
        'caloriesOut': caloriesOut,
        'bmr': bmr,
        'workoutCalories': workoutCalories,
        'workoutMinutes': workoutMinutes,
        'waterMl': waterMl,
        'waterCups': waterCups,
        'healthScore': healthScore,
        'healthStatus': healthStatus,
        'netBalance': netBalance,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) {
    return DailyActivitySummary(
      date: json['date']?.toString() ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      stepCalories: (json['stepCalories'] as num?)?.toInt() ?? 0,
      caloriesIn: (json['caloriesIn'] as num?)?.toInt() ?? 0,
      caloriesOut: (json['caloriesOut'] as num?)?.toInt() ?? 0,
      bmr: (json['bmr'] as num?)?.toInt() ?? 0,
      workoutCalories: (json['workoutCalories'] as num?)?.toInt() ?? 0,
      workoutMinutes: (json['workoutMinutes'] as num?)?.toInt() ?? 0,
      waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
      waterCups: (json['waterCups'] as num?)?.toInt() ?? 0,
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
      healthStatus: json['healthStatus']?.toString() ?? 'CẦN CẢI THIỆN',
      netBalance: (json['netBalance'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
