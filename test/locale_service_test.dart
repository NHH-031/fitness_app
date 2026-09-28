import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/services/locale_service.dart';
import 'package:fitness_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleService.init();
  });

  group('LocaleService Tests', () {
    test('Default language is vi on clean launch', () {
      expect(LocaleService.currentLanguage, equals('vi'));
      expect(LocaleService.isVietnamese, isTrue);
      expect(LocaleService.languageNotifier.value, equals('vi'));
    });

    test('Both vi and en dictionaries have complete symmetry of keys', () {
      final viKeys = LocaleService.translations['vi']!.keys.toSet();
      final enKeys = LocaleService.translations['en']!.keys.toSet();

      final missingInEn = viKeys.difference(enKeys);
      final missingInVi = enKeys.difference(viKeys);

      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys present in VI but missing in EN: $missingInEn',
      );
      expect(
        missingInVi,
        isEmpty,
        reason: 'Keys present in EN but missing in VI: $missingInVi',
      );
      expect(viKeys.length, equals(enKeys.length));
    });

    test('Translation works for basic navigation keys in vi and en', () async {
      await LocaleService.setLanguage('vi');
      expect(LocaleService.tr('nav_dashboard'), equals('Tổng quan'));
      expect(LocaleService.tr('nav_activity'), equals('Hoạt động'));
      expect(LocaleService.tr('nav_food'), equals('Dinh dưỡng'));
      expect(LocaleService.tr('nav_profile'), equals('Hồ sơ'));

      await LocaleService.setLanguage('en');
      expect(LocaleService.tr('nav_dashboard'), equals('Dashboard'));
      expect(LocaleService.tr('nav_activity'), equals('Activity'));
      expect(LocaleService.tr('nav_food'), equals('Food'));
      expect(LocaleService.tr('nav_profile'), equals('Profile'));
    });

    test('Interpolation arguments are properly replaced', () async {
      await LocaleService.setLanguage('vi');
      final viBadge = LocaleService.tr(
        'ai_synced_badge',
        args: {'name': 'Quang', 'goal': 'CUTTING'},
      );
      expect(viBadge, equals('AI cá nhân hóa theo: Quang (CUTTING)'));

      await LocaleService.setLanguage('en');
      final enBadge = LocaleService.tr(
        'ai_synced_badge',
        args: {'name': 'Quang', 'goal': 'CUTTING'},
      );
      expect(enBadge, equals('AI personalized for: Quang (CUTTING)'));
    });

    test('Numeric interpolation works for calories and progress', () async {
      await LocaleService.setLanguage('en');
      final progressText = LocaleService.tr('target_progress', args: {'percent': '85'});
      expect(progressText, equals('85% Target'));

      await LocaleService.setLanguage('vi');
      final progressVi = LocaleService.tr('target_progress', args: {'percent': '85'});
      expect(progressVi, equals('85% Mục tiêu'));
    });

    test('Switching language persists to StorageService', () async {
      await LocaleService.setLanguage('en');
      expect(await StorageService.getAppLanguage(), equals('en'));

      await LocaleService.setLanguage('vi');
      expect(await StorageService.getAppLanguage(), equals('vi'));
    });

    test('ValueNotifier notifies listeners when language changes', () async {
      String? notifiedLang;
      LocaleService.languageNotifier.addListener(() {
        notifiedLang = LocaleService.languageNotifier.value;
      });

      await LocaleService.setLanguage('en');
      expect(notifiedLang, equals('en'));

      await LocaleService.setLanguage('vi');
      expect(notifiedLang, equals('vi'));
    });

    test('tr returns fallback key if non-existent key requested', () {
      expect(LocaleService.tr('non_existent_key_xyz'), equals('non_existent_key_xyz'));
    });
  });
}
