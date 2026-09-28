import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/models/user_profile.dart';
import 'package:fitness_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfile Model & Biometric Formula Tests', () {
    test('Default user profile has valid baseline values', () {
      final profile = UserProfile.defaultProfile();
      expect(profile.name, 'Athlete');
      expect(profile.gender, 'male');
      expect(profile.age, 24);
      expect(profile.height, 175.0);
      expect(profile.weight, 70.0);
      expect(profile.targetWeight, 68.0);
      expect(profile.fitnessGoal, 'balanced');
      expect(profile.activityLevel, 1.55);
    });

    test('BMI and BMI Category calculation', () {
      // 70 kg, 175 cm -> 70 / (1.75 * 1.75) = 22.86 -> 22.9
      final profileNormal = UserProfile(
        name: 'Alex',
        gender: 'male',
        age: 25,
        height: 175.0,
        weight: 70.0,
        targetWeight: 68.0,
        activityLevel: 1.55,
        fitnessGoal: 'balanced',
      );
      expect(profileNormal.bmi, 22.9);
      expect(profileNormal.bmiCategory.contains('Bình thường'), true);

      // Underweight test: 45 kg, 175 cm -> 14.7
      final profileUnder = profileNormal.copyWith(weight: 45.0);
      expect(profileUnder.bmi < 18.5, true);
      expect(profileUnder.bmiCategory.contains('Thiếu cân'), true);

      // Overweight test: 85 kg, 175 cm -> 27.8
      final profileOver = profileNormal.copyWith(weight: 85.0);
      expect(profileOver.bmi >= 25.0 && profileOver.bmi < 30.0, true);
      expect(profileOver.bmiCategory.contains('Thừa cân'), true);
    });

    test('Mifflin-St Jeor BMR formula for Male and Female', () {
      // Men: 10 * weight (70) + 6.25 * height (175) - 5 * age (25) + 5
      // = 700 + 1093.75 - 125 + 5 = 1673.75 -> 1673.75
      final male = UserProfile(
        name: 'John',
        gender: 'male',
        age: 25,
        height: 175.0,
        weight: 70.0,
        targetWeight: 68.0,
        activityLevel: 1.2,
        fitnessGoal: 'balanced',
      );
      expect(male.bmr, 1673.75);

      // Women: 10 * weight (70) + 6.25 * height (175) - 5 * age (25) - 161
      // = 700 + 1093.75 - 125 - 161 = 1507.75
      final female = male.copyWith(gender: 'female');
      expect(female.bmr, 1507.75);
    });

    test('TDEE depends on activity multiplier', () {
      final base = UserProfile(
        name: 'Alex',
        gender: 'male',
        age: 20,
        height: 180.0,
        weight: 80.0,
        targetWeight: 75.0,
        activityLevel: 1.2, // Sedentary
        fitnessGoal: 'balanced',
      );
      final bmr = base.bmr;
      expect(base.tdee, bmr * 1.2);

      final active = base.copyWith(activityLevel: 1.725);
      expect(active.tdee, bmr * 1.725);
    });

    test('Target calories & macro splits respond to fitness goals', () {
      final base = UserProfile(
        name: 'Alex',
        gender: 'male',
        age: 25,
        height: 175.0,
        weight: 70.0,
        targetWeight: 68.0,
        activityLevel: 1.55,
        fitnessGoal: 'balanced',
      );
      final tdee = base.tdee.round();

      // 1. Balanced
      final balancedMacros = base.targetMacros;
      expect(balancedMacros['calories'], tdee);
      expect(balancedMacros['protein'], (70 * 1.8).round()); // 126g

      // 2. Cutting (-450 kcal deficit, 2.2g/kg protein)
      final cutting = base.copyWith(fitnessGoal: 'cutting');
      final cuttingMacros = cutting.targetMacros;
      expect(cuttingMacros['calories'], tdee - 450);
      expect(cuttingMacros['protein'], (70 * 2.2).round()); // 154g

      // 3. Bulking (+350 kcal surplus, 2.0g/kg protein)
      final bulking = base.copyWith(fitnessGoal: 'bulking');
      final bulkingMacros = bulking.targetMacros;
      expect(bulkingMacros['calories'], tdee + 350);
      expect(bulkingMacros['protein'], (70 * 2.0).round()); // 140g
    });
  });

  group('StorageService UserProfile Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default profile returned if none stored', () async {
      final profile = await StorageService.getUserProfile();
      expect(profile.name, 'Athlete');
      expect(profile.fitnessGoal, 'balanced');
    });

    test('Save and retrieve custom user profile', () async {
      final custom = UserProfile(
        name: 'Sarah Connor',
        gender: 'female',
        age: 29,
        height: 168.0,
        weight: 58.5,
        targetWeight: 56.0,
        activityLevel: 1.725,
        fitnessGoal: 'cutting',
      );

      await StorageService.saveUserProfile(custom);
      final retrieved = await StorageService.getUserProfile();

      expect(retrieved.name, 'Sarah Connor');
      expect(retrieved.gender, 'female');
      expect(retrieved.age, 29);
      expect(retrieved.height, 168.0);
      expect(retrieved.weight, 58.5);
      expect(retrieved.targetWeight, 56.0);
      expect(retrieved.activityLevel, 1.725);
      expect(retrieved.fitnessGoal, 'cutting');
    });

    test('Real-time calories burn uses personal BMR from stored profile', () async {
      // 1. Save profile with known BMR
      final profile = UserProfile(
        name: 'Runner',
        gender: 'male',
        age: 20,
        height: 180.0,
        weight: 80.0,
        targetWeight: 78.0,
        activityLevel: 1.55,
        fitnessGoal: 'balanced',
      );
      await StorageService.saveUserProfile(profile);

      // Halfway through the day: 12:00 PM (hour 12, min 0 -> fraction = 720/1440 = 0.5)
      final now = DateTime.now();
      final noon = DateTime(now.year, now.month, now.day, 12, 0);
      final burned = await StorageService.calculateRealTimeCaloriesBurned(
        currentSteps: 5000,
        now: noon,
      );

      // Expected:
      // BMR = 10*80 + 6.25*180 - 5*20 + 5 = 800 + 1125 - 100 + 5 = 1830
      // Fraction = 0.5 -> BMR accumulated = 1830 * 0.5 = 915
      // Steps burn = 5000 * 0.04 = 200
      // Workouts burn = 0
      // Total = 915 + 200 = 1115
      expect(burned, 1115);
    });
  });
}
