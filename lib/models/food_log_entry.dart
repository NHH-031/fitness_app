/// Model biểu diễn một món ăn / thực phẩm được ghi nhận trong ngày.
class FoodLogEntry {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime timestamp;
  final String mealType;
  final String? imagePath;

  const FoodLogEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
    this.mealType = 'Breakfast',
    this.imagePath,
  });

  static String inferMealType(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 11) {
      return 'Breakfast';
    } else if (hour >= 11 && hour < 16) {
      return 'Lunch';
    } else if (hour >= 17 && hour < 22) {
      return 'Dinner';
    } else {
      return 'Snack';
    }
  }

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
        DateTime.now();
    return FoodLogEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Food Item',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      timestamp: time,
      mealType: json['mealType']?.toString() ??
          json['meal_type']?.toString() ??
          inferMealType(time),
      imagePath: json['imagePath']?.toString() ?? json['image_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'timestamp': timestamp.toIso8601String(),
        'mealType': mealType,
        'imagePath': imagePath,
      };

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal_type': mealType,
        'image_path': imagePath,
        'timestamp': timestamp.toIso8601String(),
        'date': timestamp.toIso8601String().split('T')[0],
      };
}
