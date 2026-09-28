import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/storage_service.dart';
import 'package:fitness_tracker/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Food Tab - Storage & Meal Classification Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Food items are categorized into specified meal categories', () async {
      final now = DateTime.now();
      final morning = DateTime(now.year, now.month, now.day, 7, 30);
      final noon = DateTime(now.year, now.month, now.day, 12, 15);
      final evening = DateTime(now.year, now.month, now.day, 19, 0);
      final night = DateTime(now.year, now.month, now.day, 22, 30);

      // Log Breakfast
      await StorageService.logFoodItem(
        FoodInfo(name: 'Oatmeal & Berries', calories: 350, protein: 12, carbs: 60, fat: 5),
        timestamp: morning,
        mealType: 'Breakfast',
      );

      // Log Lunch
      await StorageService.logFoodItem(
        FoodInfo(name: 'Grilled Chicken & Rice', calories: 650, protein: 50, carbs: 70, fat: 15),
        timestamp: noon,
        mealType: 'Lunch',
      );

      // Log Dinner
      await StorageService.logFoodItem(
        FoodInfo(name: 'Salmon Salad', calories: 500, protein: 40, carbs: 15, fat: 22),
        timestamp: evening,
        mealType: 'Dinner',
      );

      // Log Snack
      await StorageService.logFoodItem(
        FoodInfo(name: 'Greek Yogurt', calories: 150, protein: 15, carbs: 10, fat: 2),
        timestamp: night,
        mealType: 'Snack',
      );

      // Verify each meal retrieval
      final breakfast = await StorageService.getTodayFoodLogsByMeal('Breakfast');
      final lunch = await StorageService.getTodayFoodLogsByMeal('Lunch');
      final dinner = await StorageService.getTodayFoodLogsByMeal('Dinner');
      final snack = await StorageService.getTodayFoodLogsByMeal('Snack');

      expect(breakfast.length, 1);
      expect(breakfast.first.name, 'Oatmeal & Berries');
      expect(lunch.length, 1);
      expect(lunch.first.name, 'Grilled Chicken & Rice');
      expect(dinner.length, 1);
      expect(dinner.first.name, 'Salmon Salad');
      expect(snack.length, 1);
      expect(snack.first.name, 'Greek Yogurt');

      // Verify meal calories
      expect(await StorageService.getTodayMealCalories('Breakfast'), 350);
      expect(await StorageService.getTodayMealCalories('Lunch'), 650);
      expect(await StorageService.getTodayMealCalories('Dinner'), 500);
      expect(await StorageService.getTodayMealCalories('Snack'), 150);

      // Verify total calories and macros
      expect(await StorageService.getTodayTotalCaloriesIn(), 1650);
      final macros = await StorageService.getTodayTotalMacros();
      expect(macros['protein'], 117);
      expect(macros['carbs'], 155);
      expect(macros['fat'], 44);
    });

    test('FoodLogEntry auto-infers meal type based on hour when not specified', () {
      final tMorning = DateTime(2026, 9, 22, 8, 0);
      final tLunch = DateTime(2026, 9, 22, 13, 0);
      final tDinner = DateTime(2026, 9, 22, 19, 30);
      final tSnack = DateTime(2026, 9, 22, 23, 0);

      expect(FoodLogEntry.inferMealType(tMorning), 'Breakfast');
      expect(FoodLogEntry.inferMealType(tLunch), 'Lunch');
      expect(FoodLogEntry.inferMealType(tDinner), 'Dinner');
      expect(FoodLogEntry.inferMealType(tSnack), 'Snack');
    });

    test('FoodLogEntry preserves imagePath and mealType in JSON serialization', () {
      final entry = FoodLogEntry(
        id: 'food_101',
        name: 'Avocado Toast',
        calories: 320,
        protein: 10,
        carbs: 35,
        fat: 16,
        timestamp: DateTime(2026, 9, 22, 9, 0),
        mealType: 'Breakfast',
        imagePath: '/data/user/0/images/toast.jpg',
      );

      final json = entry.toJson();
      final restored = FoodLogEntry.fromJson(json);

      expect(restored.id, 'food_101');
      expect(restored.name, 'Avocado Toast');
      expect(restored.calories, 320);
      expect(restored.mealType, 'Breakfast');
      expect(restored.imagePath, '/data/user/0/images/toast.jpg');
    });

    test('Nutrition Goal save and get works accurately', () async {
      expect(await StorageService.getNutritionGoal(), 'balanced');

      await StorageService.saveNutritionGoal('cutting');
      expect(await StorageService.getNutritionGoal(), 'cutting');

      await StorageService.saveNutritionGoal('bulking');
      expect(await StorageService.getNutritionGoal(), 'bulking');
    });

    test('Hydration Volume tracking in ml and sync with cups', () async {
      expect(await StorageService.getTodayWaterVolume(), 0);

      await StorageService.addWaterVolume(500);
      expect(await StorageService.getTodayWaterVolume(), 500);
      expect(await StorageService.getWaterCupsToday(), 2); // 500ml = 2 cups

      await StorageService.addWaterVolume(250);
      expect(await StorageService.getTodayWaterVolume(), 750);
      expect(await StorageService.getWaterCupsToday(), 3); // 750ml = 3 cups

      await StorageService.removeWaterVolume(250);
      expect(await StorageService.getTodayWaterVolume(), 500);

      await StorageService.resetWaterVolume();
      expect(await StorageService.getTodayWaterVolume(), 0);
      expect(await StorageService.getWaterCupsToday(), 0);
    });
  });

  group('Food Tab - Gemini AI Food Vision Parsing', () {
    test('Correctly parses multimodal vision JSON output', () {
      const geminiVisionOutput = '''
      ```json
      {
        "name": "Grilled Salmon with Asparagus and Quinoa",
        "calories": 520,
        "protein": 42,
        "carbs": 38,
        "fat": 19
      }
      ```
      ''';

      final food = GeminiService.parseFoodJson(geminiVisionOutput);
      expect(food, isNotNull);
      expect(food!.name, 'Grilled Salmon with Asparagus and Quinoa');
      expect(food.calories, 520);
      expect(food.protein, 42);
      expect(food.carbs, 38);
      expect(food.fat, 19);
    });
  });

  group('Food Tab - Portion by Grams Calculation Engine', () {
    test('Calculates accurate macros for Rice (150g) + Chicken (200g) + Veg (100g)', () {
      final meal = GeminiService.calculatePortionedMealOffline(
        riceGrams: 150,
        meatType: 'gà',
        meatGrams: 200,
        vegGrams: 100,
        isVietnamese: true,
      );

      // Rice 150g: 195 kcal, 42g carbs, 4g protein, 0.45g fat
      // Chicken 200g: 330 kcal, 0g carbs, 62g protein, 7.2g fat
      // Veg 100g: 30 kcal, 6g carbs, 2.5g protein, 0.3g fat
      // Total: ~555 kcal, 48g carbs, 69g protein, 8g fat
      expect(meal.calories, closeTo(555, 3));
      expect(meal.carbs, closeTo(48, 2));
      expect(meal.protein, closeTo(69, 2));
      expect(meal.fat, closeTo(8, 2));
      expect(meal.name, contains('Cơm (150g)'));
      expect(meal.name, contains('Thịt gà (200g)'));
      expect(meal.name, contains('Rau (100g)'));
    });

    test('Calculates accurate macros for Beef (150g) and Rice (200g) in English', () {
      final meal = GeminiService.calculatePortionedMealOffline(
        riceGrams: 200,
        meatType: 'beef',
        meatGrams: 150,
        vegGrams: 50,
        notes: 'grilled',
        isVietnamese: false,
      );

      // Rice 200g: 260 kcal, 56g carbs, 5.4g protein, 0.6g fat
      // Beef 150g: 375 kcal, 0g carbs, 39g protein, 22.5g fat
      // Veg 50g: 15 kcal, 3g carbs, 1.25g protein, 0.15g fat
      // Total: ~650 kcal, 59g carbs, 46g protein, 23g fat
      expect(meal.calories, closeTo(650, 3));
      expect(meal.carbs, closeTo(59, 2));
      expect(meal.protein, closeTo(46, 2));
      expect(meal.fat, closeTo(23, 2));
      expect(meal.name, contains('Rice (200g)'));
      expect(meal.name, contains('Beef (150g)'));
      expect(meal.name, contains('(grilled)'));
    });

    test('Handles vegetarian meal (none/0g meat)', () {
      final meal = GeminiService.calculatePortionedMealOffline(
        riceGrams: 200,
        meatType: 'none',
        meatGrams: 0,
        vegGrams: 150,
        isVietnamese: true,
      );

      // Rice 200g: 260 kcal, 56g carbs, 5.4g protein, 0.6g fat
      // Veg 150g: 45 kcal, 9g carbs, 3.75g protein, 0.45g fat
      // Total: ~305 kcal, 65g carbs, 9g protein, 1g fat
      expect(meal.calories, closeTo(305, 3));
      expect(meal.carbs, closeTo(65, 2));
      expect(meal.protein, closeTo(9, 2));
      expect(meal.fat, closeTo(1, 2));
      expect(meal.name, contains('Cơm (200g)'));
      expect(meal.name, contains('Rau (150g)'));
      expect(meal.name, isNot(contains('Thịt')));
    });

    test('Handles Fish, Shrimp, Egg, and Tofu calculations accurately', () {
      final fishMeal = GeminiService.calculatePortionedMealOffline(
        riceGrams: 100,
        meatType: 'cá',
        meatGrams: 150,
        vegGrams: 100,
      );
      // Rice 100g (130) + Fish 150g (210) + Veg 100g (30) = 370 kcal
      expect(fishMeal.calories, 370);
      expect(fishMeal.name, contains('Cá (150g)'));

      final shrimpMeal = GeminiService.calculatePortionedMealOffline(
        riceGrams: 100,
        meatType: 'tôm',
        meatGrams: 100,
        vegGrams: 100,
      );
      // Rice (130) + Shrimp 100g (99) + Veg (30) = 259 kcal
      expect(shrimpMeal.calories, 259);
      expect(shrimpMeal.name, contains('Tôm (100g)'));

      final tofuMeal = GeminiService.calculatePortionedMealOffline(
        riceGrams: 150,
        meatType: 'đậu',
        meatGrams: 200,
        vegGrams: 100,
      );
      // Rice 150g (195) + Tofu 200g (166) + Veg (30) = 391 kcal
      expect(tofuMeal.calories, 391);
      expect(tofuMeal.name, contains('Đậu phụ (200g)'));
    });
  });
}
