import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/chat_message.dart';
import '../services/firestore_service.dart';

/// Repository quản lý lịch sử hội thoại của AI Coach và AI Nutritionist.
/// Lưu trữ trực tiếp vào cơ sở dữ liệu SQLite cục bộ và đồng bộ đa chiều với Firestore.
class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  /// Lưu tin nhắn AI Chat vào cơ sở dữ liệu SQLite
  Future<void> saveLocalChatMessage(ChatMessage message) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.insert(
        'chat_messages',
        {
          'id': message.id,
          'role': message.role,
          'text': message.text,
          'timestamp': message.timestamp.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint("Lỗi lưu tin nhắn chat vào SQLite: $e");
    }
  }

  /// Lấy danh sách lịch sử tin nhắn AI Chat từ SQLite
  Future<List<ChatMessage>> getLocalChatHistory({int limit = 100}) async {
    try {
      final db = await AppDatabase.instance.database;
      final results = await db.query(
        'chat_messages',
        orderBy: 'timestamp ASC',
        limit: limit,
      );

      final List<ChatMessage> list = [];
      for (final row in results) {
        list.add(ChatMessage(
          id: row['id'] as String,
          role: (row['role'] as String?) ?? 'user',
          text: row['text'] as String,
          timestamp: DateTime.tryParse(row['timestamp'] as String) ?? DateTime.now(),
        ));
      }
      return list;
    } catch (e) {
      debugPrint("Lỗi đọc lịch sử chat từ SQLite: $e");
      return [];
    }
  }

  /// Lưu hàng loạt tin nhắn từ Cloud về SQLite (dùng khi Sync)
  Future<void> saveMultipleLocalChatMessages(List<ChatMessage> messages) async {
    try {
      final db = await AppDatabase.instance.database;
      final batch = db.batch();
      for (final m in messages) {
        batch.insert(
          'chat_messages',
          {
            'id': m.id,
            'role': m.role,
            'text': m.text,
            'timestamp': m.timestamp.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint("Lỗi đồng bộ nhiều tin nhắn chat vào SQLite: $e");
    }
  }

  /// Xóa toàn bộ lịch sử AI Chat cục bộ trong SQLite
  Future<void> clearLocalChatHistory() async {
    try {
      final db = await AppDatabase.instance.database;
      await db.delete('chat_messages');
    } catch (e) {
      debugPrint("Lỗi xóa lịch sử chat cục bộ: $e");
    }
  }

  /// Phương thức Hybrid tổng hợp: Lưu tin nhắn vừa vào SQLite vừa đẩy lên Cloud Firestore
  Future<void> saveChatMessage(ChatMessage message) async {
    await saveLocalChatMessage(message);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().saveChatMessage(message);
      }
    } catch (e) {
      debugPrint("Lưu chat lên Cloud Firestore thất bại: $e");
    }
  }

  /// Phương thức Hybrid tổng hợp: Xóa lịch sử trên cả SQLite và Cloud Firestore
  Future<void> clearAllChatHistory() async {
    await clearLocalChatHistory();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().clearChatHistory();
      }
    } catch (e) {
      debugPrint("Xóa chat trên Cloud Firestore lỗi: $e");
    }
  }
}
