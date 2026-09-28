import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/storage_service.dart';
import 'package:fitness_tracker/services/gemini_service.dart';
import 'package:fitness_tracker/services/locale_service.dart';
import 'package:fitness_tracker/widgets/exercise_pose_widget.dart';
import 'package:fitness_tracker/screens/workout_screen.dart';
import 'package:fitness_tracker/widgets/workout_setup_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Activity & Workout Storage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LocaleService.languageNotifier.value = 'en';
    });

    test('Log workout updates weekly minutes, count, and days', () async {
      expect(await StorageService.getWeeklyActiveMinutes(), 0);
      expect(await StorageService.getWeeklyWorkoutCount(), 0);
      expect((await StorageService.getWeeklyWorkoutDays()).isEmpty, true);

      final now = DateTime.now();
      await StorageService.logCompletedWorkout(
        durationMinutes: 20,
        title: 'Push-ups & Abs',
        timestamp: now,
      );

      expect(await StorageService.getWeeklyActiveMinutes(), 20);
      expect(await StorageService.getWeeklyWorkoutCount(), 1);
      final days = await StorageService.getWeeklyWorkoutDays();
      expect(days.contains(now.weekday), true);

      // Log second workout
      await StorageService.logCompletedWorkout(
        durationMinutes: 15,
        title: 'Squats',
        timestamp: now,
      );

      expect(await StorageService.getWeeklyActiveMinutes(), 35);
      expect(await StorageService.getWeeklyWorkoutCount(), 2);
    });

    test('Dawn workout detection before 7 AM', () async {
      expect(await StorageService.hasCompletedMorningWorkout(), false);

      final now = DateTime.now();
      // Morning workout at 6:15 AM
      final earlyMorning = DateTime(now.year, now.month, now.day, 6, 15);
      await StorageService.logCompletedWorkout(
        durationMinutes: 10,
        title: 'Morning Yoga',
        timestamp: earlyMorning,
      );

      expect(await StorageService.hasCompletedMorningWorkout(), true);
    });

    test('getTodayWorkoutLogs retrieves workouts and deleteWorkoutLog removes them', () async {
      final now = DateTime.now();
      final workoutTime = DateTime(now.year, now.month, now.day, 8, 30);
      await StorageService.logCompletedWorkout(
        durationMinutes: 15,
        title: 'Morning Cardio HIIT',
        calories: 120,
        timestamp: workoutTime,
      );

      final todayLogs = await StorageService.getTodayWorkoutLogs();
      expect(todayLogs.length, 1);
      expect(todayLogs.first['title'], 'Morning Cardio HIIT');
      expect(todayLogs.first['calories'], 120);

      // Test delete
      await StorageService.deleteWorkoutLog(workoutTime.toIso8601String());
      final updatedLogs = await StorageService.getTodayWorkoutLogs();
      expect(updatedLogs.isEmpty, true);
    });

    test('Badges unlock when criteria are met', () async {
      // 1. Initial status - all locked
      var badges = await StorageService.getAchievementBadges(
        currentSteps: 3000,
        currentStreak: 2,
      );
      expect(badges.length, 4);
      expect(badges.every((b) => !b.isUnlocked), true);

      // 2. Unlock 10k Steps Warrior
      badges = await StorageService.getAchievementBadges(
        currentSteps: 10500,
        currentStreak: 2,
      );
      final stepsBadge = badges.firstWhere((b) => b.id == '10k_steps');
      expect(stepsBadge.isUnlocked, true);
      expect(stepsBadge.progressText, 'Completed!');

      // 3. Unlock Eternal Flame with 7-day streak
      badges = await StorageService.getAchievementBadges(
        currentSteps: 3000,
        currentStreak: 7,
      );
      final flameBadge = badges.firstWhere((b) => b.id == 'eternal_flame');
      expect(flameBadge.isUnlocked, true);

      // 4. Unlock Cardio Master with 3 weekly workouts
      final now = DateTime.now();
      await StorageService.logCompletedWorkout(durationMinutes: 10, title: 'W1', timestamp: now);
      await StorageService.logCompletedWorkout(durationMinutes: 10, title: 'W2', timestamp: now);
      await StorageService.logCompletedWorkout(durationMinutes: 10, title: 'W3', timestamp: now);

      badges = await StorageService.getAchievementBadges(
        currentSteps: 0,
        currentStreak: 1,
      );
      final cardioBadge = badges.firstWhere((b) => b.id == 'cardio_master');
      expect(cardioBadge.isUnlocked, true);

      // 5. Unlock Dawn Warrior with morning workout
      final morningTime = DateTime(now.year, now.month, now.day, 5, 45);
      await StorageService.logCompletedWorkout(durationMinutes: 15, title: 'Dawn Run', timestamp: morningTime);

      badges = await StorageService.getAchievementBadges(
        currentSteps: 0,
        currentStreak: 1,
      );
      final dawnBadge = badges.firstWhere((b) => b.id == 'dawn_warrior');
      expect(dawnBadge.isUnlocked, true);
    });
  });

  group('GeminiService - AI Routine Models & Fallback Tests', () {
    test('Workout routine parsing and fallback works seamlessly', () {
      final jsonSample = {
        'title': '10-Min Intense Core',
        'durationMinutes': 10,
        'targetGoal': 'Core & Abs',
        'estimatedCalories': 85,
        'coachAdvice': 'Engage your pelvic floor and keep your lower back pressed to the floor.',
        'exercises': [
          {
            'name': 'Crunches',
            'sets': 3,
            'repsOrDuration': '15 reps',
            'formNote': 'Do not pull your neck.',
          },
          {
            'name': 'High-intensity Plank',
            'sets': 3,
            'repsOrDuration': '45 secs',
            'formNote': 'Maintain straight line from shoulders to heels.',
          }
        ]
      };

      final routine = CustomWorkoutRoutine.fromJson(jsonSample);
      expect(routine.title, '10-Min Intense Core');
      expect(routine.durationMinutes, 10);
      expect(routine.estimatedCalories, 85);
      expect(routine.exercises.length, 2);
      expect(routine.exercises[0].name, 'Crunches');
      expect(routine.exercises[0].reps, '15 reps');
      expect(routine.exercises[0].formTip, 'Do not pull your neck.');
      expect(routine.exercises[1].name, 'High-intensity Plank');
    });
  });

  group('Nutrition & Real-Time Calories Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Food logging persists meals and calculates calories and macros', () async {
      expect(await StorageService.getTodayTotalCaloriesIn(), 0);
      final initialLogs = await StorageService.getTodayFoodLogs();
      expect(initialLogs.isEmpty, true);

      // Log Food 1: Pho Bo
      final food1 = FoodInfo(
        name: 'Beef Pho',
        calories: 550,
        protein: 35,
        carbs: 65,
        fat: 16,
      );
      await StorageService.logFoodItem(food1);

      // Log Food 2: Boiled eggs
      final food2 = FoodInfo(
        name: 'Boiled Eggs',
        calories: 140,
        protein: 12,
        carbs: 2,
        fat: 10,
      );
      await StorageService.logFoodItem(food2);

      final logs = await StorageService.getTodayFoodLogs();
      expect(logs.length, 2);
      expect(logs[0].name, 'Boiled Eggs'); // Newest first
      expect(logs[1].name, 'Beef Pho');

      final totalCal = await StorageService.getTodayTotalCaloriesIn();
      expect(totalCal, 690);

      final macros = await StorageService.getTodayTotalMacros();
      expect(macros['protein'], 47);
      expect(macros['carbs'], 67);
      expect(macros['fat'], 26);

      // Delete Food 2
      await StorageService.deleteFoodLog(logs[0].id);
      final remainingLogs = await StorageService.getTodayFoodLogs();
      expect(remainingLogs.length, 1);
      expect(remainingLogs[0].name, 'Beef Pho');
      expect(await StorageService.getTodayTotalCaloriesIn(), 550);
    });

    test('Real-time calories burned accounts for BMR, steps, and workouts', () async {
      final now = DateTime.now();
      final noon = DateTime(now.year, now.month, now.day, 12, 0); // Noon = 50% of day
      // 1. With 0 steps and 0 workouts at noon:
      // Default Profile BMR = 1678.75 * 0.5 = 839 kcal
      final baseBurn = await StorageService.calculateRealTimeCaloriesBurned(
        currentSteps: 0,
        now: noon,
      );
      expect(baseBurn, 839);

      // 2. With 5000 steps:
      // stepsBurn = 5000 * 0.04 = 200 kcal
      final withSteps = await StorageService.calculateRealTimeCaloriesBurned(
        currentSteps: 5000,
        now: noon,
      );
      expect(withSteps, 1039); // 839 + 200

      // 3. Add a workout today with 150 calories:
      await StorageService.logCompletedWorkout(
        durationMinutes: 20,
        title: 'HIIT Cardio',
        calories: 150,
        timestamp: noon,
      );

      final withWorkout = await StorageService.calculateRealTimeCaloriesBurned(
        currentSteps: 5000,
        now: noon,
      );
      expect(withWorkout, 1189); // 839 + 200 + 150
      expect(await StorageService.getTodayWorkoutsCalories(), 150);
    });
  });

  group('Exercise Guide Data & Equipment Weight Tests', () {
    test('ExerciseGuideData correctly classifies bodyweight vs dumbbell exercises', () {
      // Bodyweight exercises - NO weights allowed
      expect(ExerciseGuideData.getForExercise('Hít xà đơn').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Pull-ups').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Hít đất').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Hít đất kim cương').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Plank siết cơ bụng').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Nhảy Burpees đốt mỡ').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Leo núi Mountain Climbers').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Chùng chân Lunges').isDumbbell, false);
      expect(ExerciseGuideData.getForExercise('Gập bụng').isDumbbell, false);

      // Dumbbell exercises - weights allowed
      expect(ExerciseGuideData.getForExercise('Đẩy ngực tạ đơn').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Dumbbell Floor Press').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Đẩy vai qua đầu').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Dumbbell Shoulder Press').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Kéo tạ lưng xô').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Cuốn tạ tay trước').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Squat ôm tạ Goblet').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Deadlift tạ đơn RDL').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Dang tạ ngang').isDumbbell, true);
      expect(ExerciseGuideData.getForExercise('Cầu mông đặt tạ').isDumbbell, true);
    });

    test('WorkoutExercise default weightKg is null for bodyweight', () {
      const bw = WorkoutExercise(
        title: 'Hít xà đơn',
        duration: '3 hiệp x 8 reps',
        calories: '110 kcal',
        equipment: 'bodyweight',
      );
      expect(bw.weightKg, isNull);

      const db = WorkoutExercise(
        title: 'Đẩy ngực tạ đơn',
        duration: '3 hiệp x 10 reps',
        calories: '115 kcal',
        equipment: 'dumbbell',
        weightKg: 10.0,
      );
      expect(db.weightKg, 10.0);
    });

    test('WorkoutCalorieHelper recalculates calories proportionally based on sets and reps', () {
      // 3 sets x 15 reps = 45 reps at 120 kcal base -> ~2.67 kcal/rep
      final calculatedStandard = WorkoutCalorieHelper.calculateAdjustedCalories(
        baseCalories: 120,
        baseSets: 3,
        baseRepsOrSeconds: 15,
        userSets: 3,
        userRepsOrSeconds: 15,
      );
      expect(calculatedStandard, 120);

      // User increases to 4 sets x 15 reps = 60 reps -> (60/45) * 120 = 160 kcal
      final calculatedHigherSets = WorkoutCalorieHelper.calculateAdjustedCalories(
        baseCalories: 120,
        baseSets: 3,
        baseRepsOrSeconds: 15,
        userSets: 4,
        userRepsOrSeconds: 15,
      );
      expect(calculatedHigherSets, 160);

      // User reduces to 2 sets x 10 reps = 20 reps -> (20/45) * 120 = 53 kcal
      final calculatedLower = WorkoutCalorieHelper.calculateAdjustedCalories(
        baseCalories: 120,
        baseSets: 3,
        baseRepsOrSeconds: 15,
        userSets: 2,
        userRepsOrSeconds: 10,
      );
      expect(calculatedLower, 53);
    });

    test('WorkoutCalorieHelper adjusts for dumbbell weight progression', () {
      // 10kg base vs 15kg user -> heavier load increases burn
      final cal10kg = WorkoutCalorieHelper.calculateAdjustedCalories(
        baseCalories: 100,
        baseSets: 3,
        baseRepsOrSeconds: 10,
        userSets: 3,
        userRepsOrSeconds: 10,
        baseWeight: 10.0,
        userWeight: 10.0,
      );
      expect(cal10kg, 100);

      final cal15kg = WorkoutCalorieHelper.calculateAdjustedCalories(
        baseCalories: 100,
        baseSets: 3,
        baseRepsOrSeconds: 10,
        userSets: 3,
        userRepsOrSeconds: 10,
        baseWeight: 10.0,
        userWeight: 15.0,
      );
      expect(cal15kg > 100, true);
    });

    test('GeminiService fallback generates dumbbell workout when equipment is dumbbell', () async {
      final routine = await GeminiService.generateCustomWorkout(
        durationMinutes: 20,
        goal: 'Tăng cơ ngực và tay',
        equipment: 'dumbbell',
      );
      expect(routine.durationMinutes, 20);
      expect(routine.exercises.isNotEmpty, true);
      final hasDumbbellExercise = routine.exercises.any(
        (ex) => ex.name.toLowerCase().contains('tạ') || ex.name.toLowerCase().contains('dumbbell'),
      );
      expect(hasDumbbellExercise, true);
    });

    test('GeminiService fallback generates hybrid workout when equipment is hybrid', () async {
      final routine = await GeminiService.generateCustomWorkout(
        durationMinutes: 25,
        goal: 'Cardio và sức mạnh',
        equipment: 'hybrid',
      );
      expect(routine.durationMinutes, 25);
      expect(routine.exercises.isNotEmpty, true);
      expect(routine.title.toLowerCase().contains('hybrid'), true);
    });
  });
}
