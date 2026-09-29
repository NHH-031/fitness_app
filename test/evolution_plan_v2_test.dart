import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/database/app_database.dart';
import 'package:fitness_tracker/models/favorite_food.dart';
import 'package:fitness_tracker/models/body_measurement.dart';
import 'package:fitness_tracker/repositories/body_measurement_repository.dart';
import 'package:fitness_tracker/services/biometric_service.dart';
import 'package:fitness_tracker/services/report_export_service.dart';
import 'package:fitness_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.clearAllUserData();
    WorkoutRepository.invalidateCache();
    NutritionRepository.invalidateCache();
  });

  group('Evolution Plan v2.0 - Phase 1: AI Nutrition & Quick Favorites', () {
    test('FavoriteFood model serialization and conversion to FoodLogEntry', () {
      final fav = FavoriteFood(
        id: 'fav_1',
        name: 'Phở bò tái',
        calories: 450,
        protein: 28,
        carbs: 60,
        fat: 10,
        servingSize: '1 tô (450g)',
        createdAt: DateTime.now(),
      );

      final map = fav.toMap();
      expect(map['id'], 'fav_1');
      expect(map['name'], 'Phở bò tái');
      expect(map['calories'], 450);

      final fromMap = FavoriteFood.fromMap(map);
      expect(fromMap.name, 'Phở bò tái');
      expect(fromMap.protein, 28);

      final logEntry = fav.toFoodLogEntry(mealType: 'Lunch');
      expect(logEntry.name, 'Phở bò tái');
      expect(logEntry.mealType, 'Lunch');
      expect(logEntry.calories, 450);
    });

    test('NutritionRepository handles favorite foods SQLite CRUD operations', () async {
      final repo = NutritionRepository.instance;

      final fav1 = FavoriteFood(
        id: 'fav_pho',
        name: 'Phở Bò',
        calories: 480,
        protein: 30,
        carbs: 65,
        fat: 10,
        servingSize: '1 bát',
        createdAt: DateTime.now(),
      );

      await repo.addFavoriteFood(fav1);

      final list = await repo.getFavoriteFoods();
      expect(list.length, 1);
      expect(list.first.name, 'Phở Bò');

      final isFav = await repo.isFoodFavorite('Phở Bò');
      expect(isFav, true);

      final isNotFav = await repo.isFoodFavorite('Cơm sườn');
      expect(isNotFav, false);

      final fetched = await repo.getFavoriteFoodByName('Phở Bò');
      expect(fetched != null, true);
      expect(fetched!.calories, 480);

      await repo.deleteFavoriteFood('fav_pho');
      final listAfterDelete = await repo.getFavoriteFoods();
      expect(listAfterDelete.isEmpty, true);
    });
  });

  group('Evolution Plan v2.0 - Phase 3: Progressive Overload & PR Queries', () {
    test('WorkoutRepository calculates progressive overload and PRs', () async {
      final repo = WorkoutRepository.instance;

      // 1. Log earlier workout
      await repo.logCompletedWorkout(
        durationMinutes: 45,
        title: 'Bench Press',
        weightKg: 60.0,
        reps: 8,
        sets: 3,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      );

      // 2. Log subsequent workout with heavier weight
      await repo.logCompletedWorkout(
        durationMinutes: 45,
        title: 'Bench Press',
        weightKg: 65.0,
        reps: 6,
        sets: 4,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      );

      // Latest log query
      final latest = await repo.getLatestLogForExercise('Bench Press');
      expect(latest != null, true);
      expect((latest!['weight'] as num).toDouble(), 65.0);
      expect(latest['reps'], 6);

      // Personal Record Weight
      final prWeight = await repo.getPersonalRecordWeight('Bench Press');
      expect(prWeight, 65.0);

      // Personal Record Reps
      final prReps = await repo.getPersonalRecordReps('Bench Press');
      expect(prReps, 8);
    });
  });

  group('Evolution Plan v2.0 - Phase 4: US Navy Body Fat % & Measurements', () {
    test('UserMetricsService US Navy circumference formula calculations', () {
      // Test Male calculation
      final maleBf = UserMetricsService.calculateBodyFatPercent(
        waistCm: 80.0,
        neckCm: 38.0,
        heightCm: 175.0,
        gender: 'male',
      );
      expect(maleBf > 5.0 && maleBf < 25.0, true);

      final maleCategory = UserMetricsService.getBodyFatCategory(
        maleBf,
        gender: 'male',
        isVietnamese: true,
      );
      expect(maleCategory.isNotEmpty, true);

      // Test Female calculation
      final femaleBf = UserMetricsService.calculateBodyFatPercent(
        waistCm: 70.0,
        neckCm: 32.0,
        heightCm: 165.0,
        hipsCm: 95.0,
        gender: 'female',
      );
      expect(femaleBf > 12.0 && femaleBf < 35.0, true);

      final femaleCategory = UserMetricsService.getBodyFatCategory(
        femaleBf,
        gender: 'female',
        isVietnamese: true,
      );
      expect(femaleCategory.isNotEmpty, true);
    });

    test('BodyMeasurementRepository saves and retrieves body measurements', () async {
      final repo = BodyMeasurementRepository.instance;

      final m1 = BodyMeasurement(
        id: 'meas_1',
        date: '2026-10-01',
        waistCm: 82.0,
        neckCm: 38.0,
        chestCm: 100.0,
        hipsCm: 96.0,
        bicepCm: 36.0,
        thighCm: 56.0,
        weight: 72.5,
        bodyFatPercent: 15.5,
        createdAt: DateTime.parse('2026-10-01 08:00:00'),
      );

      final m2 = BodyMeasurement(
        id: 'meas_2',
        date: '2026-10-15',
        waistCm: 80.0,
        neckCm: 38.0,
        chestCm: 101.0,
        hipsCm: 95.0,
        bicepCm: 36.5,
        thighCm: 56.0,
        weight: 71.8,
        bodyFatPercent: 14.2,
        createdAt: DateTime.parse('2026-10-15 08:00:00'),
      );

      await repo.saveMeasurement(m1);
      await repo.saveMeasurement(m2);

      final all = await repo.getMeasurements();
      expect(all.length, 2);
      expect(all.first.date, '2026-10-15');

      final latest = await repo.getLatestMeasurement();
      expect(latest != null, true);
      expect(latest!.id, 'meas_2');
      expect(latest.bodyFatPercent, 14.2);

      await repo.deleteMeasurement('meas_1');
      final afterDelete = await repo.getMeasurements();
      expect(afterDelete.length, 1);
      expect(afterDelete.first.id, 'meas_2');
    });

    test('BiometricService toggles app lock setting in SharedPreferences', () async {
      final biometric = BiometricService.instance;

      expect(await biometric.isAppLockEnabled(), false);

      await biometric.setAppLockEnabled(true);
      expect(await biometric.isAppLockEnabled(), true);

      await biometric.setAppLockEnabled(false);
      expect(await biometric.isAppLockEnabled(), false);
    });

    test('ReportExportService generates structured 30-day health report text', () async {
      // Setup profile and some data
      final profile = (await StorageService.getUserProfile()).copyWith(
        name: 'Nguyễn Văn A',
        weight: 72.0,
        height: 175.0,
      );
      await StorageService.saveUserProfile(profile);

      // Log workout
      await WorkoutRepository.instance.logCompletedWorkout(
        durationMinutes: 60,
        title: 'Ngực & Tay Sau',
        calories: 450,
      );

      final reportText = await ReportExportService.instance.generate30DayReportText();
      expect(reportText.contains('FITNESS TRACKER'), true);
      expect(reportText.contains('Nguyễn Văn A'), true);
      expect(reportText.contains('72.0 kg'), true);
      expect(reportText.contains('Ngực & Tay Sau') || reportText.contains('60 phút'), true);
    });
  });
}
