import '../services/locale_service.dart';
import '../services/user_metrics_service.dart';

class UserProfile {
  final String name;
  final String gender; // 'male' or 'female'
  final int age;
  final double height; // cm
  final double weight; // kg
  final double targetWeight; // kg
  final double activityLevel; // 1.2 (sedentary), 1.375 (light), 1.55 (moderate), 1.725 (active), 1.9 (very active)
  final String fitnessGoal; // 'cutting', 'bulking', 'balanced', 'endurance'
  final int avatarIndex;

  const UserProfile({
    required this.name,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.activityLevel,
    required this.fitnessGoal,
    this.avatarIndex = 0,
  });

  /// Default baseline profile for a new user
  factory UserProfile.defaultProfile() {
    return const UserProfile(
      name: 'Athlete',
      gender: 'male',
      age: 24,
      height: 175.0,
      weight: 70.0,
      targetWeight: 68.0,
      activityLevel: 1.55, // Moderate exercise (3-5 days/week)
      fitnessGoal: 'balanced',
      avatarIndex: 0,
    );
  }

  /// Body Mass Index (BMI) = weight (kg) / (height (m))^2
  double get bmi => UserMetricsService.calculateBmi(weightKg: weight, heightCm: height);

  /// BMI Health Category Classification
  String get bmiCategory => UserMetricsService.getBmiCategory(bmi);

  String get goalDisplayName {
    if (LocaleService.isVietnamese) {
      switch (fitnessGoal.toLowerCase()) {
        case 'cutting':
          return 'Siết Mỡ';
        case 'bulking':
          return 'Tăng Cơ';
        case 'endurance':
          return 'Bền Bỉ';
        case 'balanced':
        default:
          return 'Cân Bằng';
      }
    } else {
      switch (fitnessGoal.toLowerCase()) {
        case 'cutting':
          return 'Cutting';
        case 'bulking':
          return 'Bulking';
        case 'endurance':
          return 'Endurance';
        case 'balanced':
        default:
          return 'Balanced';
      }
    }
  }

  /// Basal Metabolic Rate (BMR) calculated via Mifflin-St Jeor Equation
  double get bmr => UserMetricsService.calculateBmr(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: gender,
      );

  /// Total Daily Energy Expenditure (TDEE) = BMR * Activity Multiplier
  double get tdee => UserMetricsService.calculateTdee(
        bmr: bmr,
        activityLevel: activityLevel,
      );

  /// Dynamic Daily Calorie Target based on fitness goal
  int get targetCalories => UserMetricsService.calculateTargetCalories(
        tdee: tdee,
        fitnessGoal: fitnessGoal,
      );

  /// Dynamic Daily Macro Split based on bodyweight and fitness goal:
  /// - Protein: 1.8g - 2.2g per kg bodyweight
  /// - Fat: 20% - 25% of total calories (9 kcal/g)
  /// - Carbs: Remaining calories (4 kcal/g)
  Map<String, int> get targetMacros {
    final totalCals = targetCalories;

    // Protein calculation based on goal
    double proteinPerKg;
    switch (fitnessGoal) {
      case 'cutting':
        proteinPerKg = 2.2; // High protein to preserve lean muscle during deficit
        break;
      case 'bulking':
        proteinPerKg = 2.0; // Optimal protein for hypertrophy
        break;
      case 'endurance':
        proteinPerKg = 1.6;
        break;
      case 'balanced':
      default:
        proteinPerKg = 1.8;
        break;
    }

    final int targetProtein = (weight * proteinPerKg).round().clamp(50, 350);
    final int proteinCals = targetProtein * 4;

    // Fat calculation (25% of calories on cutting/balanced, 20% on bulking)
    final double fatRatio = (fitnessGoal == 'bulking') ? 0.20 : 0.25;
    final int fatCals = (totalCals * fatRatio).round();
    final int targetFat = (fatCals / 9.0).round().clamp(30, 150);

    // Carbs calculation (remaining calories)
    final int remainingCals = (totalCals - proteinCals - (targetFat * 9)).clamp(200, 4000);
    final int targetCarbs = (remainingCals / 4.0).round().clamp(50, 600);

    return {
      'calories': totalCals,
      'protein': targetProtein,
      'carbs': targetCarbs,
      'fat': targetFat,
    };
  }

  int get targetProtein => targetMacros['protein'] ?? 120;
  int get targetCarbs => targetMacros['carbs'] ?? 200;
  int get targetFat => targetMacros['fat'] ?? 60;

  UserProfile copyWith({
    String? name,
    String? gender,
    int? age,
    double? height,
    double? weight,
    double? targetWeight,
    double? activityLevel,
    String? fitnessGoal,
    int? avatarIndex,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel,
      'fitnessGoal': fitnessGoal,
      'avatarIndex': avatarIndex,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? 'Athlete',
      gender: json['gender']?.toString() ?? 'male',
      age: (json['age'] as num?)?.toInt() ?? 24,
      height: (json['height'] as num?)?.toDouble() ?? 175.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 68.0,
      activityLevel: (json['activityLevel'] as num?)?.toDouble() ?? 1.55,
      fitnessGoal: json['fitnessGoal']?.toString() ?? 'balanced',
      avatarIndex: (json['avatarIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
