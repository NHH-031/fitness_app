import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/widgets/muscle_anatomy_map_widget.dart';

void main() {
  testWidgets('MuscleAnatomyMapWidget renders and toggles gender and view properly', (tester) async {
    bool? selectedGender;
    String? selectedMuscle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MuscleAnatomyMapWidget(
              initialIsMale: true,
              onGenderChanged: (isMale) {
                selectedGender = isMale;
              },
              onMuscleSelected: (muscleId) {
                selectedMuscle = muscleId;
              },
            ),
          ),
        ),
      ),
    );

    // Initial render: Male mode, front view
    expect(find.text('Bản Đồ Giải Phẫu'), findsOneWidget);
    expect(find.text('Nam ♂'), findsOneWidget);
    expect(find.text('Nữ ♀'), findsOneWidget);
    expect(find.text('Mô hình Nam giới'), findsOneWidget);
    expect(find.text('Mặt trước'), findsOneWidget);
    expect(find.text('Mặt sau'), findsOneWidget);

    // Verify male front muscles callouts
    expect(find.text('Cơ Ngực'), findsWidgets);
    expect(find.text('Cơ Bụng'), findsWidgets);

    // Tap Female toggle: 'Nữ ♀'
    await tester.tap(find.text('Nữ ♀'));
    await tester.pumpAndSettle();

    expect(selectedGender, isFalse);
    expect(find.text('Mô hình Nữ giới'), findsOneWidget);

    // Tap Back view toggle: 'Mặt sau'
    await tester.tap(find.text('Mặt sau'));
    await tester.pumpAndSettle();

    // Verify female back muscles callouts
    expect(find.text('Cơ Mông'), findsWidgets);
    expect(find.text('Đùi Sau'), findsWidgets);
    expect(find.text('Cầu Vai'), findsWidgets);

    // Tap a muscle chip: 'Cơ Mông'
    await tester.tap(find.text('Cơ Mông').first);
    await tester.pumpAndSettle();

    expect(selectedMuscle, 'glutes');
  });
}
