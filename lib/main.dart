import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets/auth_gate.dart';
import 'services/notification_service.dart';
import 'services/locale_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  await LocaleService.init();
  await AuthService().init();
  final customApiKey = await StorageService.getGeminiApiKey();
  if (customApiKey != null && customApiKey.isNotEmpty) {
    GeminiService.setApiKey(customApiKey);
  }
  runApp(const FitnessTrackerApp());
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.languageNotifier,
      builder: (context, langCode, _) {
        return MaterialApp(
          key: ValueKey(langCode),
          title: 'Fitness Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const AuthGate(),
        );
      },
    );
  }
}
