import 'dart:math';
import '../services/locale_service.dart';

/// Dịch vụ tính toán các chỉ số sinh trắc học và năng lượng chuyên biệt (Single Responsibility Principle).
/// Tách rời hoàn toàn khỏi StorageService để tối ưu hóa kiểm thử và bảo trì.
class UserMetricsService {
  UserMetricsService._();
  static final UserMetricsService instance = UserMetricsService._();

  /// Tính Chỉ số Khối Cơ thể (BMI) = weight (kg) / (height (m))^2
  static double calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    final val = weightKg / (heightM * heightM);
    return double.parse(val.toStringAsFixed(1));
  }

  /// Phân loại tình trạng sức khỏe theo chỉ số BMI
  static String getBmiCategory(double bmi, {bool? isVietnamese}) {
    final vi = isVietnamese ?? LocaleService.isVietnamese;
    if (vi) {
      if (bmi < 18.5) return 'Thiếu cân';
      if (bmi < 24.9) return 'Bình thường';
      if (bmi < 29.9) return 'Thừa cân';
      return 'Béo phì';
    } else {
      if (bmi < 18.5) return 'Underweight';
      if (bmi < 24.9) return 'Normal';
      if (bmi < 29.9) return 'Overweight';
      return 'Obese';
    }
  }

  /// Tính Tỷ lệ Trao đổi Chất Cơ bản (BMR) theo phương trình Mifflin-St Jeor chuẩn y khoa
  /// Nam:   10 * Cân nặng (kg) + 6.25 * Chiều cao (cm) - 5 * Tuổi + 5
  /// Nữ:    10 * Cân nặng (kg) + 6.25 * Chiều cao (cm) - 5 * Tuổi - 161
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    if (gender.trim().toLowerCase() == 'female') {
      return (base - 161).clamp(800.0, 3500.0);
    }
    return (base + 5).clamp(900.0, 4000.0);
  }

  /// Tính Tổng Tiêu hao Năng lượng Hàng ngày (TDEE)
  /// TDEE = BMR * Hệ số hoạt động thể chất (Physical Activity Level)
  static double calculateTdee({
    required double bmr,
    required double activityLevel,
  }) {
    final safeMultiplier = activityLevel.clamp(1.1, 2.5);
    return bmr * safeMultiplier;
  }

  /// Tính mức Calo mục tiêu tùy theo định hướng thể hình (Deficit / Surplus)
  static int calculateTargetCalories({
    required double tdee,
    required String fitnessGoal,
  }) {
    switch (fitnessGoal.toLowerCase()) {
      case 'cutting':
        return (tdee - 450).round().clamp(1200, 5000);
      case 'bulking':
        return (tdee + 350).round().clamp(1500, 6000);
      case 'endurance':
        return (tdee + 150).round().clamp(1400, 5500);
      case 'balanced':
      default:
        return tdee.round().clamp(1300, 5000);
    }
  }

  /// Phân bổ Macros (Đạm / Tinh bột / Chất béo) dựa trên calo mục tiêu và cân nặng
  static Map<String, int> calculateMacroTargets({
    required int targetCalories,
    required double weightKg,
    required String fitnessGoal,
  }) {
    double proteinPerKg;
    double fatPercent;

    switch (fitnessGoal.toLowerCase()) {
      case 'cutting':
        proteinPerKg = 2.2;
        fatPercent = 0.22;
        break;
      case 'bulking':
        proteinPerKg = 2.0;
        fatPercent = 0.25;
        break;
      case 'endurance':
        proteinPerKg = 1.6;
        fatPercent = 0.25;
        break;
      case 'balanced':
      default:
        proteinPerKg = 1.8;
        fatPercent = 0.25;
        break;
    }

    final proteinGrams = (weightKg * proteinPerKg).round().clamp(50, 300);
    final proteinCalories = proteinGrams * 4;

    final fatCalories = targetCalories * fatPercent;
    final fatGrams = (fatCalories / 9).round().clamp(30, 150);

    final remainingCalories = max(0, targetCalories - proteinCalories - (fatGrams * 9));
    final carbsGrams = (remainingCalories / 4).round().clamp(50, 800);

    return {
      'protein': proteinGrams,
      'fat': fatGrams,
      'carbs': carbsGrams,
    };
  }

  /// Tính lượng calo tiêu thụ theo thời gian thực trong ngày
  /// BMR tích lũy từ 0h đến thời điểm hiện tại + Calo tập luyện + Calo đi bộ
  static int calculateRealtimeCaloriesBurned({
    required double personalBmr,
    required int workoutCalories,
    required int stepCalories,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final minutesSinceMidnight = (currentTime.hour * 60) + currentTime.minute;
    final bmrBurnedUntilNow = (personalBmr / 1440.0) * minutesSinceMidnight;

    return (bmrBurnedUntilNow + workoutCalories + stepCalories).round();
  }

  /// Ước tính calo tiêu hao từ số bước chân (Tiêu chuẩn thể thao y học 0.04 kcal/bước)
  static int calculateStepCalories(int steps, {double? weightKg}) {
    if (steps <= 0) return 0;
    return (steps * 0.04).round();
  }

  /// Ước tính quãng đường (km) từ số bước chân
  static double calculateStepDistanceKm(int steps, {double heightCm = 175.0}) {
    if (steps <= 0) return 0.0;
    // Chiều dài sải chân trung bình = 0.415 * Chiều cao (cm)
    final strideMeter = (heightCm * 0.415) / 100.0;
    final km = (steps * strideMeter) / 1000.0;
    return double.parse(km.toStringAsFixed(2));
  }

  // ========================================================
  // PHIÊN BẢN 2.0: TÍNH % MỠ CƠ THỂ THEO CHUẨN HẢI QUÂN HOA KỲ (US NAVY)
  // ========================================================

  /// Tính % Mỡ cơ thể theo công thức US Navy Circumference Method
  /// Nam: 495 / (1.0324 - 0.19077*log10(waist - neck) + 0.15456*log10(height)) - 450
  /// Nữ:  495 / (1.29579 - 0.35004*log10(waist + hips - neck) + 0.22100*log10(height)) - 450
  static double calculateBodyFatPercent({
    required double waistCm,
    required double neckCm,
    required double heightCm,
    double? hipsCm,
    required String gender,
  }) {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return 0.0;

    final isFemale = gender.trim().toLowerCase() == 'female';

    if (isFemale) {
      final hips = hipsCm ?? (waistCm * 1.15);
      final sum = waistCm + hips - neckCm;
      if (sum <= 0) return 15.0;
      final logSum = log(sum) / ln10;
      final logHeight = log(heightCm) / ln10;
      final density = 1.29579 - (0.35004 * logSum) + (0.22100 * logHeight);
      if (density <= 0) return 20.0;
      final bf = (495 / density) - 450;
      return double.parse(bf.clamp(8.0, 55.0).toStringAsFixed(1));
    } else {
      final diff = waistCm - neckCm;
      if (diff <= 0) return 10.0;
      final logDiff = log(diff) / ln10;
      final logHeight = log(heightCm) / ln10;
      final density = 1.0324 - (0.19077 * logDiff) + (0.15456 * logHeight);
      if (density <= 0) return 15.0;
      final bf = (495 / density) - 450;
      return double.parse(bf.clamp(3.0, 50.0).toStringAsFixed(1));
    }
  }

  /// Phân loại % Mỡ cơ thể theo chuẩn Hội đồng Thể dục Hoa Kỳ (ACE)
  static String getBodyFatCategory(
    double bodyFatPercent, {
    required String gender,
    bool? isVietnamese,
  }) {
    final vi = isVietnamese ?? LocaleService.isVietnamese;
    final isFemale = gender.trim().toLowerCase() == 'female';

    if (isFemale) {
      if (bodyFatPercent < 14) return vi ? 'Thiết yếu (Rất thấp)' : 'Essential';
      if (bodyFatPercent < 21) return vi ? 'Vận động viên' : 'Athletes';
      if (bodyFatPercent < 25) return vi ? 'Săn chắc thể hình' : 'Fitness';
      if (bodyFatPercent < 32) return vi ? 'Bình thường' : 'Average';
      return vi ? 'Thừa mỡ' : 'Obese';
    } else {
      if (bodyFatPercent < 6) return vi ? 'Thiết yếu (Rất thấp)' : 'Essential';
      if (bodyFatPercent < 14) return vi ? 'Vận động viên' : 'Athletes';
      if (bodyFatPercent < 18) return vi ? 'Săn chắc thể hình' : 'Fitness';
      if (bodyFatPercent < 25) return vi ? 'Bình thường' : 'Average';
      return vi ? 'Thừa mỡ' : 'Obese';
    }
  }
}

