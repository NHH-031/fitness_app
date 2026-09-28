import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fitness_tracker/widgets/health_score_widget.dart';
import 'package:fitness_tracker/services/locale_service.dart';

void main() {
  group('HealthScoreCalculator Algorithm & 4-Pillar Tests', () {
    setUp(() {
      LocaleService.languageNotifier.value = 'en';
    });

    test('Peak performance evaluation when all 4 pillars are fully met', () {
      final breakdown = HealthScoreCalculator.evaluate(
        currentSteps: 10000,
        goalSteps: 10000,
        caloriesIn: 2000,
        targetCalories: 2000,
        proteinGrams: 120,
        targetProtein: 120,
        workoutMinutes: 45,
        workoutCount: 1,
        waterCups: 8,
        streakDays: 3,
      );

      // Steps: 20, Workout: 35, Nutrition: 35 (28 base + 7 protein), Habits: 10 (7 water + 3 streak)
      expect(breakdown.stepScore, 20);
      expect(breakdown.workoutScore, 35);
      expect(breakdown.nutritionScore, 35);
      expect(breakdown.habitScore, 10);
      expect(breakdown.totalScore, 100);

      expect(breakdown.statusKey, 'score_peak');
      expect(breakdown.statusText, 'PEAK 🔥');
      expect(breakdown.statusColor, const Color(0xFF00FFA3));
      expect(breakdown.adviceIcon, Icons.local_fire_department);
    });

    test('Zero activities at start of day results in low score with workout reminder', () {
      final breakdown = HealthScoreCalculator.evaluate(
        currentSteps: 0,
        goalSteps: 10000,
        caloriesIn: 0,
        targetCalories: 2000,
        workoutMinutes: 0,
        workoutCount: 0,
        waterCups: 0,
        streakDays: 0,
      );

      expect(breakdown.totalScore, 0);
      expect(breakdown.statusKey, 'score_needs_work');
      expect(breakdown.statusText, 'NEEDS WORK ⚠️');
      expect(breakdown.statusColor, const Color(0xFFFF4B4B));
      // Primary advice: workout reminder when workout is 0
      expect(breakdown.adviceIcon, Icons.fitness_center);
    });

    test('5-Tier status classification works correctly across score boundaries', () {
      expect(HealthScoreCalculator.getScoreStatusKey(95), 'score_peak');
      expect(HealthScoreCalculator.getScoreStatusKey(90), 'score_peak');
      expect(HealthScoreCalculator.getScoreStatusKey(85), 'score_great');
      expect(HealthScoreCalculator.getScoreStatusKey(75), 'score_great');
      expect(HealthScoreCalculator.getScoreStatusKey(70), 'score_on_track');
      expect(HealthScoreCalculator.getScoreStatusKey(60), 'score_on_track');
      expect(HealthScoreCalculator.getScoreStatusKey(50), 'score_keep_going');
      expect(HealthScoreCalculator.getScoreStatusKey(40), 'score_keep_going');
      expect(HealthScoreCalculator.getScoreStatusKey(35), 'score_needs_work');
      expect(HealthScoreCalculator.getScoreStatusKey(0), 'score_needs_work');
    });

    test('Vietnamese localized 5-tier status text works accurately', () {
      LocaleService.languageNotifier.value = 'vi';

      expect(HealthScoreCalculator.getScoreStatus(95), 'ĐỈNH CAO 🔥');
      expect(HealthScoreCalculator.getScoreStatus(80), 'RẤT TỐT 💪');
      expect(HealthScoreCalculator.getScoreStatus(65), 'TIẾN BỘ 👍');
      expect(HealthScoreCalculator.getScoreStatus(45), 'CẦN CỐ GẮNG ⚡');
      expect(HealthScoreCalculator.getScoreStatus(25), 'CẦN CẢI THIỆN ⚠️');
    });

    test('Dynamic advice reminds user when calorie intake is very low', () {
      LocaleService.languageNotifier.value = 'vi';
      final breakdown = HealthScoreCalculator.evaluate(
        currentSteps: 5000,
        goalSteps: 10000,
        caloriesIn: 150, // very low
        targetCalories: 2000,
        workoutMinutes: 20, // user did workout
        workoutCount: 1,
        waterCups: 4,
        streakDays: 1,
      );

      // Since workout is > 0, system flags low nutrition
      expect(breakdown.adviceIcon, Icons.restaurant);
      expect(breakdown.adviceText.contains('Năng lượng nạp vào còn thấp'), isTrue);
    });

    test('Dynamic advice warns user when calorie surplus is high', () {
      LocaleService.languageNotifier.value = 'vi';
      final breakdown = HealthScoreCalculator.evaluate(
        currentSteps: 4000,
        goalSteps: 10000,
        caloriesIn: 3200, // surplus > 1.25x 2000
        targetCalories: 2000,
        workoutMinutes: 25,
        workoutCount: 1,
        waterCups: 4,
        streakDays: 1,
      );

      expect(breakdown.adviceIcon, Icons.warning_amber_rounded);
      expect(breakdown.adviceText.contains('Calo nạp vào đang vượt mức tiêu hao'), isTrue);
    });

    test('Legacy calculate compatibility wrapper still returns valid scores capped at 100', () {
      final score = HealthScoreCalculator.calculate(
        currentSteps: 25000,
        goalSteps: 10000,
        caloriesIn: 800,
        caloriesOutBase: 400,
        workoutScore: 35,
      );

      expect(score <= 100, isTrue);
      expect(score >= 0, isTrue);
    });
  });
}
