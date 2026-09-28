import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import 'workout_repository.dart';
import 'nutrition_repository.dart';
import 'step_repository.dart';
import 'water_repository.dart';

/// Repository quản lý trạng thái tài khoản, hồ sơ cá nhân, chế độ khách, chuỗi hoạt động (Streak) và dọn dẹp khi đăng xuất.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  static const String _keyAppLanguage = 'app_language';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyLastLoginDate = 'last_login_date';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyIsGuestMode = 'is_guest_mode';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyUserJoinedDate = 'user_joined_date';
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyDailySummaries = 'daily_activity_summaries';

  static String _formatDate([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // --- QUẢN LÝ ONBOARDING ---
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  Future<void> setCompletedOnboarding(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasCompletedOnboarding, completed);
  }

  // --- QUẢN LÝ CHẾ ĐỘ KHÁCH (GUEST MODE) ---
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuestMode) ?? false;
  }

  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuestMode, isGuest);
  }

  // --- QUẢN LÝ NGÔN NGỮ ---
  Future<String> getAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppLanguage) ?? 'vi';
  }

  Future<void> saveAppLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLanguage, langCode);
  }

  // --- QUẢN LÝ GEMINI API KEY ---
  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
  }

  Future<void> saveGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_keyGeminiApiKey);
    } else {
      await prefs.setString(_keyGeminiApiKey, trimmed);
    }
    GeminiService.setApiKey(trimmed);
  }

  // --- QUẢN LÝ HỒ SƠ NGƯỜI DÙNG ---
  Future<UserProfile> getUserProfile() async {
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

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfile, jsonEncode(profile.toJson()));
    FirestoreService().saveUserProfile(profile);
  }

  // --- NGÀY BẮT ĐẦU THAM GIA ---
  Future<DateTime> getUserJoinedDate() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? earliest;

    final saved = prefs.getString(_keyUserJoinedDate);
    if (saved != null) {
      final parsed = DateTime.tryParse(saved);
      if (parsed != null) {
        earliest = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resolved = earliest ?? today;
    await prefs.setString(_keyUserJoinedDate, _formatDate(resolved));
    return resolved;
  }

  Future<void> setUserJoinedDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanDate = DateTime(date.year, date.month, date.day);
    await prefs.setString(_keyUserJoinedDate, _formatDate(cleanDate));
  }

  // --- KIỂM TRA HOẠT ĐỘNG TRONG NGÀY ---
  Future<bool> hasActivityOnDate(DateTime date) async {
    final dateStr = _formatDate(date);
    final isToday = dateStr == _formatDate();
    if (isToday) return true;

    final joinedDate = await getUserJoinedDate();
    final joinedStr = _formatDate(joinedDate);
    if (dateStr == joinedStr) {
      return true;
    }

    final steps = await StepRepository.instance.getStepsByDate(date);
    if (steps > 0) return true;

    final caloIn = await NutritionRepository.instance.getTotalCaloriesInByDate(date);
    if (caloIn > 0) return true;

    final workouts = await WorkoutRepository.instance.getWorkoutLogsByDate(date);
    if (workouts.isNotEmpty) return true;

    final water = await WaterRepository.instance.getWaterCupsByDate(date);
    if (water > 0) return true;

    return false;
  }

  // --- TÍNH TOÁN STREAK ---
  Future<int> calculateConsecutiveActiveStreak() async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    int streak = 1;
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

  Future<int> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final String? lastLoginStr = prefs.getString(_keyLastLoginDate);
    int currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;

    final now = DateTime.now();
    final todayStr = _formatDate(now);
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    final joinedDate = await getUserJoinedDate();
    final joinedUtc = DateTime.utc(joinedDate.year, joinedDate.month, joinedDate.day);
    final daysSinceJoined = max(1, todayUtc.difference(joinedUtc).inDays + 1);

    final activityStreak = await calculateConsecutiveActiveStreak();

    if (lastLoginStr == null || currentStreak <= 0) {
      currentStreak = max(activityStreak, daysSinceJoined == 2 ? 2 : 1);
      if (currentStreak > daysSinceJoined) currentStreak = daysSinceJoined;
      if (currentStreak < 1) currentStreak = 1;
      await prefs.setString(_keyLastLoginDate, todayStr);
      await prefs.setInt(_keyCurrentStreak, currentStreak);
      FirestoreService().updateStreak(currentStreak, todayStr);
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
      return currentStreak;
    }

    final lastUtc = DateTime.utc(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
    final dayDiff = todayUtc.difference(lastUtc).inDays;

    if (dayDiff == 0) {
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
      currentStreak++;
      if (activityStreak > currentStreak) {
        currentStreak = activityStreak;
      }
      if (currentStreak > daysSinceJoined) {
        currentStreak = daysSinceJoined;
      }
      await prefs.setString(_keyLastLoginDate, todayStr);
      await prefs.setInt(_keyCurrentStreak, currentStreak);
      FirestoreService().updateStreak(currentStreak, todayStr);
    } else {
      currentStreak = max(activityStreak, 1);
      if (currentStreak > daysSinceJoined) {
        currentStreak = daysSinceJoined;
      }
      await prefs.setString(_keyLastLoginDate, todayStr);
      await prefs.setInt(_keyCurrentStreak, currentStreak);
      FirestoreService().updateStreak(currentStreak, todayStr);
    }

    return currentStreak;
  }

  /// Dọn sạch toàn bộ dữ liệu người dùng khi Sign Out
  Future<void> clearUserDataOnSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserProfile);
    await prefs.remove(_keyLastLoginDate);
    await prefs.remove(_keyCurrentStreak);
    await prefs.remove(_keyIsGuestMode);
    await prefs.remove(_keyHasCompletedOnboarding);
    await prefs.remove(_keyUserJoinedDate);
    await prefs.remove(_keyDailySummaries);

    // Xóa dữ liệu các bảng SQLite
    await AppDatabase.instance.clearAllUserData();

    // Xóa dữ liệu trong Repositories
    await StepRepository.instance.clearAll();
    await WaterRepository.instance.clearAll();
    WorkoutRepository.invalidateCache();
    NutritionRepository.invalidateCache();
  }
}
