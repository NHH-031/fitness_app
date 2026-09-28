import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized localization service managing dynamic i18n JSON asset bundles,
/// language switching, and synchronous string translations with interpolation.
class LocaleService {
  static const String _keyLanguage = 'app_language';
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('vi');

  static String get currentLanguage => languageNotifier.value;
  static bool get isVietnamese => languageNotifier.value == 'vi';

  /// In-memory dictionary map loaded from JSON assets: {'vi': {...}, 'en': {...}}
  static final Map<String, Map<String, String>> _translations = {};
  static Map<String, Map<String, String>> get translations => _translations;

  /// Initializes the service by preloading language bundles and restoring saved user locale.
  static Future<void> init() async {
    await Future.wait([
      _loadLanguage('vi'),
      _loadLanguage('en'),
    ]);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_keyLanguage) ?? 'vi';
      languageNotifier.value = savedLang;
    } catch (_) {
      // SharedPreferences might not be mocked in pure unit tests
    }
  }

  /// Internal loader to deserialize language asset JSON into the memory map.
  static Future<void> _loadLanguage(String langCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/i18n/$langCode.json');
      final Map<String, dynamic> raw = json.decode(jsonString);
      _translations[langCode] = raw.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      debugPrint('LocaleService: Error loading language asset for $langCode: $e');
    }
  }

  /// Changes current active app language ('vi' | 'en') and persists choice.
  static Future<void> setLanguage(String langCode) async {
    if (langCode != 'vi' && langCode != 'en') return;

    if (_translations[langCode] == null || _translations[langCode]!.isEmpty) {
      await _loadLanguage(langCode);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, langCode);
    } catch (_) {}
    languageNotifier.value = langCode;
  }

  /// Helper shorthand for synchronous translation lookup with optional interpolation args.
  /// Example: LocaleService.tr('hello_user', args: {'name': 'Quang'})
  static String tr(String key, {Map<String, String>? args}) {
    final lang = languageNotifier.value;
    final dict = _translations[lang] ?? _translations['vi'] ?? {};
    String text = dict[key] ?? _translations['en']?[key] ?? key;

    if (args != null && args.isNotEmpty) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }
}
