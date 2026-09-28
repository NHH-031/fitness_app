import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_profile.dart';

class FoodInfo {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  FoodInfo({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodInfo.fromJson(Map<String, dynamic> json) {
    return FoodInfo(
      name: json['name']?.toString() ?? 'Unknown Food',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

class GeminiService {
  static const String _modelName = 'gemini-2.0-flash';
  static const String _fallbackModelName = 'gemini-1.5-flash';
  static String _runtimeApiKey = '';

  /// Khóa Gemini API với thứ tự ưu tiên an toàn:
  /// 1. Biến môi trường lúc compile-time: --dart-define=GEMINI_API_KEY=... hoặc --dart-define-from-file=.env
  /// 2. Khóa được cấu hình động lúc runtime thông qua setApiKey(...)
  static String get apiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    return _runtimeApiKey;
  }

  /// Thiết lập API Key lúc runtime (ví dụ: load từ SharedPreferences hoặc cài đặt người dùng)
  static void setApiKey(String key) {
    _runtimeApiKey = key.trim();
  }

  /// Kiểm tra xem đã có API Key hợp lệ hay chưa
  static bool get hasValidApiKey =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE';

  /// Tạo instance GenerativeModel
  static GenerativeModel _createModel({
    String? modelName,
    Content? systemInstruction,
  }) {
    return GenerativeModel(
      model: modelName ?? _modelName,
      apiKey: apiKey,
      systemInstruction: systemInstruction,
    );
  }

  /// Gọi API với cơ chế tự động chuyển sang model dự phòng nếu model chính gặp sự cố
  static Future<GenerateContentResponse> _generateWithFallback(
    List<Content> contents, {
    Content? systemInstruction,
  }) async {
    try {
      return await _createModel(
        modelName: _modelName,
        systemInstruction: systemInstruction,
      ).generateContent(contents);
    } catch (primaryErr) {
      debugPrint(
        "⚠️ [GeminiService] Model chính ($_modelName) lỗi: $primaryErr. Tự động chuyển đổi sang dự phòng ($_fallbackModelName)...",
      );
      return await _createModel(
        modelName: _fallbackModelName,
        systemInstruction: systemInstruction,
      ).generateContent(contents);
    }
  }

  /// Trích xuất và phân tích JSON từ chuỗi phản hồi thô của Gemini
  static FoodInfo? parseFoodJson(String rawText) {
    try {
      String cleanText = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Trích xuất phần JSON nếu có văn bản kèm theo
      final startIndex = cleanText.indexOf('{');
      final endIndex = cleanText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
        cleanText = cleanText.substring(startIndex, endIndex + 1);
      }

      final jsonMap = jsonDecode(cleanText);
      if (jsonMap is Map<String, dynamic>) {
        return FoodInfo.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint("Lỗi phân tích JSON món ăn: $e");
    }
    return null;
  }

  // Bộ nhớ đệm dinh dưỡng thông minh (Zero-latency offline cache)
  static final Map<String, FoodInfo> _nutritionCache = {
    'cơm trắng': FoodInfo(name: 'Cơm trắng (1 bát ~150g)', calories: 200, protein: 4, carbs: 44, fat: 0),
    '1 bát cơm': FoodInfo(name: 'Cơm trắng (1 bát)', calories: 200, protein: 4, carbs: 44, fat: 0),
    'cơm': FoodInfo(name: 'Cơm trắng (1 bát)', calories: 200, protein: 4, carbs: 44, fat: 0),
    'ức gà': FoodInfo(name: 'Ức gà luộc (100g)', calories: 165, protein: 31, carbs: 0, fat: 4),
    'ức gà luộc': FoodInfo(name: 'Ức gà luộc (100g)', calories: 165, protein: 31, carbs: 0, fat: 4),
    '100g ức gà': FoodInfo(name: 'Ức gà (100g)', calories: 165, protein: 31, carbs: 0, fat: 4),
    'trứng luộc': FoodInfo(name: 'Trứng luộc (1 quả)', calories: 78, protein: 6, carbs: 1, fat: 5),
    '1 quả trứng': FoodInfo(name: 'Trứng luộc (1 quả)', calories: 78, protein: 6, carbs: 1, fat: 5),
    'trứng ốp la': FoodInfo(name: 'Trứng ốp la (1 quả)', calories: 110, protein: 6, carbs: 1, fat: 9),
    'phở bò': FoodInfo(name: 'Phở bò', calories: 450, protein: 22, carbs: 62, fat: 12),
    'phở gà': FoodInfo(name: 'Phở gà', calories: 400, protein: 25, carbs: 60, fat: 8),
    'bún chả': FoodInfo(name: 'Bún chả', calories: 530, protein: 27, carbs: 58, fat: 21),
    'bún bò huế': FoodInfo(name: 'Bún bò Huế', calories: 520, protein: 26, carbs: 65, fat: 16),
    'bánh mì thịt': FoodInfo(name: 'Bánh mì thịt', calories: 420, protein: 16, carbs: 50, fat: 17),
    'bánh mì trứng': FoodInfo(name: 'Bánh mì trứng', calories: 360, protein: 13, carbs: 46, fat: 14),
    'yến mạch': FoodInfo(name: 'Yến mạch (50g)', calories: 180, protein: 7, carbs: 32, fat: 3),
    'chuối': FoodInfo(name: 'Chuối (1 quả)', calories: 105, protein: 1, carbs: 27, fat: 0),
    'táo': FoodInfo(name: 'Táo (1 quả)', calories: 95, protein: 1, carbs: 25, fat: 0),
    'sữa chua không đường': FoodInfo(name: 'Sữa chua không đường (1 hộp)', calories: 85, protein: 5, carbs: 7, fat: 4),
    'sữa tươi không đường': FoodInfo(name: 'Sữa tươi không đường (200ml)', calories: 120, protein: 6, carbs: 10, fat: 6),
    'whey protein': FoodInfo(name: 'Whey Protein (1 muỗng ~30g)', calories: 120, protein: 24, carbs: 2, fat: 1),
    'cà phê đen': FoodInfo(name: 'Cà phê đen không đường', calories: 5, protein: 0, carbs: 1, fat: 0),
    'cà phê sữa đá': FoodInfo(name: 'Cà phê sữa đá', calories: 160, protein: 3, carbs: 26, fat: 5),
  };

  /// Lấy số lượng món ăn đã được cache
  static int get cachedFoodCount => _nutritionCache.length;

  /// Xóa sạch bộ nhớ đệm
  static void clearNutritionCache() {
    _nutritionCache.clear();
  }

  static Future<FoodInfo?> analyzeFood(String text) async {
    final cleanQuery = text.trim().toLowerCase();
    if (cleanQuery.isEmpty) return null;

    // 1. Kiểm tra cache tức thì (Zero-latency offline search)
    if (_nutritionCache.containsKey(cleanQuery)) {
      debugPrint("⚡ [Nutrition Cache Hit] Trả về tức thì từ cache: '$cleanQuery'");
      return _nutritionCache[cleanQuery];
    }

    // 2. Kiểm tra nếu query khớp gần đúng với các từ khóa phổ biến trong cache
    for (final entry in _nutritionCache.entries) {
      if (cleanQuery == entry.key || (cleanQuery.contains(entry.key) && cleanQuery.length <= entry.key.length + 5)) {
        debugPrint("⚡ [Nutrition Cache Fuzzy Hit] Khớp từ khóa: '${entry.key}'");
        return entry.value;
      }
    }

    if (!hasValidApiKey) {
      debugPrint("⚠️ [GeminiService] Chưa cấu hình Gemini API Key. Vui lòng cung cấp qua --dart-define=GEMINI_API_KEY hoặc file .env.");
      return null;
    }

    final prompt = '''
You are a professional nutritionist. Analyze the following food description and estimate the nutritional values.
Input: "$text"

MANDATORY: Return ONLY one valid JSON object matching the schema below without any extra text or markdown code blocks:
{
  "name": "Short food name (in English)",
  "calories": (integer estimate in kcal),
  "protein": (integer estimate in grams),
  "carbs": (integer estimate in grams),
  "fat": (integer estimate in grams)
}
''';

    try {
      final response = await _generateWithFallback([Content.text(prompt)]);
      String? resText = response.text;
      if (resText != null) {
        final parsed = parseFoodJson(resText);
        if (parsed != null && parsed.calories > 0) {
          // Lưu vào bộ nhớ đệm cho các lần truy vấn tiếp theo
          _nutritionCache[cleanQuery] = parsed;
          return parsed;
        }
      }
    } catch (e) {
      debugPrint("Gemini API Error: $e");
      return null;
    }
    return null;
  }

  /// Accurate Offline Nutrition Engine for Portioned Meals (per 100g cooked food)
  static FoodInfo calculatePortionedMealOffline({
    required int riceGrams,
    required String meatType,
    required int meatGrams,
    required int vegGrams,
    String? notes,
    bool isVietnamese = true,
  }) {
    // Cooked White Rice: 130 kcal, 28g C, 2.7g P, 0.3g F per 100g
    final double riceCal = (riceGrams * 130) / 100.0;
    final double riceCarbs = (riceGrams * 28.0) / 100.0;
    final double riceProtein = (riceGrams * 2.7) / 100.0;
    final double riceFat = (riceGrams * 0.3) / 100.0;

    // Cooked Meat/Protein density per 100g:
    // Beef: 250 kcal, 26g P, 0g C, 15g F
    // Pork: 240 kcal, 27g P, 0g C, 14g F
    // Chicken: 165 kcal, 31g P, 0g C, 3.6g F
    // Fish: 140 kcal, 24g P, 0g C, 4.5g F
    // Shrimp: 99 kcal, 24g P, 0.2g C, 0.3g F
    // Egg: 143 kcal, 12.6g P, 0.7g C, 9.5g F
    // Tofu: 83 kcal, 10g P, 1.9g C, 5.3g F
    double meatCalPer100 = 0;
    double meatProtPer100 = 0;
    double meatCarbPer100 = 0;
    double meatFatPer100 = 0;
    String meatLabelVi = '';
    String meatLabelEn = '';

    final typeLower = meatType.toLowerCase().trim();
    if (typeLower.contains('bò') || typeLower.contains('beef')) {
      meatCalPer100 = 250;
      meatProtPer100 = 26;
      meatCarbPer100 = 0;
      meatFatPer100 = 15;
      meatLabelVi = 'Thịt bò';
      meatLabelEn = 'Beef';
    } else if (typeLower.contains('lợn') || typeLower.contains('heo') || typeLower.contains('pork')) {
      meatCalPer100 = 240;
      meatProtPer100 = 27;
      meatCarbPer100 = 0;
      meatFatPer100 = 14;
      meatLabelVi = 'Thịt lợn';
      meatLabelEn = 'Pork';
    } else if (typeLower.contains('gà') || typeLower.contains('chicken')) {
      meatCalPer100 = 165;
      meatProtPer100 = 31;
      meatCarbPer100 = 0;
      meatFatPer100 = 3.6;
      meatLabelVi = 'Thịt gà';
      meatLabelEn = 'Chicken';
    } else if (typeLower.contains('cá') || typeLower.contains('fish')) {
      meatCalPer100 = 140;
      meatProtPer100 = 24;
      meatCarbPer100 = 0;
      meatFatPer100 = 4.5;
      meatLabelVi = 'Cá';
      meatLabelEn = 'Fish';
    } else if (typeLower.contains('tôm') || typeLower.contains('shrimp') || typeLower.contains('hải sản')) {
      meatCalPer100 = 99;
      meatProtPer100 = 24;
      meatCarbPer100 = 0.2;
      meatFatPer100 = 0.3;
      meatLabelVi = 'Tôm';
      meatLabelEn = 'Shrimp';
    } else if (typeLower.contains('trứng') || typeLower.contains('egg')) {
      meatCalPer100 = 143;
      meatProtPer100 = 12.6;
      meatCarbPer100 = 0.7;
      meatFatPer100 = 9.5;
      meatLabelVi = 'Trứng';
      meatLabelEn = 'Eggs';
    } else if (typeLower.contains('đậu') || typeLower.contains('tofu')) {
      meatCalPer100 = 83;
      meatProtPer100 = 10;
      meatCarbPer100 = 1.9;
      meatFatPer100 = 5.3;
      meatLabelVi = 'Đậu phụ';
      meatLabelEn = 'Tofu';
    } else if (typeLower.contains('không') || typeLower == 'none' || meatGrams <= 0) {
      meatCalPer100 = 0;
      meatProtPer100 = 0;
      meatCarbPer100 = 0;
      meatFatPer100 = 0;
    } else {
      // Default lean meat: ~180 kcal, 25g P, 0g C, 8g F
      meatCalPer100 = 180;
      meatProtPer100 = 25;
      meatCarbPer100 = 0;
      meatFatPer100 = 8;
      meatLabelVi = meatType;
      meatLabelEn = meatType;
    }

    final double meatCal = (meatGrams * meatCalPer100) / 100.0;
    final double meatCarbs = (meatGrams * meatCarbPer100) / 100.0;
    final double meatProtein = (meatGrams * meatProtPer100) / 100.0;
    final double meatFat = (meatGrams * meatFatPer100) / 100.0;

    // Cooked Vegetables: 30 kcal, 6g C, 2.5g P, 0.3g F per 100g
    final double vegCal = (vegGrams * 30.0) / 100.0;
    final double vegCarbs = (vegGrams * 6.0) / 100.0;
    final double vegProtein = (vegGrams * 2.5) / 100.0;
    final double vegFat = (vegGrams * 0.3) / 100.0;

    // Total macros
    final int totalCalories = (riceCal + meatCal + vegCal).round();
    final int totalCarbs = (riceCarbs + meatCarbs + vegCarbs).round();
    final int totalProtein = (riceProtein + meatProtein + vegProtein).round();
    final int totalFat = (riceFat + meatFat + vegFat).round();

    // Composite name
    final List<String> parts = [];
    if (riceGrams > 0) {
      parts.add(isVietnamese ? 'Cơm (${riceGrams}g)' : 'Rice (${riceGrams}g)');
    }
    if (meatGrams > 0 && meatLabelVi.isNotEmpty) {
      parts.add('${isVietnamese ? meatLabelVi : meatLabelEn} (${meatGrams}g)');
    }
    if (vegGrams > 0) {
      parts.add(isVietnamese ? 'Rau (${vegGrams}g)' : 'Vegetables (${vegGrams}g)');
    }

    String compositeName = parts.isEmpty
        ? (isVietnamese ? 'Bữa ăn dinh dưỡng' : 'Balanced Meal')
        : parts.join(' + ');

    if (notes != null && notes.trim().isNotEmpty) {
      compositeName += ' (${notes.trim()})';
    }

    return FoodInfo(
      name: compositeName,
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
    );
  }

  /// AI-Powered Portion Nutrition Calculation using Gemini 2.5 Flash
  /// with intelligent fallback to local clinical nutrition database.
  static Future<FoodInfo> analyzePortionedMeal({
    required int riceGrams,
    required String meatType,
    required int meatGrams,
    required int vegGrams,
    String? notes,
    bool isVietnamese = true,
  }) async {
    // 1. Calculate offline baseline for safety
    final offlineInfo = calculatePortionedMealOffline(
      riceGrams: riceGrams,
      meatType: meatType,
      meatGrams: meatGrams,
      vegGrams: vegGrams,
      notes: notes,
      isVietnamese: isVietnamese,
    );

    // If API key is not configured, immediately return accurate offline calculation
    if (!hasValidApiKey) {
      return offlineInfo;
    }

    try {
      final prompt = '''
You are a professional clinical dietitian and nutrition scientist.
A user inputs their exact meal portions in grams:
- Cooked rice / starch: $riceGrams grams
- Meat / Protein source ($meatType): $meatGrams grams
- Cooked vegetables / greens: $vegGrams grams
${notes != null && notes.trim().isNotEmpty ? '- Cooking method / notes: ${notes.trim()}' : ''}

Calculate the precise total calories, protein (g), carbohydrates (g), and fat (g) based on standard cooked food nutritional databases.
Language for meal name: ${isVietnamese ? 'Vietnamese' : 'English'}.
Example name: "Cơm (${riceGrams}g) + $meatType (${meatGrams}g) + Rau (${vegGrams}g)"

MANDATORY: Return ONLY one valid JSON object matching the schema below without any extra text or markdown code blocks:
{
  "name": "Composite meal name",
  "calories": (integer in kcal),
  "protein": (integer in grams),
  "carbs": (integer in grams),
  "fat": (integer in grams)
}
''';

      final response = await _generateWithFallback([Content.text(prompt)]).timeout(
        const Duration(seconds: 12),
      );

      final resText = response.text;
      if (resText != null) {
        final parsed = parseFoodJson(resText);
        if (parsed != null && parsed.calories > 0) {
          return parsed;
        }
      }
    } catch (e) {
      debugPrint("Gemini analyzePortionedMeal error: $e. Using offline clinical baseline.");
    }

    return offlineInfo;
  }

  static String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  /// AI Food Vision: Analyze food image bytes using Gemini 2.5 Flash multimodal
  static Future<FoodInfo?> analyzeFoodImage(Uint8List imageBytes) async {
    if (!hasValidApiKey) {
      debugPrint("⚠️ [GeminiService] Chưa cấu hình Gemini API Key cho AI Vision.");
      return null;
    }

    final mimeType = _detectMimeType(imageBytes);

    final prompt = '''
You are an expert AI nutritionist. Analyze this food image.
Identify the dish or food items present, estimate reasonable portion sizes, and calculate nutritional values.
If multiple food items are on the plate, combine them into one meal name and total the nutrients.

MANDATORY: Return ONLY a valid JSON object matching this exact schema:
{
  "name": "Food or meal name (in Vietnamese or English, e.g. Phở Bò, Cơm Tấm, hoặc Grilled Chicken Salad)",
  "calories": (realistic integer estimate in kcal),
  "protein": (realistic integer estimate in grams),
  "carbs": (realistic integer estimate in grams),
  "fat": (realistic integer estimate in grams)
}
''';

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];
      final response = await _generateWithFallback(content)
          .timeout(const Duration(seconds: 30));

      final resText = response.text;
      if (resText != null) {
        final parsed = parseFoodJson(resText);
        if (parsed != null && parsed.name != 'null' && parsed.name.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      debugPrint("Gemini Vision API Error: $e");
    }
    return null;
  }

  /// AI Nutritionist Advisor: Interactive chat with Gemini based on today's real-time nutrition stats and user biometric profile
  static Future<String> chatWithNutritionist({
    required String message,
    required Map<String, dynamic> todayStats,
    List<Map<String, String>>? history,
    UserProfile? userProfile,
  }) async {
    if (!hasValidApiKey) {
      return "Chưa cấu hình Gemini API Key. Vui lòng thiết lập biến môi trường GEMINI_API_KEY hoặc cấu hình trong file .env.";
    }

    final caloriesIn = todayStats['caloriesIn'] ?? 0;
    final caloriesBurned = todayStats['caloriesBurned'] ?? 0;
    final protein = todayStats['protein'] ?? 0;
    final carbs = todayStats['carbs'] ?? 0;
    final fat = todayStats['fat'] ?? 0;
    final waterMl = todayStats['waterMl'] ?? 0;
    final currentGoal = todayStats['goal'] ?? 'Balanced';
    final foodsSummary = todayStats['foodsSummary'] ?? 'Chưa ghi nhận món nào';

    final userBioContext = userProfile != null
        ? '''
Hồ sơ sinh trắc học người dùng:
- Họ tên: ${userProfile.name}
- Giới tính: ${userProfile.gender == 'female' ? 'Nữ' : 'Nam'}, Tuổi: ${userProfile.age}
- Chiều cao: ${userProfile.height} cm, Cân nặng: ${userProfile.weight} kg, BMI: ${userProfile.bmi.toStringAsFixed(1)} (${userProfile.bmiCategory})
- Cân nặng mục tiêu: ${userProfile.targetWeight} kg
- Mục tiêu thể hình/dinh dưỡng: ${userProfile.goalDisplayName} (${userProfile.fitnessGoal})
- Tỷ lệ trao đổi chất cơ bản (BMR): ${userProfile.bmr.round()} kcal/ngày
- Tổng năng lượng tiêu hao ước tính (TDEE): ${userProfile.tdee.round()} kcal/ngày
- Mục tiêu calo khoa học: ${userProfile.targetCalories} kcal (Protein: ${userProfile.targetMacros['protein']}g, Carbs: ${userProfile.targetMacros['carbs']}g, Fat: ${userProfile.targetMacros['fat']}g)
'''
        : '';

    final systemInstruction = '''
Bạn là Gemini Nutritionist - Chuyên gia dinh dưỡng và huấn luyện viên sức khỏe thông minh hàng đầu.
$userBioContext
Bối cảnh dinh dưỡng thực tế hôm nay:
- Tổng Calo nạp: $caloriesIn kcal
- Tổng Calo tiêu hao: $caloriesBurned kcal
- Macro nạp: $protein g Protein, $carbs g Carbs, $fat g Fat
- Lượng nước đã uống: $waterMl ml
- Mục tiêu dinh dưỡng: $currentGoal
- Các món đã ăn hôm nay: $foodsSummary

Phong cách trả lời:
- Nhiệt tình, truyền cảm hứng, chuyên nghiệp và súc tích (khoảng 2-4 đoạn hoặc gạch đầu dòng rõ ràng).
- Liên kết chặt chẽ số liệu hôm nay với mục tiêu sinh trắc học cá nhân của người dùng (ví dụ: đang muốn siết mỡ hay tăng cơ, thiếu protein so với mục tiêu ${userProfile?.targetMacros['protein'] ?? 150}g, calo thâm hụt hay dư thừa so với TDEE).
- Sử dụng tiếng Việt thân thiện, dễ hiểu, có emoji sinh động.
''';

    try {
      final List<Content> chatHistory = [];
      if (history != null) {
        for (final msg in history) {
          if (msg['role'] == 'user') {
            chatHistory.add(Content.text(msg['text'] ?? ''));
          } else if (msg['role'] == 'model') {
            chatHistory.add(Content.model([TextPart(msg['text'] ?? '')]));
          }
        }
      }

      chatHistory.add(Content.text(message));

      final response = await _generateWithFallback(
        chatHistory,
        systemInstruction: Content.system(systemInstruction),
      );
      return response.text ?? "Xin lỗi, tôi chưa thể đưa ra câu trả lời lúc này. Bạn thử lại nhé!";
    } catch (e) {
      debugPrint("Nutritionist Chat Error: $e");
      return "Rất tiếc, đã có lỗi kết nối với Gemini AI ($e). Vui lòng thử lại sau!";
    }
  }

  /// AI Personal Coach: Generates an instant personalized workout plan
  static Future<CustomWorkoutRoutine> generateCustomWorkout({
    required int durationMinutes,
    required String goal,
    required String equipment,
    UserProfile? userProfile,
  }) async {
    final userBioContext = userProfile != null
        ? '''
User Biometric Profile:
- Name: ${userProfile.name}
- Gender: ${userProfile.gender}
- Age: ${userProfile.age}
- Height: ${userProfile.height} cm, Weight: ${userProfile.weight} kg, BMI: ${userProfile.bmi} (${userProfile.bmiCategory})
- Target Weight: ${userProfile.targetWeight} kg
- Primary Fitness Goal: ${userProfile.fitnessGoal}
- Basal Metabolic Rate (BMR): ${userProfile.bmr.round()} kcal, TDEE: ${userProfile.tdee.round()} kcal
Customize intensity, difficulty, and form coaching to be safe and maximally effective for this specific person's body type and goals.
'''
        : '';

    final String equipmentInstruction;
    final lowerEq = equipment.toLowerCase();
    if (lowerEq.contains('dumbbell') || lowerEq.contains('tạ')) {
      equipmentInstruction = 'Dumbbells only. Emphasize home dumbbell exercises such as Dumbbell Floor Press, Overhead Shoulder Press, Bent-over Row, Goblet Squat, Dumbbell Bicep Curls, Lateral Raises, and Romanian Deadlifts.';
    } else if (lowerEq.contains('hybrid') || lowerEq.contains('kết hợp')) {
      equipmentInstruction = 'Hybrid combination of Dumbbells and Bodyweight movements (combine Push-ups, Squats, Planks with Dumbbell Press, Rows, and Deadlifts).';
    } else {
      equipmentInstruction = 'Bodyweight only without any weights (e.g. Push-ups, Pull-ups, Squats, Planks, Burpees, Lunges).';
    }

    final prompt = '''
You are a top-tier personal fitness trainer. Create a custom, highly effective $durationMinutes-minute home workout routine.
Target Goal: $goal
Equipment Available: $equipment ($equipmentInstruction)
$userBioContext

MANDATORY REQUIREMENT: Return ONLY a valid JSON object matching the exact structure below, without any markdown formatting or extra commentary:
{
  "title": "Inspiring routine title in English",
  "durationMinutes": $durationMinutes,
  "targetGoal": "$goal",
  "estimatedCalories": (realistic integer between 70 and 450 depending on duration),
  "exercises": [
    {
      "name": "Exercise Name (e.g., Dumbbell Floor Press, Push-ups, Goblet Squat)",
      "sets": (integer 2 to 4),
      "repsOrDuration": "e.g., 12 reps or 45s",
      "formNote": "Concise key form tip for safety and effectiveness"
    }
  ]
}
''';

    if (hasValidApiKey) {
      try {
        final response = await _generateWithFallback([Content.text(prompt)]);
        final raw = response.text;
        if (raw != null) {
          String cleanText = raw
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final startIdx = cleanText.indexOf('{');
          final endIdx = cleanText.lastIndexOf('}');
          if (startIdx != -1 && endIdx != -1 && endIdx >= startIdx) {
            cleanText = cleanText.substring(startIdx, endIdx + 1);
            final map = jsonDecode(cleanText);
            if (map is Map<String, dynamic>) {
              return CustomWorkoutRoutine.fromJson(map);
            }
          }
        }
      } catch (e) {
        debugPrint("Gemini AI Workout Gen Exception: $e. Falling back to built-in generator.");
      }
    }

    return _getFallbackRoutine(durationMinutes, goal, equipment);
  }

  /// Built-in intelligent fallback routine generator (100% reliable offline)
  static CustomWorkoutRoutine _getFallbackRoutine(int durationMinutes, String goal, [String equipment = 'bodyweight']) {
    final lowerGoal = goal.toLowerCase();
    final lowerEq = equipment.toLowerCase();
    final isDumbbell = lowerEq.contains('dumbbell') || lowerEq.contains('tạ');
    final isHybrid = lowerEq.contains('hybrid') || lowerEq.contains('kết hợp');

    // 1. Dumbbell routine
    if (isDumbbell) {
      return CustomWorkoutRoutine(
        title: 'Dumbbell Hypertrophy & Power',
        durationMinutes: durationMinutes,
        targetGoal: goal,
        estimatedCalories: durationMinutes * 8,
        exercises: const [
          WorkoutExerciseItem(
            name: 'Đẩy ngực tạ đơn',
            sets: 3,
            repsOrDuration: '10-12 reps',
            formNote: 'Keep shoulder blades retracted and drive dumbbells smoothly upward.',
          ),
          WorkoutExerciseItem(
            name: 'Kéo tạ lưng xô',
            sets: 3,
            repsOrDuration: '12 reps',
            formNote: 'Hinge forward at 45 degrees, pull dumbbells toward hip pockets.',
          ),
          WorkoutExerciseItem(
            name: 'Squat ôm tạ Goblet',
            sets: 3,
            repsOrDuration: '12 reps',
            formNote: 'Hold dumbbell vertically against chest, squat deep through heels.',
          ),
          WorkoutExerciseItem(
            name: 'Đẩy vai qua đầu',
            sets: 3,
            repsOrDuration: '10 reps',
            formNote: 'Press vertically overhead without hyperextending lower back.',
          ),
        ],
      );
    }

    // 2. Hybrid routine
    if (isHybrid) {
      return CustomWorkoutRoutine(
        title: 'Hybrid Functional Strength & Cardio',
        durationMinutes: durationMinutes,
        targetGoal: goal,
        estimatedCalories: durationMinutes * 9,
        exercises: const [
          WorkoutExerciseItem(
            name: 'Đẩy ngực tạ đơn',
            sets: 3,
            repsOrDuration: '10 reps',
            formNote: 'Focus on chest contraction at top of each press.',
          ),
          WorkoutExerciseItem(
            name: 'Hít đất',
            sets: 3,
            repsOrDuration: '12 reps',
            formNote: 'Explosive push up, control 2 seconds down.',
          ),
          WorkoutExerciseItem(
            name: 'Squat ôm tạ Goblet',
            sets: 3,
            repsOrDuration: '12 reps',
            formNote: 'Brace core tightly and sink hips back.',
          ),
          WorkoutExerciseItem(
            name: 'Plank siết cơ bụng',
            sets: 3,
            repsOrDuration: '45s hold',
            formNote: 'Maintain completely straight line from shoulders to ankles.',
          ),
        ],
      );
    }

    // 3. Upper body focus
    if (lowerGoal.contains('upper') || lowerGoal.contains('ngực') || lowerGoal.contains('tay') || lowerGoal.contains('vai')) {
      return CustomWorkoutRoutine(
        title: 'Upper Body Armor & Pump',
        durationMinutes: durationMinutes,
        targetGoal: 'Upper Body Strength',
        estimatedCalories: durationMinutes * 8,
        exercises: const [
          WorkoutExerciseItem(
            name: 'Hít đất',
            sets: 3,
            repsOrDuration: '15 reps',
            formNote: 'Keep elbows at 45 degrees, full lockout at top.',
          ),
          WorkoutExerciseItem(
            name: 'Hít đất kim cương',
            sets: 3,
            repsOrDuration: '10 reps',
            formNote: 'Index fingers and thumbs forming a diamond to isolate triceps.',
          ),
          WorkoutExerciseItem(
            name: 'Hít xà đơn',
            sets: 3,
            repsOrDuration: '8 reps',
            formNote: 'Lead with chest, pull chin fully over bar with control.',
          ),
          WorkoutExerciseItem(
            name: 'Plank siết cơ bụng',
            sets: 3,
            repsOrDuration: '45s hold',
            formNote: 'Solid core brace throughout.',
          ),
        ],
      );
    }

    // 4. Lower body focus
    if (lowerGoal.contains('lower') || lowerGoal.contains('chân') || lowerGoal.contains('mông') || lowerGoal.contains('glute')) {
      return CustomWorkoutRoutine(
        title: 'Lower Body Glute & Leg Sculpt',
        durationMinutes: durationMinutes,
        targetGoal: 'Glutes & Legs Sculpting',
        estimatedCalories: durationMinutes * 8,
        exercises: const [
          WorkoutExerciseItem(
            name: 'Squat tự do',
            sets: 3,
            repsOrDuration: '20 reps',
            formNote: 'Deep squat below parallel, push knees outward.',
          ),
          WorkoutExerciseItem(
            name: 'Chùng chân Lunges',
            sets: 3,
            repsOrDuration: '16 reps (8 each leg)',
            formNote: 'Step forward keeping front shin perpendicular to floor.',
          ),
          WorkoutExerciseItem(
            name: 'Cầu mông Glute Bridge',
            sets: 3,
            repsOrDuration: '15 slow reps',
            formNote: '2-second squeeze at the peak of hip bridge.',
          ),
          WorkoutExerciseItem(
            name: 'Nhảy Burpees đốt mỡ',
            sets: 3,
            repsOrDuration: '10 reps',
            formNote: 'Explosive jump at end of each repetition.',
          ),
        ],
      );
    }

    // 5. Abs / Core focus
    if (lowerGoal.contains('abs') || lowerGoal.contains('core') || lowerGoal.contains('bụng')) {
      return CustomWorkoutRoutine(
        title: 'Core Blast & Six-Pack Shred',
        durationMinutes: durationMinutes,
        targetGoal: 'Core & Abs Sculpting',
        estimatedCalories: durationMinutes * 7,
        exercises: const [
          WorkoutExerciseItem(
            name: 'Plank siết cơ bụng',
            sets: 3,
            repsOrDuration: '45s hold',
            formNote: 'Keep spine straight and squeeze glutes firmly.',
          ),
          WorkoutExerciseItem(
            name: 'Gập bụng Crunch',
            sets: 3,
            repsOrDuration: '20 reps',
            formNote: 'Curl shoulders off floor while exhaling forcefully.',
          ),
          WorkoutExerciseItem(
            name: 'Leo núi Mountain Climbers',
            sets: 3,
            repsOrDuration: '30s sprint',
            formNote: 'Sprint knees toward chest while maintaining low hips.',
          ),
          WorkoutExerciseItem(
            name: 'Bicycle Crunches',
            sets: 3,
            repsOrDuration: '20 reps',
            formNote: 'Touch elbow to opposite knee without pulling on neck.',
          ),
        ],
      );
    } else if (lowerGoal.contains('flex') || lowerGoal.contains('stretch') || lowerGoal.contains('lưng')) {
      return CustomWorkoutRoutine(
        title: 'Mobility & Spine Relief Flow',
        durationMinutes: durationMinutes,
        targetGoal: 'Flexibility & Lower Back Relief',
        estimatedCalories: durationMinutes * 5,
        exercises: const [
          WorkoutExerciseItem(
            name: 'Yoga Flexibility Stretch',
            sets: 3,
            repsOrDuration: '60s deep hold',
            formNote: 'Breathe diaphragmatically and lengthen through each vertebra.',
          ),
          WorkoutExerciseItem(
            name: 'Glute Bridges',
            sets: 3,
            repsOrDuration: '15 slow reps',
            formNote: 'Squeeze glutes at the apex for 2 seconds to decompress spine.',
          ),
          WorkoutExerciseItem(
            name: 'Donkey Kicks',
            sets: 3,
            repsOrDuration: '12 reps each leg',
            formNote: 'Drive heel upward without arching the lumbar spine.',
          ),
          WorkoutExerciseItem(
            name: 'Plank siết cơ bụng',
            sets: 3,
            repsOrDuration: '40s hold',
            formNote: 'Maintain neutral neck and engaged transverse abdominal wall.',
          ),
        ],
      );
    } else {
      // Default: Full Body Burn
      return CustomWorkoutRoutine(
        title: 'Full Body Inferno Cardio',
        durationMinutes: durationMinutes,
        targetGoal: 'Full Body Fat Burn & Cardio',
        estimatedCalories: durationMinutes * 9,
        exercises: const [
          WorkoutExerciseItem(
            name: 'Nhảy Burpees đốt mỡ',
            sets: 3,
            repsOrDuration: '10 reps',
            formNote: 'Explode up with hands clapping overhead after each push-up.',
          ),
          WorkoutExerciseItem(
            name: 'Hít đất',
            sets: 3,
            repsOrDuration: '12-15 reps',
            formNote: 'Chest 3cm from floor, elbows at 45-degree angle.',
          ),
          WorkoutExerciseItem(
            name: 'Squat tự do',
            sets: 3,
            repsOrDuration: '20 deep reps',
            formNote: 'Thighs parallel to ground, drive through heels on ascent.',
          ),
          WorkoutExerciseItem(
            name: 'Chùng chân Lunges',
            sets: 3,
            repsOrDuration: '16 reps (8 each leg)',
            formNote: 'Land softly on balls of feet with knees tracking straight.',
          ),
        ],
      );
    }
  }

  /// Tạo bản tin huấn luyện viên AI hàng ngày (Daily AI Health Briefing)
  static Future<DailyAiBriefing> generateDailyBriefing({
    required String dateStr,
    required String yesterdayDateStr,
    required UserProfile profile,
    required int steps,
    required int caloriesIn,
    required int caloriesBurned,
    required int waterCups,
    required int healthScore,
    required int streakDays,
    bool isVietnamese = true,
  }) async {
    final calorieBalance = caloriesIn - caloriesBurned;

    if (hasValidApiKey) {
      try {
        final balanceText = calorieBalance < 0
            ? "thâm hụt ${calorieBalance.abs()} kcal"
            : (calorieBalance > 0
                ? "dư thừa $calorieBalance kcal"
                : "cân bằng năng lượng hoàn hảo");

        final prompt = '''
Bạn là Huấn Luyện Viên Cá Nhân (AI Personal Trainer / PT) chuyên nghiệp, nhiệt huyết và tận tâm của ứng dụng Fitness Tracker.
Nhiệm vụ của bạn là phân tích dữ liệu ngày hôm qua ($yesterdayDateStr) và đưa ra bản tin sức khỏe ngắn gọn, truyền cảm hứng cho ngày hôm nay ($dateStr).

Thông tin học viên:
- Tên: ${profile.name}
- Mục tiêu: ${profile.fitnessGoal}
- Chuỗi rèn luyện (Streak): $streakDays ngày liên tục

Dữ liệu ngày hôm qua:
- Số bước đi: $steps bước
- Calo nạp vào: $caloriesIn kcal
- Calo tiêu hao: $caloriesBurned kcal
- Cân bằng năng lượng: $balanceText
- Lượng nước uống: $waterCups/8 cốc
- Điểm sức khỏe tổng thể: $healthScore/100

YÊU CẦU QUAN TRỌNG:
1. Giọng điệu huấn luyện viên: Tràn đầy năng lượng, đồng hành, chân thành, khen ngợi thành tích cụ thể và động viên cải thiện điểm yếu.
2. Tin nhắn (message): Bắt buộc đề cập các con số cụ thể ngày hôm qua (như calo thâm hụt/dư thừa, số bước, số cốc nước hoặc điểm sức khỏe). Đưa ra lời khuyên hành động hôm nay. Tối đa 2-3 câu ngắn gọn.
Ví dụ phong cách: "Hôm qua bạn thâm hụt 867 kcal rất tốt, nhưng mới đạt 4/8 cốc nước. Hôm nay hãy bù nước và cố gắng đạt 8.000 bước nhé!"
3. Tiêu đề (headline): Dưới 6 từ, tràn đầy nhiệt huyết kèm emoji.
4. Mẹo hành động (actionableTip): 1 lời khuyên hoặc thử thách nhỏ làm được ngay hôm nay kèm emoji.
5. Chỉ trả về DUY NHẤT một chuỗi JSON hợp lệ không kèm văn bản giải thích hay markdown code block:
{
  "headline": "Tiêu đề ngắn",
  "message": "Lời nhắn huấn luyện viên phân tích ngày hôm qua...",
  "actionableTip": "Mẹo hành động hôm nay",
  "coachTone": "motivating"
}
Ngôn ngữ: ${isVietnamese ? 'Tiếng Việt' : 'English'}
''';

        final response = await _generateWithFallback([Content.text(prompt)]);
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          String cleanText = text
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final startIndex = cleanText.indexOf('{');
          final endIndex = cleanText.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
            cleanText = cleanText.substring(startIndex, endIndex + 1);
            final map = jsonDecode(cleanText) as Map<String, dynamic>;
            final headline = map['headline']?.toString() ??
                (isVietnamese ? 'Chào ngày mới!' : 'Good Morning!');
            final message = map['message']?.toString() ?? '';
            final actionableTip = map['actionableTip']?.toString() ?? '';
            final coachTone = map['coachTone']?.toString() ?? 'motivating';

            if (message.isNotEmpty) {
              return DailyAiBriefing(
                dateStr: dateStr,
                yesterdayDateStr: yesterdayDateStr,
                headline: headline,
                message: message,
                actionableTip: actionableTip,
                coachTone: coachTone,
                steps: steps,
                caloriesIn: caloriesIn,
                caloriesBurned: caloriesBurned,
                calorieBalance: calorieBalance,
                waterCups: waterCups,
                healthScore: healthScore,
                streakDays: streakDays,
                generatedAt: DateTime.now(),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Gemini daily briefing error, fallback to offline engine: $e");
      }
    }

    return _generateOfflineDailyBriefing(
      dateStr: dateStr,
      yesterdayDateStr: yesterdayDateStr,
      profile: profile,
      steps: steps,
      caloriesIn: caloriesIn,
      caloriesBurned: caloriesBurned,
      waterCups: waterCups,
      healthScore: healthScore,
      streakDays: streakDays,
      isVietnamese: isVietnamese,
    );
  }

  static DailyAiBriefing _generateOfflineDailyBriefing({
    required String dateStr,
    required String yesterdayDateStr,
    required UserProfile profile,
    required int steps,
    required int caloriesIn,
    required int caloriesBurned,
    required int waterCups,
    required int healthScore,
    required int streakDays,
    bool isVietnamese = true,
  }) {
    final calorieBalance = caloriesIn - caloriesBurned;
    final absBalance = calorieBalance.abs();

    String headline;
    String message;
    String tip;
    String coachTone = 'motivating';

    if (isVietnamese) {
      if (healthScore >= 80) {
        headline = 'Phong độ đỉnh cao! 🔥';
        coachTone = 'celebratory';
      } else if (streakDays >= 3) {
        headline = 'Chiến binh kiên trì! ⚡';
        coachTone = 'motivating';
      } else {
        headline = 'Khởi đầu ngày mới! 💪';
        coachTone = 'refocus';
      }

      final parts = <String>[];
      if (caloriesIn > 0) {
        if (calorieBalance < -200) {
          parts.add('Hôm qua bạn thâm hụt $absBalance kcal rất tốt');
        } else if (calorieBalance > 200) {
          parts.add('Hôm qua bạn nạp dư $absBalance kcal hỗ trợ năng lượng');
        } else {
          parts.add('Hôm qua năng lượng nạp và tiêu hao cân bằng rất tốt');
        }
      } else if (steps > 0 || caloriesBurned > 1500) {
        parts.add('Hôm qua bạn tiêu hao $caloriesBurned kcal với $steps bước');
      } else {
        parts.add('Hôm qua là một ngày nhẹ nhàng');
      }

      if (waterCups < 5) {
        parts.add('nhưng mới đạt $waterCups/8 cốc nước');
        message = '${parts.join(', ')}. Hôm nay hãy bù nước và cố gắng đạt 8.000 bước nhé!';
      } else {
        parts.add('và duy trì uống đủ $waterCups/8 cốc nước rất tuyệt');
        message = '${parts.join(', ')}. Hôm nay tiếp tục giữ vững chuỗi $streakDays ngày phong độ nhé!';
      }

      if (waterCups < 6) {
        tip = '💧 Uống ngay 1 ly nước ấm để đánh thức trao đổi chất';
      } else if (steps < 8000) {
        tip = '👟 Đặt mục tiêu đi dạo 15 phút để hoàn thành 8.000 bước';
      } else {
        tip = '🔥 Duy trì thói quen tập luyện 20 phút cùng AI Coach';
      }
    } else {
      if (healthScore >= 80) {
        headline = 'Peak Performance! 🔥';
        coachTone = 'celebratory';
      } else if (streakDays >= 3) {
        headline = 'Consistent Warrior! ⚡';
        coachTone = 'motivating';
      } else {
        headline = 'Ready to Crush Today! 💪';
        coachTone = 'refocus';
      }

      final parts = <String>[];
      if (caloriesIn > 0) {
        if (calorieBalance < -200) {
          parts.add('Yesterday you maintained a great $absBalance kcal deficit');
        } else if (calorieBalance > 200) {
          parts.add('Yesterday you had a $absBalance kcal surplus');
        } else {
          parts.add('Yesterday intake and expenditure were well balanced');
        }
      } else {
        parts.add('Yesterday you burned $caloriesBurned kcal with $steps steps');
      }

      if (waterCups < 5) {
        parts.add('but only reached $waterCups/8 water cups');
        message = '${parts.join(', ')}. Rehydrate well today and aim for 8,000 steps!';
      } else {
        parts.add('with great hydration ($waterCups/8 cups)');
        message = '${parts.join(', ')}. Keep up this awesome momentum today!';
      }

      tip = waterCups < 6
          ? '💧 Drink a fresh glass of water to kickstart your metabolism'
          : '👟 Take a 15-minute brisk walk today to hit your step goal';
    }

    return DailyAiBriefing(
      dateStr: dateStr,
      yesterdayDateStr: yesterdayDateStr,
      headline: headline,
      message: message,
      actionableTip: tip,
      coachTone: coachTone,
      steps: steps,
      caloriesIn: caloriesIn,
      caloriesBurned: caloriesBurned,
      calorieBalance: calorieBalance,
      waterCups: waterCups,
      healthScore: healthScore,
      streakDays: streakDays,
      generatedAt: DateTime.now(),
    );
  }
}

class WorkoutExerciseItem {
  final String name;
  final int sets;
  final String repsOrDuration;
  final String formNote;

  String get formTip => formNote;
  String get reps => repsOrDuration;

  const WorkoutExerciseItem({
    required this.name,
    required this.sets,
    required this.repsOrDuration,
    required this.formNote,
  });

  factory WorkoutExerciseItem.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseItem(
      name: json['name']?.toString() ?? 'Bodyweight Exercise',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      repsOrDuration: json['repsOrDuration']?.toString() ?? '12 reps',
      formNote: json['formNote']?.toString() ?? 'Maintain strict form and steady breathing.',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'repsOrDuration': repsOrDuration,
        'formNote': formNote,
      };
}

class CustomWorkoutRoutine {
  final String title;
  final int durationMinutes;
  final String targetGoal;
  final int estimatedCalories;
  final String coachAdvice;
  final List<WorkoutExerciseItem> exercises;

  const CustomWorkoutRoutine({
    required this.title,
    required this.durationMinutes,
    required this.targetGoal,
    required this.estimatedCalories,
    this.coachAdvice = 'Focus on controlled breathing, full range of motion, and stay hydrated!',
    required this.exercises,
  });

  factory CustomWorkoutRoutine.fromJson(Map<String, dynamic> json) {
    var list = json['exercises'] as List<dynamic>? ?? [];
    List<WorkoutExerciseItem> items = list
        .map((e) => WorkoutExerciseItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return CustomWorkoutRoutine(
      title: json['title']?.toString() ?? 'Custom AI Workout',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 20,
      targetGoal: json['targetGoal']?.toString() ?? 'Full Body Conditioning',
      estimatedCalories: (json['estimatedCalories'] as num?)?.toInt() ?? 150,
      coachAdvice: json['coachAdvice']?.toString() ??
          'Focus on controlled breathing, full range of motion, and stay hydrated!',
      exercises: items,
    );
  }
}

class DailyAiBriefing {
  final String dateStr;
  final String yesterdayDateStr;
  final String headline;
  final String message;
  final String actionableTip;
  final String coachTone;
  final int steps;
  final int caloriesIn;
  final int caloriesBurned;
  final int calorieBalance;
  final int waterCups;
  final int healthScore;
  final int streakDays;
  final DateTime generatedAt;

  const DailyAiBriefing({
    required this.dateStr,
    required this.yesterdayDateStr,
    required this.headline,
    required this.message,
    required this.actionableTip,
    this.coachTone = 'motivating',
    required this.steps,
    required this.caloriesIn,
    required this.caloriesBurned,
    required this.calorieBalance,
    required this.waterCups,
    required this.healthScore,
    required this.streakDays,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'dateStr': dateStr,
        'yesterdayDateStr': yesterdayDateStr,
        'headline': headline,
        'message': message,
        'actionableTip': actionableTip,
        'coachTone': coachTone,
        'steps': steps,
        'caloriesIn': caloriesIn,
        'caloriesBurned': caloriesBurned,
        'calorieBalance': calorieBalance,
        'waterCups': waterCups,
        'healthScore': healthScore,
        'streakDays': streakDays,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DailyAiBriefing.fromJson(Map<String, dynamic> json) {
    return DailyAiBriefing(
      dateStr: json['dateStr']?.toString() ?? '',
      yesterdayDateStr: json['yesterdayDateStr']?.toString() ?? '',
      headline: json['headline']?.toString() ?? 'Chào ngày mới!',
      message: json['message']?.toString() ?? '',
      actionableTip: json['actionableTip']?.toString() ?? '',
      coachTone: json['coachTone']?.toString() ?? 'motivating',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      caloriesIn: (json['caloriesIn'] as num?)?.toInt() ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
      calorieBalance: (json['calorieBalance'] as num?)?.toInt() ?? 0,
      waterCups: (json['waterCups'] as num?)?.toInt() ?? 0,
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 1,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
