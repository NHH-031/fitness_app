import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/models/chat_message.dart';
import 'package:fitness_tracker/services/storage_service.dart';
import 'package:fitness_tracker/services/locale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatMessage Model & Serialization Tests', () {
    test('ChatMessage json serialization and deserialization works correctly', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg_001',
        role: 'user',
        text: 'Nên ăn gì sau khi tập gym?',
        timestamp: now,
        metadata: {'calories': 200},
      );

      expect(msg.isUser, isTrue);
      expect(msg.isModel, isFalse);

      final jsonMap = msg.toJson();
      expect(jsonMap['id'], 'msg_001');
      expect(jsonMap['role'], 'user');
      expect(jsonMap['text'], 'Nên ăn gì sau khi tập gym?');
      expect(jsonMap['timestamp'], now.toIso8601String());

      final fromJson = ChatMessage.fromJson(jsonMap);
      expect(fromJson.id, msg.id);
      expect(fromJson.role, msg.role);
      expect(fromJson.text, msg.text);
      expect(fromJson.metadata?['calories'], 200);
    });

    test('ChatMessage Firestore serialization and deserialization works correctly', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg_002',
        role: 'model',
        text: 'Bạn nên bổ sung khoảng 25-30g đạm từ ức gà hoặc whey protein.',
        timestamp: now,
      );

      expect(msg.isModel, isTrue);
      expect(msg.isUser, isFalse);

      final firestoreMap = msg.toFirestore();
      expect(firestoreMap['id'], 'msg_002');
      expect(firestoreMap['role'], 'model');
      expect(firestoreMap['timestamp'], now.millisecondsSinceEpoch);

      final fromFirestore = ChatMessage.fromFirestore(firestoreMap);
      expect(fromFirestore.id, msg.id);
      expect(fromFirestore.role, msg.role);
      expect(fromFirestore.text, msg.text);
    });
  });

  group('AI Chat Storage & History Management Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocaleService.init();
    });

    test('Initial chat history is empty', () async {
      final list = await StorageService.getLocalChatHistory();
      expect(list, isEmpty);
    });

    test('Save and retrieve chat messages in chronological order', () async {
      final t1 = DateTime.now().subtract(const Duration(minutes: 5));
      final t2 = DateTime.now().subtract(const Duration(minutes: 4));

      final msg1 = ChatMessage(id: '1', role: 'user', text: 'Chào Gemini', timestamp: t1);
      final msg2 = ChatMessage(id: '2', role: 'model', text: 'Chào bạn! Mình có thể giúp gì?', timestamp: t2);

      await StorageService.saveLocalChatMessage(msg1);
      await StorageService.saveLocalChatMessage(msg2);

      final history = await StorageService.getLocalChatHistory();
      expect(history.length, 2);
      expect(history.first.text, 'Chào Gemini');
      expect(history.last.text, 'Chào bạn! Mình có thể giúp gì?');
    });

    test('Chat notification triggers on save and clear', () async {
      int notifyCount = 0;
      StorageService.chatUpdateNotifier.addListener(() {
        notifyCount++;
      });

      final msg = ChatMessage(
        id: '10',
        role: 'user',
        text: 'Hôm nay tôi uống được bao nhiêu nước?',
        timestamp: DateTime.now(),
      );

      await StorageService.saveLocalChatMessage(msg);
      expect(notifyCount, 1);

      await StorageService.clearLocalChatHistory();
      expect(notifyCount, 2);

      final list = await StorageService.getLocalChatHistory();
      expect(list, isEmpty);
    });

    test('Saving multiple messages from Cloud sync merges and sorts properly', () async {
      final t1 = DateTime(2026, 9, 28, 10, 0);
      final t2 = DateTime(2026, 9, 28, 10, 1);
      final t3 = DateTime(2026, 9, 28, 10, 2);

      final cloudMessages = [
        ChatMessage(id: 'c2', role: 'model', text: 'Ăn yến mạch nhé', timestamp: t2),
        ChatMessage(id: 'c1', role: 'user', text: 'Bữa sáng nên ăn gì?', timestamp: t1),
        ChatMessage(id: 'c3', role: 'user', text: 'Cảm ơn bạn', timestamp: t3),
      ];

      await StorageService.saveMultipleLocalChatMessages(cloudMessages);

      final history = await StorageService.getLocalChatHistory();
      expect(history.length, 3);
      expect(history[0].id, 'c1');
      expect(history[1].id, 'c2');
      expect(history[2].id, 'c3');
    });
  });
}
