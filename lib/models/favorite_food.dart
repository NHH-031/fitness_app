import 'food_log_entry.dart';

class FavoriteFood {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String? servingSize;
  final String? imagePath;
  final DateTime createdAt;

  const FavoriteFood({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'serving_size': servingSize,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FavoriteFood.fromMap(Map<String, dynamic> map) {
    return FavoriteFood(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toInt() ?? 0,
      fat: (map['fat'] as num?)?.toInt() ?? 0,
      servingSize: map['serving_size']?.toString(),
      imagePath: map['image_path']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FavoriteFood copyWith({
    String? id,
    String? name,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    String? servingSize,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return FavoriteFood(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  FoodLogEntry toFoodLogEntry({String mealType = 'Breakfast', DateTime? timestamp}) {
    final entryTime = timestamp ?? DateTime.now();
    return FoodLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: mealType,
      imagePath: imagePath,
      timestamp: entryTime,
    );
  }
}

