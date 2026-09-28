import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fitness_badge.dart';
import '../utils/app_haptics.dart';
import 'storage_service.dart';

class AchievementService {
  static const String _keyUnlockedBadges = 'unlocked_achievement_badges_v1';
  static final StreamController<FitnessBadge> _badgeUnlockController =
      StreamController<FitnessBadge>.broadcast();

  static Stream<FitnessBadge> get onBadgeUnlocked =>
      _badgeUnlockController.stream;

  /// Danh mục các huy hiệu chính thức trong game hóa
  static List<FitnessBadge> _getBaseBadges() {
    return [
      const FitnessBadge(
        id: 'streak_3',
        titleVi: 'Khởi đầu vàng',
        titleEn: 'Golden Start',
        descriptionVi: 'Duy trì chuỗi đăng nhập và rèn luyện 3 ngày liên tục.',
        descriptionEn: 'Maintain a 3-day consecutive workout & login streak.',
        iconEmoji: '⚡',
        category: 'streak',
        progressLabel: '0/3 ngày',
      ),
      const FitnessBadge(
        id: 'streak_7',
        titleVi: 'Chiến thần kiên trì',
        titleEn: 'Persistence Warrior',
        descriptionVi: 'Chinh phục chuỗi kỷ luật 7 ngày không gián đoạn.',
        descriptionEn: 'Achieve an unbroken 7-day fitness streak.',
        iconEmoji: '🔥',
        category: 'streak',
        progressLabel: '0/7 ngày',
      ),
      const FitnessBadge(
        id: 'streak_14',
        titleVi: 'Kỷ luật bất diệt',
        titleEn: 'Unstoppable Momentum',
        descriptionVi: 'Duy trì chuỗi rèn luyện 14 ngày liên tiếp.',
        descriptionEn: 'Maintain a 14-day consecutive active streak.',
        iconEmoji: '⚔️',
        category: 'streak',
        progressLabel: '0/14 ngày',
      ),
      const FitnessBadge(
        id: 'water_master',
        titleVi: 'Bậc thầy Hydration',
        titleEn: 'Hydration Master',
        descriptionVi: 'Uống đủ 8 cốc nước trong ít nhất 3 ngày.',
        descriptionEn: 'Hit full 8 cups of water on at least 3 days.',
        iconEmoji: '💧',
        category: 'water',
        progressLabel: '0/3 ngày',
      ),
      const FitnessBadge(
        id: 'water_8_today',
        titleVi: 'Thủy thần 8 cốc',
        titleEn: 'Hydration Hero',
        descriptionVi: 'Hoàn thành đủ 8 cốc nước (2.000ml) trong ngày hôm nay.',
        descriptionEn: 'Drink 8 cups of water in a single day.',
        iconEmoji: '🌊',
        category: 'water',
        progressLabel: '0/8 cốc',
      ),
      const FitnessBadge(
        id: 'walking_king',
        titleVi: 'Vua đi bộ',
        titleEn: 'Walking King',
        descriptionVi: 'Chinh phục cột mốc 10.000 bước chân trong một ngày.',
        descriptionEn: 'Reach 10,000 steps in a single day.',
        iconEmoji: '👑',
        category: 'steps',
        progressLabel: '0/10.000 bước',
      ),
      const FitnessBadge(
        id: 'iron_discipline',
        titleVi: 'Kỷ luật thép',
        titleEn: 'Iron Discipline',
        descriptionVi: 'Ghi nhận đầy đủ 3 bữa ăn (Sáng, Trưa, Tối) trong một ngày.',
        descriptionEn: 'Log at least 3 meals (Breakfast, Lunch, Dinner) in a day.',
        iconEmoji: '🛡️',
        category: 'food',
        progressLabel: '0/3 bữa',
      ),
      const FitnessBadge(
        id: 'fat_burner',
        titleVi: 'Siết mỡ siêu đẳng',
        titleEn: 'Ultimate Deficit',
        descriptionVi: 'Đạt thâm hụt năng lượng trên 500 kcal trong một ngày.',
        descriptionEn: 'Achieve a calorie deficit of over 500 kcal in a day.',
        iconEmoji: '💎',
        category: 'energy',
        progressLabel: '0/500 kcal',
      ),
      const FitnessBadge(
        id: 'workout_champion',
        titleVi: 'Chiến binh phòng tập',
        titleEn: 'Workout Champion',
        descriptionVi: 'Hoàn thành ít nhất một bài tập thể lực hoặc cardio.',
        descriptionEn: 'Complete at least 1 workout session.',
        iconEmoji: '🏋️',
        category: 'workout',
        progressLabel: '0/1 bài',
      ),
    ];
  }

  /// Tải danh sách tất cả các huy hiệu kèm tiến độ thực tế
  static Future<List<FitnessBadge>> getBadges({bool triggerUnlock = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final rawUnlocked = prefs.getStringList(_keyUnlockedBadges) ?? [];
    final Map<String, DateTime> unlockedMap = {};
    for (final item in rawUnlocked) {
      try {
        final parts = item.split('|');
        if (parts.length >= 2) {
          unlockedMap[parts[0]] = DateTime.tryParse(parts[1]) ?? DateTime.now();
        } else {
          unlockedMap[parts[0]] = DateTime.now();
        }
      } catch (_) {}
    }

    // Lấy dữ liệu thực tế từ StorageService
    final streak = await StorageService.getCurrentStreak();
    final todaySteps = await StorageService.getTodaySteps();
    final todayWater = await StorageService.getWaterCupsToday();
    final todayFood = await StorageService.getFoodLogsByDate(DateTime.now());
    final todaySummary = await StorageService.getDailySummary(DateTime.now());
    final workouts = await StorageService.getWorkoutLogsByDate(DateTime.now());

    // Đếm số bữa ăn khác nhau
    final mealTypes = todayFood.map((e) => e.mealType.toLowerCase()).toSet();
    int loggedMealsCount = mealTypes.length;

    // Đếm số ngày uống đủ 8 cốc từ lịch sử
    final waterHistory = await StorageService.getWaterHistoryLogs();
    int daysWith8Cups = waterHistory.where((log) => log.cups >= 8).length;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    if (todayWater >= 8 && !waterHistory.any((log) => log.date == todayStr)) {
      daysWith8Cups++;
    }

    final baseBadges = _getBaseBadges();
    final List<FitnessBadge> evaluatedBadges = [];
    final List<FitnessBadge> newlyUnlocked = [];

    for (final badge in baseBadges) {
      bool isUnlocked = unlockedMap.containsKey(badge.id);
      DateTime? unlockedTime = unlockedMap[badge.id];
      double progress = 0.0;
      String progressLabel = badge.progressLabel;

      switch (badge.id) {
        case 'streak_3':
          progress = (streak / 3.0).clamp(0.0, 1.0);
          progressLabel = '$streak/3 ngày';
          if (streak >= 3) isUnlocked = true;
          break;
        case 'streak_7':
          progress = (streak / 7.0).clamp(0.0, 1.0);
          progressLabel = '$streak/7 ngày';
          if (streak >= 7) isUnlocked = true;
          break;
        case 'streak_14':
          progress = (streak / 14.0).clamp(0.0, 1.0);
          progressLabel = '$streak/14 ngày';
          if (streak >= 14) isUnlocked = true;
          break;
        case 'water_master':
          progress = (daysWith8Cups / 3.0).clamp(0.0, 1.0);
          progressLabel = '$daysWith8Cups/3 ngày';
          if (daysWith8Cups >= 3) isUnlocked = true;
          break;
        case 'water_8_today':
          progress = (todayWater / 8.0).clamp(0.0, 1.0);
          progressLabel = '$todayWater/8 cốc';
          if (todayWater >= 8) isUnlocked = true;
          break;
        case 'walking_king':
          progress = (todaySteps / 10000.0).clamp(0.0, 1.0);
          progressLabel = '$todaySteps/10.000 bước';
          if (todaySteps >= 10000) isUnlocked = true;
          break;
        case 'iron_discipline':
          progress = (loggedMealsCount / 3.0).clamp(0.0, 1.0);
          progressLabel = '$loggedMealsCount/3 bữa';
          if (loggedMealsCount >= 3 || todayFood.length >= 3) isUnlocked = true;
          break;
        case 'fat_burner':
          final deficit = -todaySummary.netBalance;
          progress = deficit > 0 ? (deficit / 500.0).clamp(0.0, 1.0) : 0.0;
          progressLabel = '${deficit > 0 ? deficit : 0}/500 kcal';
          if (deficit >= 500) isUnlocked = true;
          break;
        case 'workout_champion':
          progress = workouts.isNotEmpty ? 1.0 : 0.0;
          progressLabel = '${workouts.length}/1 bài';
          if (workouts.isNotEmpty) isUnlocked = true;
          break;
      }

      if (isUnlocked && !unlockedMap.containsKey(badge.id)) {
        unlockedTime = DateTime.now();
        unlockedMap[badge.id] = unlockedTime;
        newlyUnlocked.add(badge.copyWith(
          isUnlocked: true,
          unlockedAt: unlockedTime,
          progress: 1.0,
        ));
      }

      evaluatedBadges.add(badge.copyWith(
        isUnlocked: isUnlocked,
        unlockedAt: unlockedTime,
        progress: isUnlocked ? 1.0 : progress,
        progressLabel: isUnlocked ? 'ĐÃ ĐẠT 🎉' : progressLabel,
      ));
    }

    // Nếu có huy hiệu mới được mở khóa, lưu lại và phát thông báo
    if (newlyUnlocked.isNotEmpty) {
      final updatedList = unlockedMap.entries
          .map((e) => '${e.key}|${e.value.toIso8601String()}')
          .toList();
      await prefs.setStringList(_keyUnlockedBadges, updatedList);

      if (triggerUnlock) {
        for (final b in newlyUnlocked) {
          AppHaptics.success();
          _badgeUnlockController.add(b);
        }
      }
    }

    return evaluatedBadges;
  }

  /// Kiểm tra nhanh sau các hành động (uống nước, ghi nhận ăn uống, tập luyện)
  static Future<void> checkBadges() async {
    await getBadges(triggerUnlock: true);
  }
}
