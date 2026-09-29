import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/widgets/exercise_pose_widget.dart';

void main() {
  group('ExercisePoseAnimator Tests', () {
    testWidgets('ExercisePoseAnimator renders with male model by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExercisePoseAnimator(
              exerciseTitle: 'Hít đất',
              height: 160,
              isMale: true,
            ),
          ),
        ),
      );

      expect(find.byType(ExercisePoseAnimator), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Mô hình Nam ♂'), findsOneWidget);
    });

    testWidgets('ExercisePoseAnimator renders female model with Neon Rose theme', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExercisePoseAnimator(
              exerciseTitle: 'Cầu mông đặt tạ',
              height: 160,
              isMale: false,
            ),
          ),
        ),
      );

      expect(find.byType(ExercisePoseAnimator), findsOneWidget);
      expect(find.text('Mô hình Nữ ♀'), findsOneWidget);
    });

    test('ExerciseGuideData returns complete steps and target muscles', () {
      final pushUpGuide = ExerciseGuideData.getForExercise('Hít đất');
      expect(pushUpGuide.targetMuscles.toLowerCase(), contains('ngực'));
      expect(pushUpGuide.steps.length, greaterThanOrEqualTo(3));

      final squatGuide = ExerciseGuideData.getForExercise('Squat mông đùi');
      expect(squatGuide.targetMuscles.toLowerCase(), contains('đùi'));

      final rdlGuide = ExerciseGuideData.getForExercise('Deadlift tạ đơn (RDL)');
      expect(rdlGuide.isDumbbell, isTrue);
    });
  });
}
