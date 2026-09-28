import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/gemini_service.dart';
import 'package:fitness_tracker/services/storage_service.dart';

void main() {
  group('GeminiService & FoodInfo JSON Parsing Tests', () {
    test('Correctly parses standard JSON string', () {
      const rawJson = '''
      {
        "name": "Phở bò đặc biệt",
        "calories": 600,
        "protein": 38,
        "carbs": 70,
        "fat": 18
      }
      ''';

      final food = GeminiService.parseFoodJson(rawJson);
      expect(food, isNotNull);
      expect(food!.name, "Phở bò đặc biệt");
      expect(food.calories, 600);
      expect(food.protein, 38);
      expect(food.carbs, 70);
      expect(food.fat, 18);
    });

    test('Correctly strips markdown block (```json ... ```)', () {
      const rawMarkdown = '''
      ```json
      {
        "name": "Bánh mì pate trứng",
        "calories": 450,
        "protein": 18,
        "carbs": 52,
        "fat": 20
      }
      ```
      ''';

      final food = GeminiService.parseFoodJson(rawMarkdown);
      expect(food, isNotNull);
      expect(food!.name, "Bánh mì pate trứng");
      expect(food.calories, 450);
      expect(food.protein, 18);
      expect(food.carbs, 52);
      expect(food.fat, 20);
    });

    test('Correctly extracts JSON embedded inside conversational text', () {
      const rawResponse = '''
      Dưới đây là kết quả phân tích cho món ăn của bạn:
      {
        "name": "Ức gà luộc",
        "calories": 250,
        "protein": 45,
        "carbs": 0,
        "fat": 5
      }
      Chúc bạn ngon miệng và duy trì năng lượng tốt!
      ''';

      final food = GeminiService.parseFoodJson(rawResponse);
      expect(food, isNotNull);
      expect(food!.name, "Ức gà luộc");
      expect(food.protein, 45);
      expect(food.calories, 250);
    });

    test('Handles missing keys gracefully with default values', () {
      const incompleteJson = '''
      {
        "name": "Nước cam ép"
      }
      ''';

      final food = GeminiService.parseFoodJson(incompleteJson);
      expect(food, isNotNull);
      expect(food!.name, "Nước cam ép");
      expect(food.calories, 0);
      expect(food.protein, 0);
      expect(food.carbs, 0);
      expect(food.fat, 0);
    });

    test('Returns null on malformed or empty string without throwing', () {
      expect(GeminiService.parseFoodJson(""), isNull);
      expect(GeminiService.parseFoodJson("Không thể phân tích món ăn"), isNull);
      expect(GeminiService.parseFoodJson("{ invalid json ..."), isNull);
    });

    test('FoodInfo toJson produces valid Map', () {
      final food = FoodInfo(
        name: "Cơm tấm",
        calories: 700,
        protein: 30,
        carbs: 85,
        fat: 25,
      );

      final json = food.toJson();
      expect(json['name'], "Cơm tấm");
      expect(json['calories'], 700);
      expect(json['protein'], 30);
      expect(json['carbs'], 85);
      expect(json['fat'], 25);
    });

    test('Nutrition cache returns instant result without calling remote API', () async {
      expect(GeminiService.cachedFoodCount, greaterThan(10));

      final rice = await GeminiService.analyzeFood('cơm trắng');
      expect(rice, isNotNull);
      expect(rice!.calories, 200);
      expect(rice.carbs, 44);

      final chicken = await GeminiService.analyzeFood('100g ức gà');
      expect(chicken, isNotNull);
      expect(chicken!.protein, 31);
      expect(chicken.calories, 165);
    });

    test('GeminiService API key configuration and resolution works correctly', () async {
      SharedPreferences.setMockInitialValues({});
      // Test setting and retrieving via GeminiService
      GeminiService.setApiKey('test_key_12345');
      expect(GeminiService.apiKey, 'test_key_12345');
      expect(GeminiService.hasValidApiKey, isTrue);

      // Test reset
      GeminiService.setApiKey('');
      expect(GeminiService.hasValidApiKey, isFalse);

      // Test StorageService persistence
      await StorageService.saveGeminiApiKey('storage_test_key');
      expect(await StorageService.getGeminiApiKey(), 'storage_test_key');
      expect(GeminiService.apiKey, 'storage_test_key');

      // Clean up
      await StorageService.saveGeminiApiKey('');
      expect(await StorageService.getGeminiApiKey(), isNull);
    });
  });
}
