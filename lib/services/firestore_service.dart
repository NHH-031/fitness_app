import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import 'storage_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  String? get currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = currentUid;
    final fs = _firestore;
    if (uid == null || fs == null) return null;
    return fs.collection('users').doc(uid);
  }

  // --- USER PROFILE & METADATA ---

  Future<void> saveUserProfile(UserProfile profile) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.set({
        'profile': profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveUserProfile error: $e');
    }
  }

  Future<UserProfile?> getUserProfile() async {
    final doc = _userDoc;
    if (doc == null) return null;
    try {
      final snapshot = await doc.get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      if (data.containsKey('profile') && data['profile'] is Map) {
        return UserProfile.fromJson(Map<String, dynamic>.from(data['profile'] as Map));
      }
    } catch (e) {
      debugPrint('Firestore getUserProfile error: $e');
    }
    return null;
  }

  Future<void> updateStreak(int streak, String lastLoginDate) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.set({
        'streak': {
          'currentStreak': streak,
          'lastLoginDate': lastLoginDate,
        },
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateStreak error: $e');
    }
  }

  // --- FOOD LOGS ---

  Future<void> saveFoodLog(FoodLogEntry entry) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('food_logs').doc(entry.id).set(entry.toJson());
    } catch (e) {
      debugPrint('Firestore saveFoodLog error: $e');
    }
  }

  Future<void> deleteFoodLog(String id) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('food_logs').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteFoodLog error: $e');
    }
  }

  Future<List<FoodLogEntry>> getAllFoodLogs() async {
    final doc = _userDoc;
    if (doc == null) return [];
    try {
      final querySnapshot = await doc
          .collection('food_logs')
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs.map((d) => FoodLogEntry.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('Firestore getAllFoodLogs error: $e');
      return [];
    }
  }

  // --- WORKOUT LOGS ---

  Future<void> saveWorkoutLog(Map<String, dynamic> log) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final id = log['timestamp']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ??
          DateTime.now().millisecondsSinceEpoch.toString();
      await doc.collection('workout_logs').doc(id).set(log);
    } catch (e) {
      debugPrint('Firestore saveWorkoutLog error: $e');
    }
  }

  Future<void> deleteWorkoutLog(String timestamp) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final id = timestamp.replaceAll(RegExp(r'[^0-9]'), '');
      await doc.collection('workout_logs').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteWorkoutLog error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogs() async {
    final doc = _userDoc;
    if (doc == null) return [];
    try {
      final querySnapshot = await doc.collection('workout_logs').get();
      return querySnapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Firestore getWorkoutLogs error: $e');
      return [];
    }
  }

  // --- WATER LOGS ---

  Future<void> saveWaterData(String dateStr, int volumeMl, int cups) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('water_logs').doc(dateStr).set({
        'volumeMl': volumeMl,
        'cups': cups,
        'date': dateStr,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveWaterData error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWaterHistoryLogs({int limit = 30}) async {
    final doc = _userDoc;
    if (doc == null) return [];
    try {
      final snapshot = await doc
          .collection('water_logs')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Firestore getWaterHistoryLogs error: $e');
      return [];
    }
  }

  // --- DAILY SUMMARIES ---
  Future<void> saveDailySummary(DailyActivitySummary summary) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('daily_summaries').doc(summary.date).set({
        ...summary.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveDailySummary error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDailySummaries({int limit = 30}) async {
    final doc = _userDoc;
    if (doc == null) return [];
    try {
      final snapshot = await doc
          .collection('daily_summaries')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Firestore getDailySummaries error: $e');
      return [];
    }
  }

  // --- AI CHAT HISTORY ---

  Future<void> saveChatMessage(ChatMessage message) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc
          .collection('ai_chat_history')
          .doc(message.id)
          .set(message.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveChatMessage error: $e');
    }
  }

  Future<List<ChatMessage>> getChatHistory({int limit = 100}) async {
    final doc = _userDoc;
    if (doc == null) return [];
    try {
      final querySnapshot = await doc
          .collection('ai_chat_history')
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();
      return querySnapshot.docs
          .map((d) => ChatMessage.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      debugPrint('Firestore getChatHistory error: $e');
      return [];
    }
  }

  Stream<List<ChatMessage>> streamChatHistory({int limit = 100}) {
    final doc = _userDoc;
    if (doc == null) return const Stream.empty();
    return doc
        .collection('ai_chat_history')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => ChatMessage.fromFirestore(d.data())).toList());
  }

  Future<void> clearChatHistory() async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final snapshot = await doc.collection('ai_chat_history').get();
      final batch = _firestore?.batch();
      if (batch != null) {
        for (final d in snapshot.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Firestore clearChatHistory error: $e');
    }
  }

  // --- SYNC BETWEEN LOCAL (SharedPreferences) AND CLOUD (Firestore) ---

  /// Sau khi user đăng nhập, kiểm tra nếu cloud chưa có dữ liệu thì đẩy dữ liệu local lên cloud,
  /// hoặc nếu cloud đã có dữ liệu thì kéo về đồng bộ vào local cache.
  Future<void> syncOnLogin() async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      final userSnapshot = await doc.get();

      if (!userSnapshot.exists || userSnapshot.data()?['profile'] == null) {
        // Tài khoản mới trên cloud: Cập nhật streak từ dữ liệu hoạt động thực tế và đẩy toàn bộ dữ liệu local lên cloud
        await StorageService.checkAndUpdateStreak();
        await _pushLocalDataToCloud();
      } else {
        // Tài khoản đã có dữ liệu trên cloud: Tải từ Cloud về Local và cập nhật chuỗi
        await _pullCloudDataToLocal();
        await StorageService.checkAndUpdateStreak();
      }
      StorageService.notifyDataChanged();
    } catch (e) {
      debugPrint('Firestore syncOnLogin error: $e');
    }
  }

  /// Đẩy dữ liệu hiện có ở SharedPreferences lên Firestore bằng WriteBatch tối ưu
  Future<void> _pushLocalDataToCloud() async {
    final doc = _userDoc;
    final fs = _firestore;
    if (doc == null || fs == null) return;

    final user = FirebaseAuth.instance.currentUser;
    // 1. Tạo user metadata
    await doc.set({
      'email': user?.email ?? '',
      'displayName': user?.displayName ?? '',
      'photoURL': user?.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Profile
    final localProfile = await StorageService.getUserProfile();
    await saveUserProfile(localProfile);

    // 3. Streak
    final streak = await StorageService.getCurrentStreak();
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login_date') ?? DateTime.now().toIso8601String();
    await updateStreak(streak, lastLogin);

    // Chuẩn bị batch writer (tối đa 400 thao tác / batch)
    WriteBatch batch = fs.batch();
    int opCount = 0;

    Future<void> commitBatchIfNeeded() async {
      if (opCount >= 400) {
        await batch.commit();
        batch = fs.batch();
        opCount = 0;
      }
    }

    // 4. Workout logs
    final localWorkouts = await StorageService.getWorkoutLogs();
    for (final w in localWorkouts) {
      final id = w['timestamp']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final workoutDoc = doc.collection('workout_logs').doc(id);
      batch.set(workoutDoc, w, SetOptions(merge: true));
      opCount++;
      await commitBatchIfNeeded();
    }

    // 5. Food logs
    final rawFoodLogs = prefs.getStringList('user_food_logs') ?? [];
    for (final str in rawFoodLogs) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        final entry = FoodLogEntry.fromJson(map);
        final foodDoc = doc.collection('food_logs').doc(entry.id);
        batch.set(foodDoc, entry.toJson(), SetOptions(merge: true));
        opCount++;
        await commitBatchIfNeeded();
      } catch (_) {}
    }

    // 6. Water logs
    final waterLogs = await StorageService.getWaterHistoryLogs();
    for (final log in waterLogs) {
      final waterDoc = doc.collection('water_logs').doc(log.date);
      batch.set(waterDoc, {
        'date': log.date,
        'volumeMl': log.volumeMl,
        'cups': log.cups,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      opCount++;
      await commitBatchIfNeeded();
    }

    // 7. AI Chat History
    final localChats = await StorageService.getLocalChatHistory();
    for (final chat in localChats) {
      final chatDoc = doc.collection('chat_messages').doc(chat.id);
      batch.set(chatDoc, chat.toJson(), SetOptions(merge: true));
      opCount++;
      await commitBatchIfNeeded();
    }

    if (opCount > 0) {
      await batch.commit();
    }

    debugPrint('Đã đồng bộ toàn bộ dữ liệu local lên Cloud Firestore qua WriteBatch thành công ($opCount bản ghi).');
  }

  /// Tải dữ liệu từ Firestore xuống SharedPreferences (Local Cache)
  Future<void> _pullCloudDataToLocal() async {
    final doc = _userDoc;
    if (doc == null) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Profile
    final cloudProfile = await getUserProfile();
    if (cloudProfile != null) {
      await prefs.setString('user_profile', jsonEncode(cloudProfile.toJson()));
      await StorageService.setCompletedOnboarding(true);
    }

    // 2. Streak
    final snapshot = await doc.get();
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      if (data.containsKey('streak') && data['streak'] is Map) {
        final streakMap = Map<String, dynamic>.from(data['streak'] as Map);
        if (streakMap['currentStreak'] != null) {
          await prefs.setInt('current_streak', (streakMap['currentStreak'] as num).toInt());
        }
        if (streakMap['lastLoginDate'] != null) {
          await prefs.setString('last_login_date', streakMap['lastLoginDate'].toString());
        }
      }
    }

    // 3. Workouts
    final cloudWorkouts = await getWorkoutLogs();
    if (cloudWorkouts.isNotEmpty) {
      final encodedList = cloudWorkouts.map((w) => jsonEncode(w)).toList();
      await prefs.setStringList('completed_workout_logs', encodedList);
    }

    // 4. Food logs
    final cloudFood = await getAllFoodLogs();
    if (cloudFood.isNotEmpty) {
      final encodedList = cloudFood.map((f) => jsonEncode(f.toJson())).toList();
      await prefs.setStringList('user_food_logs', encodedList);
    }

    // 5. Water logs
    final cloudWaterLogs = await getWaterHistoryLogs();
    if (cloudWaterLogs.isNotEmpty) {
      final localWaterLogs = await StorageService.getWaterHistoryLogs();
      if (localWaterLogs.isEmpty) {
        final List<String> encoded = [];
        for (final item in cloudWaterLogs) {
          encoded.add(jsonEncode({
            'date': item['date']?.toString() ?? '',
            'cups': (item['cups'] as num?)?.toInt() ?? 0,
            'volumeMl': (item['volumeMl'] as num?)?.toInt() ?? 0,
            'updatedAt': DateTime.now().toIso8601String(),
          }));
        }
        await prefs.setStringList('daily_water_history', encoded);
      }
    }

    // 6. AI Chat History
    final cloudChats = await getChatHistory();
    if (cloudChats.isNotEmpty) {
      await StorageService.saveMultipleLocalChatMessages(cloudChats);
    }

    debugPrint('Đã tải và cập nhật dữ liệu từ Cloud Firestore về máy thành công.');
  }
}
