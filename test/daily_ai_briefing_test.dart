import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/gemini_service.dart';
import 'package:fitness_tracker/services/storage_service.dart';
import 'package:fitness_tracker/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.invalidateMemoryCaches();
  });

  group('DailyAiBriefing Model & Offline PT Engine Tests', () {
    test('DailyAiBriefing serialization and deserialization works correctly', () {
      final now = DateTime.now();
      final briefing = DailyAiBriefing(
        dateStr: '2026-09-24',
        yesterdayDateStr: '2026-09-23',
        headline: 'Chiến binh kiên trì! ⚡',
        message: 'Hôm qua bạn thâm hụt 867 kcal rất tốt, nhưng mới đạt 4/8 cốc nước. Hôm nay hãy bù nước và cố gắng đạt 8.000 bước nhé!',
        actionableTip: '💧 Uống ngay 1 ly nước ấm để đánh thức trao đổi chất',
        coachTone: 'motivating',
        steps: 8420,
        caloriesIn: 1800,
        caloriesBurned: 2667,
        calorieBalance: -867,
        waterCups: 4,
        healthScore: 88,
        streakDays: 2,
        generatedAt: now,
      );

      final json = briefing.toJson();
      expect(json['dateStr'], '2026-09-24');
      expect(json['yesterdayDateStr'], '2026-09-23');
      expect(json['calorieBalance'], -867);
      expect(json['waterCups'], 4);
      expect(json['steps'], 8420);

      final restored = DailyAiBriefing.fromJson(json);
      expect(restored.headline, briefing.headline);
      expect(restored.message, briefing.message);
      expect(restored.actionableTip, briefing.actionableTip);
      expect(restored.calorieBalance, -867);
      expect(restored.waterCups, 4);
      expect(restored.steps, 8420);
      expect(restored.healthScore, 88);
      expect(restored.streakDays, 2);
    });

    test('Offline PT Engine generates motivating advice mentioning calorie deficit and water', () async {
      final profile = const UserProfile(
        name: 'Đạt',
        age: 25,
        gender: 'male',
        weight: 70,
        height: 175,
        targetWeight: 68,
        activityLevel: 1.55,
        fitnessGoal: 'cutting',
      );

      // Deficit of 867 kcal, 4 water cups
      final briefing = await GeminiService.generateDailyBriefing(
        dateStr: '2026-09-24',
        yesterdayDateStr: '2026-09-23',
        profile: profile,
        steps: 7500,
        caloriesIn: 1600,
        caloriesBurned: 2467,
        waterCups: 4,
        healthScore: 82,
        streakDays: 2,
        isVietnamese: true,
      );

      expect(briefing.calorieBalance, -867);
      expect(briefing.waterCups, 4);
      expect(briefing.message, contains('thâm hụt 867 kcal'));
      expect(briefing.message, contains('4/8 cốc nước'));
      expect(briefing.actionableTip, isNotEmpty);
    });

    test('StorageService caches and retrieves DailyAiBriefing without recomputing', () async {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      final initial = await StorageService.getOrGenerateDailyAiBriefing(forDate: today);
      expect(initial.dateStr, todayStr);

      final cached = await StorageService.getCachedDailyAiBriefing(todayStr);
      expect(cached, isNotNull);
      expect(cached!.dateStr, todayStr);
      expect(cached.headline, initial.headline);
      expect(cached.message, initial.message);

      // Calling again returns cached instance
      final second = await StorageService.getOrGenerateDailyAiBriefing(forDate: today);
      expect(second.headline, initial.headline);
    });
  });
}
