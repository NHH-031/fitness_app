import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/storage_service.dart';
import 'package:fitness_tracker/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService - Streak Logic Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('First time user starts with streak 1', () async {
      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 1);
    });

    test('Logging in again on same day preserves streak', () async {
      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 1);

      // Same day second launch
      streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 1);
    });

    test('Logging in on consecutive day increments streak', () async {
      final prefs = await SharedPreferences.getInstance();
      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      DateTime yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);

      await prefs.setString('last_login_date', yesterdayDate.toIso8601String());
      await prefs.setInt('current_streak', 5);

      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 6);
    });

    test('Gap of more than 1 day resets streak to 1', () async {
      final prefs = await SharedPreferences.getInstance();
      DateTime threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      DateTime pastDate = DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day);

      await prefs.setString('last_login_date', pastDate.toIso8601String());
      await prefs.setInt('current_streak', 12);

      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 1);
    });

    test('Missing exactly 1 day (gap of 2 days) resets streak to 1', () async {
      final prefs = await SharedPreferences.getInstance();
      DateTime twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      DateTime pastDate = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);

      await prefs.setString('last_login_date', pastDate.toIso8601String());
      await prefs.setInt('current_streak', 10);

      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 1);
    });

    test('New user joining today has streak clamped to 1 even if dirty cache existed', () async {
      final prefs = await SharedPreferences.getInstance();
      await StorageService.setUserJoinedDate(DateTime.now());
      await prefs.setInt('current_streak', 5);

      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 1);
      expect(await StorageService.getCurrentStreak(), 1);
    });

    test('User with recorded activity on yesterday and logging in today has streak 2', () async {
      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

      // Ghi log hoạt động hôm qua
      await StorageService.logCompletedWorkout(
        title: 'Hít đất',
        durationMinutes: 15,
        calories: 120,
        timestamp: yesterday,
      );

      // Mở app hôm nay
      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 2);
      expect(await StorageService.getCurrentStreak(), 2);
    });

    test('User who joined yesterday gets streak 2 today even without prior workout log', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      await StorageService.setUserJoinedDate(yesterday);

      int streak = await StorageService.checkAndUpdateStreak();
      expect(streak, 2);
      expect(await StorageService.getCurrentStreak(), 2);
    });

    test('Hardware step tracker preserves accumulated steps across device reboot', () async {
      // 1. Khởi tạo mốc bước ban đầu của ngày: cảm biến bắt đầu từ 1000
      int initialSteps = await StorageService.processHardwareSteps(1000);
      expect(initialSteps, 0);

      // 2. Đi được 2500 bước (cảm biến báo 3500)
      int walkedSteps = await StorageService.processHardwareSteps(3500);
      expect(walkedSteps, 2500);
      expect(await StorageService.getTodaySteps(), 2500);

      // 3. Giả lập thiết bị khởi động lại (Reboot): Cảm biến phần cứng bị reset về 50
      int rebootSteps = await StorageService.processHardwareSteps(50);
      // Số bước ngày hôm nay vẫn phải bảo toàn nguyên vẹn là 2500
      expect(rebootSteps, 2500);
      expect(await StorageService.getTodaySteps(), 2500);

      // 4. Tiếp tục đi thêm 100 bước nữa sau khi reboot (cảm biến tăng từ 50 lên 150)
      int nextSteps = await StorageService.processHardwareSteps(150);
      expect(nextSteps, 2600);
      expect(await StorageService.getTodaySteps(), 2600);
    });
  });

  group('StorageService - Water Tracking & Reminder Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Water cups increment and decrement properly', () async {
      expect(await StorageService.getWaterCupsToday(), 0);

      await StorageService.addWaterCup();
      await StorageService.addWaterCup();
      await StorageService.addWaterCup();
      expect(await StorageService.getWaterCupsToday(), 3);

      await StorageService.removeWaterCup();
      expect(await StorageService.getWaterCupsToday(), 2);

      // Decrementing past 0 should stay 0
      await StorageService.removeWaterCup();
      await StorageService.removeWaterCup();
      await StorageService.removeWaterCup();
      expect(await StorageService.getWaterCupsToday(), 0);
    });

    test('Water cups reset to 0 when date changes and archives yesterday to history', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('water_date', '2026-09-22');
      await prefs.setInt('water_cups_today', 7);
      await prefs.setInt('water_volume_ml_today', 1750);

      // Today's call should detect old date, archive it and reset to 0
      int cupsToday = await StorageService.getWaterCupsToday();
      expect(cupsToday, 0);

      final history = await StorageService.getWaterHistoryLogs();
      expect(history.any((log) => log.date == '2026-09-22' && log.cups == 7 && log.volumeMl == 1750), true);
    });

    test('addWaterCup updates both today cups and daily history entry', () async {
      await StorageService.addWaterCup();
      await StorageService.addWaterCup();

      final cups = await StorageService.getWaterCupsToday();
      expect(cups, 2);

      final todayStr = StorageService.getTodayDateString();
      final history = await StorageService.getWaterHistoryLogs();
      final todayLog = history.firstWhere((log) => log.date == todayStr);
      expect(todayLog.cups, 2);
      expect(todayLog.volumeMl, 500);
    });

    test('Water reminder preferences save and load correctly', () async {
      await StorageService.setWaterReminderEnabled(false);
      expect(await StorageService.isWaterReminderEnabled(), false);

      await StorageService.setWaterReminderInterval(3);
      expect(await StorageService.getWaterReminderInterval(), 3);
    });
  });

  group('StorageService - Daily Summary & History Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('DailyActivitySummary serialization and deserialization works correctly', () {
      final now = DateTime.now();
      final summary = DailyActivitySummary(
        date: '2026-09-22',
        steps: 8500,
        distanceKm: 6.375,
        stepCalories: 340,
        caloriesIn: 2100,
        caloriesOut: 2450,
        bmr: 1650,
        workoutCalories: 460,
        workoutMinutes: 45,
        waterMl: 2000,
        waterCups: 8,
        healthScore: 82,
        healthStatus: 'TUYỆT VỜI',
        netBalance: -350,
        updatedAt: now,
      );

      final json = summary.toJson();
      final restored = DailyActivitySummary.fromJson(json);

      expect(restored.date, '2026-09-22');
      expect(restored.steps, 8500);
      expect(restored.distanceKm, 6.375);
      expect(restored.stepCalories, 340);
      expect(restored.caloriesIn, 2100);
      expect(restored.caloriesOut, 2450);
      expect(restored.bmr, 1650);
      expect(restored.workoutCalories, 460);
      expect(restored.workoutMinutes, 45);
      expect(restored.waterMl, 2000);
      expect(restored.waterCups, 8);
      expect(restored.healthScore, 82);
      expect(restored.healthStatus, 'TUYỆT VỜI');
      expect(restored.netBalance, -350);
    });

    test('saveDailySummary and getDailySummary retrieve snapshot properly', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = StorageService.getTodayDateString(yesterday);

      final summary = DailyActivitySummary(
        date: dateStr,
        steps: 10500,
        distanceKm: 7.875,
        stepCalories: 420,
        caloriesIn: 1950,
        caloriesOut: 2500,
        bmr: 1680,
        workoutCalories: 400,
        workoutMinutes: 40,
        waterMl: 2250,
        waterCups: 9,
        healthScore: 92,
        healthStatus: 'XUẤT SẮC',
        netBalance: -550,
        updatedAt: DateTime.now(),
      );

      await StorageService.saveDailySummary(summary);

      final loaded = await StorageService.getDailySummary(yesterday);
      expect(loaded.date, dateStr);
      expect(loaded.steps, 10500);
      expect(loaded.healthScore, 92);
      expect(loaded.netBalance, -550);
    });

    test('saveDailySteps and getStepsByDate work across dates', () async {
      await StorageService.saveDailySteps('2026-09-20', 6000);
      await StorageService.saveDailySteps('2026-09-21', 12000);

      final date20 = DateTime(2026, 9, 20);
      final date21 = DateTime(2026, 9, 21);
      final date22 = DateTime(2026, 9, 22);

      expect(await StorageService.getStepsByDate(date20), 6000);
      expect(await StorageService.getStepsByDate(date21), 12000);
      expect(await StorageService.getStepsByDate(date22), 0);
    });

    test('getDailySummariesList returns list of requested length when joined date is set', () async {
      final weekAgo = DateTime.now().subtract(const Duration(days: 6));
      await StorageService.setUserJoinedDate(weekAgo);
      final list = await StorageService.getDailySummariesList(days: 7);
      expect(list.length, 7);
    });

    test('getDailySummariesList limits to actual days since joined without fake data', () async {
      await StorageService.setUserJoinedDate(DateTime.now());
      final list = await StorageService.getDailySummariesList(days: 7);
      expect(list.length, 1);
    });

    test('Food logging by date separates yesterday and today records', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final food1 = FoodInfo(name: 'Phở bò hôm qua', calories: 500, protein: 25, carbs: 60, fat: 15);
      final food2 = FoodInfo(name: 'Cơm tấm hôm nay', calories: 600, protein: 30, carbs: 70, fat: 20);

      await StorageService.logFoodItem(food1, timestamp: yesterday);
      await StorageService.logFoodItem(food2, timestamp: DateTime.now());

      final yesterdayLogs = await StorageService.getFoodLogsByDate(yesterday);
      final todayLogs = await StorageService.getTodayFoodLogs();

      expect(yesterdayLogs.any((f) => f.name == 'Phở bò hôm qua'), isTrue);
      expect(yesterdayLogs.any((f) => f.name == 'Cơm tấm hôm nay'), isFalse);

      expect(todayLogs.any((f) => f.name == 'Cơm tấm hôm nay'), isTrue);
      expect(todayLogs.any((f) => f.name == 'Phở bò hôm qua'), isFalse);

      final yesterdayCal = await StorageService.getTotalCaloriesInByDate(yesterday);
      expect(yesterdayCal, 500);
    });

    test('Water cups by date separates yesterday and today records', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await StorageService.resetWaterVolume();

      // Today cups should start at 0
      expect(await StorageService.getWaterCupsToday(), 0);

      // Add 2 cups to yesterday
      await StorageService.addWaterCupForDate(yesterday);
      await StorageService.addWaterCupForDate(yesterday);

      expect(await StorageService.getWaterCupsByDate(yesterday), 2);
      expect(await StorageService.getWaterCupsToday(), 0);

      // Remove 1 cup from yesterday
      await StorageService.removeWaterCupForDate(yesterday);
      expect(await StorageService.getWaterCupsByDate(yesterday), 1);
      expect(await StorageService.getWaterCupsToday(), 0);
    });
  });
}
