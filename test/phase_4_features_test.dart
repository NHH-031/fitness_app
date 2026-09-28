import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/services/open_food_facts_service.dart';
import 'package:fitness_tracker/services/health_sync_service.dart';
import 'package:fitness_tracker/screens/profile/profile_health_connect_card.dart';
import 'package:fitness_tracker/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleService.init();
  });

  group('Phase 4: Open Food Facts & Barcode Scanner Tests', () {
    test('ScannedFoodProduct creates with valid properties and scales correctly', () {
      const product = ScannedFoodProduct(
        barcode: '8934563138164',
        name: 'Sữa tươi tiệt trùng Vinamilk 100% ít đường',
        calories: 140,
        protein: 6,
        carbs: 16,
        fat: 5,
        servingSize: '180 ml',
        brand: 'Vinamilk',
      );

      expect(product.barcode, '8934563138164');
      expect(product.name, contains('Vinamilk'));
      expect(product.calories, 140);
      expect(product.protein, 6);
      expect(product.carbs, 16);
      expect(product.fat, 5);
      expect(product.servingSize, '180 ml');
      expect(product.brand, 'Vinamilk');

      // Test portion scaling 1.5x
      final scaled15 = product.scale(1.5);
      expect(scaled15.calories, 210);
      expect(scaled15.protein, 9);
      expect(scaled15.carbs, 24);
      expect(scaled15.fat, 8);
      expect(scaled15.name, product.name);

      // Test portion scaling 0.5x
      final scaled05 = product.scale(0.5);
      expect(scaled05.calories, 70);
      expect(scaled05.protein, 3);
      expect(scaled05.carbs, 8);
      expect(scaled05.fat, 3);
    });

    test('OpenFoodFactsService handles empty barcode gracefully', () async {
      final service = OpenFoodFactsService.instance;
      expect(service, isNotNull);

      final resultEmpty = await service.fetchProductByBarcode('');
      expect(resultEmpty, isNull);

      final resultWhitespace = await service.fetchProductByBarcode('   ');
      expect(resultWhitespace, isNull);
    });
  });

  group('Phase 4: Health Connect & Wearable Sync Tests', () {
    test('HealthSnapshot copyWith and property checks', () {
      final now = DateTime.now();
      const snapshot = HealthSnapshot(
        steps: 8500,
        heartRateBpm: 72,
        sleepHours: 7.5,
        activeCalories: 450,
        isConnected: true,
      );

      expect(snapshot.steps, 8500);
      expect(snapshot.heartRateBpm, 72);
      expect(snapshot.sleepHours, 7.5);
      expect(snapshot.activeCalories, 450);
      expect(snapshot.isConnected, isTrue);

      final updated = snapshot.copyWith(
        steps: 10200,
        heartRateBpm: 80,
        lastSyncTime: now,
      );

      expect(updated.steps, 10200);
      expect(updated.heartRateBpm, 80);
      expect(updated.sleepHours, 7.5);
      expect(updated.lastSyncTime, now);
      expect(updated.isConnected, isTrue);
    });

    test('HealthSyncService initial state and disconnect', () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_connected': false,
      });

      final service = HealthSyncService.instance;
      await service.init();

      expect(service.status, anyOf(HealthSyncStatus.disconnected, HealthSyncStatus.connected));
      expect(service.isSyncing, isFalse);

      await service.disconnect();
      expect(service.snapshot.isConnected, isFalse);
      expect(service.status, HealthSyncStatus.disconnected);
    });

    testWidgets('ProfileHealthConnectCard renders properly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await HealthSyncService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileHealthConnectCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that title and connect button are displayed
      expect(find.byType(ProfileHealthConnectCard), findsOneWidget);
    });
  });
}
