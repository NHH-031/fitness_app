import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Water Reminder & Tracking Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial water settings should have reasonable defaults', () async {
      final isEnabled = await StorageService.isWaterReminderEnabled();
      final interval = await StorageService.getWaterReminderInterval();
      final cups = await StorageService.getWaterCupsToday();

      expect(isEnabled, true);
      expect(interval, 2);
      expect(cups, 0);
    });

    test('Adding and removing water cups should track accurately', () async {
      var cups = await StorageService.addWaterCup();
      expect(cups, 1);

      cups = await StorageService.addWaterCup();
      expect(cups, 2);

      cups = await StorageService.removeWaterCup();
      expect(cups, 1);
    });

    test('Toggling reminder and changing interval should persist', () async {
      await StorageService.setWaterReminderEnabled(false);
      expect(await StorageService.isWaterReminderEnabled(), false);

      await StorageService.setWaterReminderInterval(3);
      expect(await StorageService.getWaterReminderInterval(), 3);
    });
  });
}
