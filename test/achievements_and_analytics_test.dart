import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/storage_service.dart';
import 'package:fitness_tracker/services/achievement_service.dart';
import 'package:fitness_tracker/services/gemini_service.dart';
import 'package:fitness_tracker/models/fitness_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AchievementService & FitnessBadge Tests', () {
    test('Initial badges list contains default badges with correct IDs', () async {
      final badges = await AchievementService.getBadges(triggerUnlock: false);
      expect(badges.isNotEmpty, isTrue);
      expect(badges.any((b) => b.id == 'streak_7'), isTrue);
      expect(badges.any((b) => b.id == 'water_master'), isTrue);
      expect(badges.any((b) => b.id == 'walking_king'), isTrue);
      expect(badges.any((b) => b.id == 'iron_discipline'), isTrue);
    });

    test('Unlocks streak_7 badge when streak reaches 7 and emits stream event', () async {
      // Đặt ngày tham gia cách đây 10 ngày để streak hợp lệ
      await StorageService.setUserJoinedDate(DateTime.now().subtract(const Duration(days: 10)));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 7);

      FitnessBadge? broadcastedBadge;
      final subscription = AchievementService.onBadgeUnlocked.listen((b) {
        if (b.id == 'streak_7') broadcastedBadge = b;
      });

      final badges = await AchievementService.getBadges(triggerUnlock: true);
      await pumpEventQueue(); // Chờ event microtask trên stream xử lý

      final streakBadge = badges.firstWhere((b) => b.id == 'streak_7');

      expect(streakBadge.isUnlocked, isTrue);
      expect(streakBadge.progress, equals(1.0));
      expect(streakBadge.progressLabel, equals('ĐÃ ĐẠT 🎉'));
      expect(broadcastedBadge, isNotNull);
      expect(broadcastedBadge?.id, equals('streak_7'));

      await subscription.cancel();
    });

    test('Unlocks walking_king badge when steps reach 10,000', () async {
      await StorageService.saveTodaySteps(10500);

      final badges = await AchievementService.getBadges(triggerUnlock: false);
      final stepsBadge = badges.firstWhere((b) => b.id == 'walking_king');
      expect(stepsBadge.isUnlocked, isTrue);
      expect(stepsBadge.progress, equals(1.0));
    });

    test('Unlocks iron_discipline badge when 3 meals are logged', () async {
      final today = DateTime.now();
      await StorageService.logFoodItem(
        FoodInfo(name: 'Phở bò', calories: 450, protein: 20, carbs: 55, fat: 12),
        timestamp: today,
        mealType: 'breakfast',
      );
      await StorageService.logFoodItem(
        FoodInfo(name: 'Cơm sườn', calories: 650, protein: 30, carbs: 70, fat: 22),
        timestamp: today,
        mealType: 'lunch',
      );
      await StorageService.logFoodItem(
        FoodInfo(name: 'Canh rong biển', calories: 150, protein: 10, carbs: 15, fat: 5),
        timestamp: today,
        mealType: 'dinner',
      );

      final badges = await AchievementService.getBadges(triggerUnlock: false);
      final mealBadge = badges.firstWhere((b) => b.id == 'iron_discipline');
      expect(mealBadge.isUnlocked, isTrue);
      expect(mealBadge.progress, equals(1.0));
    });

    test('Unlocks water_master badge when 3 days meet hydration goal of 8 cups', () async {
      final y1 = DateTime.now().subtract(const Duration(days: 1));
      final y2 = DateTime.now().subtract(const Duration(days: 2));

      for (int i = 0; i < 8; i++) {
        await StorageService.addWaterCupForDate(y2);
      }
      for (int i = 0; i < 8; i++) {
        await StorageService.addWaterCupForDate(y1);
      }
      for (int i = 0; i < 8; i++) {
        await StorageService.addWaterCup();
      }

      final badges = await AchievementService.getBadges(triggerUnlock: false);
      final waterMasterBadge = badges.firstWhere((b) => b.id == 'water_master');
      expect(waterMasterBadge.isUnlocked, isTrue);
      expect(waterMasterBadge.progress, equals(1.0));
    });
  });

  group('Weight Logs Storage Tests', () {
    test('Logs weight and retrieves in chronological order', () async {
      final now = DateTime.now();
      await StorageService.logWeight(68.5, date: now.subtract(const Duration(days: 2)));
      await StorageService.logWeight(68.2, date: now.subtract(const Duration(days: 1)));
      await StorageService.logWeight(67.9, date: now);

      final logs = await StorageService.getWeightLogs();
      expect(logs.length, equals(3));
      expect(logs.first['weight'], equals(68.5));
      expect(logs.last['weight'], equals(67.9));
    });
  });
}
