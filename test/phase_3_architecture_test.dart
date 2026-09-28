import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/database/app_database.dart';
import 'package:fitness_tracker/repositories/workout_repository.dart';
import 'package:fitness_tracker/repositories/nutrition_repository.dart';
import 'package:fitness_tracker/repositories/water_repository.dart';
import 'package:fitness_tracker/repositories/chat_repository.dart';
import 'package:fitness_tracker/repositories/step_repository.dart';
import 'package:fitness_tracker/repositories/auth_repository.dart';
import 'package:fitness_tracker/services/user_metrics_service.dart';
import 'package:fitness_tracker/models/food_log_entry.dart';
import 'package:fitness_tracker/models/chat_message.dart';
import 'package:fitness_tracker/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.clearAllUserData();
    WorkoutRepository.invalidateCache();
    NutritionRepository.invalidateCache();
    StepRepository.invalidateCache();
  });

  group('Phase 3 - Architecture & Repositories Tests', () {
    test('AppDatabase initializes tables and clearAllUserData works', () async {
      final db = await AppDatabase.instance.database;
      expect(db.isOpen, true);

      // Verify table creation
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((r) => r['name']).toSet();
      expect(tableNames.contains('workout_logs'), true);
      expect(tableNames.contains('food_entries'), true);
      expect(tableNames.contains('daily_water_history'), true);
      expect(tableNames.contains('chat_messages'), true);
    });

    test('WorkoutRepository CRUD and queries work with SQLite', () async {
      final repo = WorkoutRepository.instance;
      final now = DateTime.now();

      await repo.logCompletedWorkout(
        durationMinutes: 30,
        title: 'Bench Press & Triceps',
        calories: 210,
        sets: 4,
        reps: 10,
        weightKg: 60.0,
        equipment: 'Barbell',
        timestamp: now,
      );

      final logs = await repo.getWorkoutLogs();
      expect(logs.length, 1);
      expect(logs.first['title'], 'Bench Press & Triceps');
      expect(logs.first['duration'], 30);
      expect(logs.first['calories'], 210);
      expect(logs.first['sets'], 4);
      expect(logs.first['reps'], 10);
      expect(logs.first['weight'], 60.0);
      expect(logs.first['equipment'], 'Barbell');

      final todayLogs = await repo.getTodayWorkoutLogs();
      expect(todayLogs.length, 1);

      final cals = await repo.getTodayWorkoutsCalories();
      expect(cals, 210);

      final mins = await repo.getTodayWorkoutsMinutes();
      expect(mins, 30);

      // Delete workout
      await repo.deleteWorkoutLog(now.toIso8601String());
      expect((await repo.getWorkoutLogs()).isEmpty, true);
    });

    test('NutritionRepository CRUD and queries work with SQLite', () async {
      final repo = NutritionRepository.instance;
      final now = DateTime.now();

      final entry = FoodLogEntry(
        id: 'food_1',
        name: 'Oatmeal & Protein Shake',
        calories: 450,
        protein: 35,
        carbs: 55,
        fat: 8,
        timestamp: now,
        mealType: 'Breakfast',
      );

      await repo.saveFoodLog(entry);

      final logs = await repo.getFoodLogs();
      expect(logs.length, 1);
      expect(logs.first.name, 'Oatmeal & Protein Shake');
      expect(logs.first.calories, 450);
      expect(logs.first.protein, 35);

      expect(await repo.getTodayTotalCalories(), 450);
      expect(await repo.getTodayTotalProtein(), 35);
      expect(await repo.getTodayTotalCarbs(), 55);
      expect(await repo.getTodayTotalFat(), 8);

      // Delete food
      await repo.deleteFoodLog('food_1');
      expect((await repo.getFoodLogs()).isEmpty, true);
    });

    test('WaterRepository daily tracking and SQLite archiving work', () async {
      final repo = WaterRepository.instance;

      expect(await repo.getWaterCupsToday(), 0);
      await repo.addWaterCup();
      expect(await repo.getWaterCupsToday(), 1);
      expect(await repo.getTodayWaterVolume(), 250);

      await repo.addWaterCup();
      expect(await repo.getWaterCupsToday(), 2);
      expect(await repo.getTodayWaterVolume(), 500);

      await repo.removeWaterCup();
      expect(await repo.getWaterCupsToday(), 1);
      expect(await repo.getTodayWaterVolume(), 250);

      final history = await repo.getWaterHistoryLogs();
      expect(history.isNotEmpty, true);
      expect(history.first.cups, 1);
    });

    test('ChatRepository stores and retrieves messages from SQLite', () async {
      final repo = ChatRepository.instance;
      final now = DateTime.now();

      final msg1 = ChatMessage(
        id: 'msg_1',
        role: 'user',
        text: 'Hello AI Coach',
        timestamp: now,
      );
      final msg2 = ChatMessage(
        id: 'msg_2',
        role: 'model',
        text: 'Hi there! Let us hit your goals today!',
        timestamp: now.add(const Duration(seconds: 1)),
      );

      await repo.saveLocalChatMessage(msg1);
      await repo.saveLocalChatMessage(msg2);

      final history = await repo.getLocalChatHistory();
      expect(history.length, 2);
      expect(history[0].text, 'Hello AI Coach');
      expect(history[1].text, 'Hi there! Let us hit your goals today!');

      await repo.clearLocalChatHistory();
      expect((await repo.getLocalChatHistory()).isEmpty, true);
    });

    test('UserMetricsService biometrics and macro formulas are accurate', () {
      // BMI
      final bmi = UserMetricsService.calculateBmi(weightKg: 75.0, heightCm: 175.0);
      expect(bmi, 24.5);
      expect(UserMetricsService.getBmiCategory(bmi, isVietnamese: true), 'Bình thường');
      expect(UserMetricsService.getBmiCategory(bmi, isVietnamese: false), 'Normal');

      // BMR Male (Mifflin-St Jeor: 10*75 + 6.25*175 - 5*25 + 5 = 750 + 1093.75 - 125 + 5 = 1723.75)
      final bmrMale = UserMetricsService.calculateBmr(weightKg: 75.0, heightCm: 175.0, age: 25, gender: 'male');
      expect(bmrMale, 1723.75);

      // TDEE Moderate (1723.75 * 1.55 = 2671.8125)
      final tdee = UserMetricsService.calculateTdee(bmr: bmrMale, activityLevel: 1.55);
      expect(tdee.round(), 2672);

      // Target calories for cutting (-450)
      final cuttingCal = UserMetricsService.calculateTargetCalories(tdee: tdee, fitnessGoal: 'cutting');
      expect(cuttingCal, 2672 - 450);

      // Macro splits for cutting
      final macros = UserMetricsService.calculateMacroTargets(targetCalories: cuttingCal, weightKg: 75.0, fitnessGoal: 'cutting');
      expect(macros['protein'], (75 * 2.2).round());
      expect(macros.containsKey('carbs'), true);
      expect(macros.containsKey('fat'), true);
    });

    test('AuthRepository profile, onboarding, and sign out work properly', () async {
      final repo = AuthRepository.instance;

      expect(await repo.hasCompletedOnboarding(), false);
      await repo.setCompletedOnboarding(true);
      expect(await repo.hasCompletedOnboarding(), true);

      expect(await repo.isGuestMode(), false);
      await repo.setGuestMode(true);
      expect(await repo.isGuestMode(), true);

      final profile = UserProfile(
        name: 'Alex Johnson',
        gender: 'male',
        age: 28,
        height: 180.0,
        weight: 78.0,
        targetWeight: 75.0,
        activityLevel: 1.55,
        fitnessGoal: 'cutting',
      );
      await repo.saveUserProfile(profile);

      final loaded = await repo.getUserProfile();
      expect(loaded.name, 'Alex Johnson');
      expect(loaded.weight, 78.0);
      expect(loaded.fitnessGoal, 'cutting');

      // Clear user data on sign out
      await repo.clearUserDataOnSignOut();
      expect((await repo.getUserProfile()).name, 'Athlete'); // back to default
      expect(await repo.hasCompletedOnboarding(), false);
      expect(await repo.isGuestMode(), false);
    });
  });
}
