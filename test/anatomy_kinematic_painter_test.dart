import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/widgets/anatomy_kinematic_painter.dart';

void main() {
  group('AnatomyKinematicPainter Unit Tests', () {
    test('Exercise resolution accurately classifies exercises in both Vietnamese and English', () {
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Đẩy ngực tạ đơn'),
        AnatomyExerciseType.benchPress,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Dumbbell Floor Press'),
        AnatomyExerciseType.benchPress,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Đẩy vai tạ đơn qua đầu'),
        AnatomyExerciseType.shoulderPress,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Cuốn tạ tay trước'),
        AnatomyExerciseType.bicepCurl,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Kéo tạ lưng xô'),
        AnatomyExerciseType.bentOverRow,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Squat mông đùi'),
        AnatomyExerciseType.squat,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Deadlift tạ đơn (RDL)'),
        AnatomyExerciseType.rdl,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Cầu mông đặt tạ đơn'),
        AnatomyExerciseType.hipThrust,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Hít đất kim cương'),
        AnatomyExerciseType.diamondPushUp,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Hít xà đơn'),
        AnatomyExerciseType.pullUp,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Plank siết cơ bụng'),
        AnatomyExerciseType.plank,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Gập bụng'),
        AnatomyExerciseType.crunch,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Nhảy Jumping Jacks'),
        AnatomyExerciseType.jumpingJack,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Đá mông Donkey Kicks'),
        AnatomyExerciseType.donkeyKick,
      );
      expect(
        AnatomyKinematicPainter.resolveExerciseType('Chùng chân Lunges'),
        AnatomyExerciseType.lunge,
      );
    });

    test('View mode returns correct front or side perspective for optimal biomechanics', () {
      expect(
        AnatomyKinematicPainter.getViewMode(AnatomyExerciseType.shoulderPress),
        KinematicViewMode.front,
      );
      expect(
        AnatomyKinematicPainter.getViewMode(AnatomyExerciseType.bicepCurl),
        KinematicViewMode.front,
      );
      expect(
        AnatomyKinematicPainter.getViewMode(AnatomyExerciseType.pullUp),
        KinematicViewMode.front,
      );
      expect(
        AnatomyKinematicPainter.getViewMode(AnatomyExerciseType.squat),
        KinematicViewMode.side,
      );
      expect(
        AnatomyKinematicPainter.getViewMode(AnatomyExerciseType.hipThrust),
        KinematicViewMode.side,
      );
      expect(
        AnatomyKinematicPainter.getViewMode(AnatomyExerciseType.pushUp),
        KinematicViewMode.side,
      );
      expect(
        AnatomyKinematicPainter.getViewMode(AnatomyExerciseType.plank),
        KinematicViewMode.side,
      );
    });

    test('Muscle activation factor produces dynamic concentric peak values', () {
      // Hip thrust glute activation peaks at 1.0 when progress is 1.0
      final gluteStart = AnatomyKinematicPainter.getMuscleActivation(
        0.0,
        AnatomyExerciseType.hipThrust,
        'glutes',
      );
      final glutePeak = AnatomyKinematicPainter.getMuscleActivation(
        1.0,
        AnatomyExerciseType.hipThrust,
        'glutes',
      );
      expect(glutePeak, greaterThan(gluteStart));
      expect(glutePeak, closeTo(1.0, 0.05));

      // Bicep curl activation peaks when dumbbell is curled to top
      final bicepStart = AnatomyKinematicPainter.getMuscleActivation(
        0.0,
        AnatomyExerciseType.bicepCurl,
        'biceps',
      );
      final bicepPeak = AnatomyKinematicPainter.getMuscleActivation(
        1.0,
        AnatomyExerciseType.bicepCurl,
        'biceps',
      );
      expect(bicepPeak, greaterThan(bicepStart));
      expect(bicepPeak, closeTo(1.0, 0.05));

      // Non-targeted muscles receive subtle stabilizing background activation
      final backAct = AnatomyKinematicPainter.getMuscleActivation(
        1.0,
        AnatomyExerciseType.bicepCurl,
        'lats',
      );
      expect(backAct, lessThan(0.25));
    });

    test('Theme colors adjust properly for male Cyan and female Neon Rose', () {
      final malePainter = AnatomyKinematicPainter(
        progress: 0.5,
        exerciseTitle: 'Squat',
        isMale: true,
      );
      expect(malePainter.themeColor, const Color(0xFF00F0FF));

      final femalePainter = AnatomyKinematicPainter(
        progress: 0.5,
        exerciseTitle: 'Squat',
        isMale: false,
      );
      expect(femalePainter.themeColor, const Color(0xFFFF2E93));
    });
  });

  group('AnatomyKinematicPainter Widget Paint Tests', () {
    testWidgets('Renders without error across male and female configurations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 180,
                child: CustomPaint(
                  painter: AnatomyKinematicPainter(
                    progress: 0.8,
                    exerciseTitle: 'Đẩy ngực tạ đơn',
                    isMale: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      // Switch to Female Hip thrust in side view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 180,
                child: CustomPaint(
                  painter: AnatomyKinematicPainter(
                    progress: 1.0,
                    exerciseTitle: 'Cầu mông đặt tạ',
                    isMale: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders all major exercise types across front and side views smoothly', (tester) async {
      final exercises = [
        'Hít đất',
        'Hít xà đơn',
        'Đẩy vai qua đầu',
        'Cuốn tạ tay trước',
        'Plank siết cơ bụng',
        'Gập bụng',
        'Nhảy Jumping Jacks',
        'Deadlift tạ đơn RDL',
        'Chùng chân Lunges',
        'Giãn cơ Yoga dẻo dai',
      ];

      for (final ex in exercises) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 160,
                child: CustomPaint(
                  painter: AnatomyKinematicPainter(
                    progress: 0.75,
                    exerciseTitle: ex,
                    isMale: true,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
