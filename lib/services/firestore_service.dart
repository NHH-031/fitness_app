import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../models/body_measurement.dart';
import '../models/favorite_food.dart';
import '../repositories/body_measurement_repository.dart';
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

  // --- BODY MEASUREMENTS (SỐ ĐO CƠ THỂ & % MỠ) ---

  Future<void> saveBodyMeasurement(BodyMeasurement measurement) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc
          .collection('body_measurements')
          .doc(measurement.id)
          .set(measurement.toMap(), SetOptions(merge: true));
      debugPrint('Firestore saveBodyMeasurement: ${measurement.id} saved');
    } catch (e) {
      debugPrint('Firestore saveBodyMeasurement error: $e');
    }
  }

  Future<void> deleteBodyMeasurement(String id) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('body_measurements').doc(id).delete();
      debugPrint('Firestore deleteBodyMeasurement: $id deleted');
    } catch (e) {
      debugPrint('Firestore deleteBodyMeasurement error: $e');
    }
  }

  Future<List<BodyMeasurement>> getBodyMeasurements() async {
    final doc = _userDoc;
    if (doc == null) return [];
    try {
      final querySnapshot = await doc
          .collection('body_measurements')
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((d) => BodyMeasurement.fromMap(d.data())).toList();
    } catch (e) {
      debugPrint('Firestore getBodyMeasurements error: $e');
      return [];
    }
  }

  // --- BODY PHOTOS METADATA (ẢNH BEFORE / AFTER) ---

  Future<void> saveBodyPhotosMeta({String? beforePhotoPath, String? afterPhotoPath}) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (beforePhotoPath != null) data['beforePhotoPath'] = beforePhotoPath;
      if (afterPhotoPath != null) data['afterPhotoPath'] = afterPhotoPath;
      await doc.collection('body_measurements').doc('photo_meta').set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveBodyPhotosMeta error: $e');
    }
  }

  // --- FAVORITE FOODS (MÓN ĂN QUEN THUỘC) ---

  Future<void> saveFavoriteFood(FavoriteFood food) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc
          .collection('favorite_foods')
          .doc(food.id)
          .set(food.toMap(), SetOptions(merge: true));
      debugPrint('Firestore saveFavoriteFood: ${food.name} saved');
    } catch (e) {
      debugPrint('Firestore saveFavoriteFood error: $e');
    }
  }

  Future<void> deleteFavoriteFood(String id) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('favorite_foods').doc(id).delete();
      debugPrint('Firestore deleteFavoriteFood: $id deleted');
    } catch (e) {
      debugPrint('Firestore deleteFavoriteFood error: $e');
    }
  }

  Future<List<FavoriteFood>> getFavoriteFoods() async {
    final doc = _userDoc;
    if (doc == null) return [];
    try {
      final querySnapshot = await doc
          .collection('favorite_foods')
          .orderBy('created_at', descending: true)
          .get();
      return querySnapshot.docs.map((d) => FavoriteFood.fromMap(d.data())).toList();
    } catch (e) {
      debugPrint('Firestore getFavoriteFoods error: $e');
      return [];
    }
  }

  // --- SECURITY & BIOMETRIC SETTINGS ---

  Future<void> saveAppLockSetting(bool enabled) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('settings').doc('security').set({
        'appLockEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveAppLockSetting error: $e');
    }
  }

  Future<bool?> getAppLockSetting() async {
    final doc = _userDoc;
    if (doc == null) return null;
    try {
      final snap = await doc.collection('settings').doc('security').get();
      if (snap.exists && snap.data() != null) {
        return snap.data()!['appLockEnabled'] as bool?;
      }
    } catch (e) {
      debugPrint('Firestore getAppLockSetting error: $e');
    }
    return null;
  }

  // --- COMPREHENSIVE 2-WAY SYNC (ĐỒNG BỘ 2 CHIỀU GIỮA LOCAL VÀ CLOUD) ---

  /// Sau khi user đăng nhập (kể cả từ chế độ khách), thực hiện 2-Way Merge toàn diện:
  /// - Hợp nhất bài tập (Workouts): giữ cả bài tập ở chế độ khách và trên đám mây.
  /// - Hợp nhất đồ ăn (Food logs): không bị đè mất các món vừa thêm ở chế độ khách.
  /// - Hợp nhất lượng nước uống (Water logs): giữ nguyên nước đã uống hôm nay và lịch sử.
  /// - Hợp nhất Hồ sơ & Chuỗi (Profile & Streak).
  /// - Tải lên đám mây các dữ liệu khách tạo ra và kéo về dữ liệu đám mây còn thiếu.
  /// - Làm mới toàn bộ bộ nhớ đệm (Cache) và kích hoạt Notifier cho các màn hình.
  Future<void> syncOnLogin() async {
    final doc = _userDoc;
    final fs = _firestore;
    if (doc == null || fs == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      // 1. Tạo/cập nhật user metadata trên Firestore
      await doc.set({
        'email': user?.email ?? '',
        'displayName': user?.displayName ?? '',
        'photoURL': user?.photoURL ?? '',
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Profile 2-Way Merge
      final localProfile = await StorageService.getUserProfile();
      final cloudProfile = await getUserProfile();
      UserProfile mergedProfile;
      if (cloudProfile != null) {
        mergedProfile = UserProfile(
          name: (user?.displayName != null && user!.displayName!.isNotEmpty)
              ? user.displayName!
              : (cloudProfile.name.isNotEmpty ? cloudProfile.name : localProfile.name),
          gender: cloudProfile.gender.isNotEmpty ? cloudProfile.gender : localProfile.gender,
          age: cloudProfile.age > 0 ? cloudProfile.age : localProfile.age,
          height: cloudProfile.height > 0 ? cloudProfile.height : localProfile.height,
          weight: cloudProfile.weight > 0 ? cloudProfile.weight : localProfile.weight,
          targetWeight: cloudProfile.targetWeight > 0 ? cloudProfile.targetWeight : localProfile.targetWeight,
          fitnessGoal: cloudProfile.fitnessGoal.isNotEmpty ? cloudProfile.fitnessGoal : localProfile.fitnessGoal,
          activityLevel: cloudProfile.activityLevel > 0 ? cloudProfile.activityLevel : localProfile.activityLevel,
          avatarIndex: cloudProfile.avatarIndex >= 0 ? cloudProfile.avatarIndex : localProfile.avatarIndex,
        );
      } else {
        mergedProfile = UserProfile(
          name: (user?.displayName != null && user!.displayName!.isNotEmpty) ? user.displayName! : localProfile.name,
          gender: localProfile.gender,
          age: localProfile.age,
          height: localProfile.height,
          weight: localProfile.weight,
          targetWeight: localProfile.targetWeight,
          fitnessGoal: localProfile.fitnessGoal,
          activityLevel: localProfile.activityLevel,
          avatarIndex: localProfile.avatarIndex,
        );
      }
      await prefs.setString('user_profile', jsonEncode(mergedProfile.toJson()));
      await StorageService.setCompletedOnboarding(true);
      await saveUserProfile(mergedProfile);

      // 3. Chuỗi Streak 2-Way Merge
      final localStreak = await StorageService.getCurrentStreak();
      int cloudStreak = 0;
      String? cloudLastLogin;
      final userSnapshot = await doc.get();
      if (userSnapshot.exists && userSnapshot.data() != null) {
        final data = userSnapshot.data()!;
        if (data.containsKey('streak') && data['streak'] is Map) {
          final sMap = Map<String, dynamic>.from(data['streak'] as Map);
          cloudStreak = (sMap['currentStreak'] as num?)?.toInt() ?? 0;
          cloudLastLogin = sMap['lastLoginDate']?.toString();
        }
      }
      final mergedStreak = localStreak > cloudStreak ? localStreak : cloudStreak;
      final lastLogin = prefs.getString('last_login_date') ??
          cloudLastLogin ??
          DateTime.now().toIso8601String().split('T')[0];
      await prefs.setInt('current_streak', mergedStreak);
      await prefs.setString('last_login_date', lastLogin);
      await updateStreak(mergedStreak, lastLogin);

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

      // 4. Workout Logs 2-Way Merge
      final localWorkouts = await StorageService.getWorkoutLogs();
      final cloudWorkouts = await getWorkoutLogs();

      final Map<String, Map<String, dynamic>> mergedWorkoutsMap = {};
      for (final w in cloudWorkouts) {
        final key = w['timestamp']?.toString() ?? '';
        if (key.isNotEmpty) {
          mergedWorkoutsMap[key] = Map<String, dynamic>.from(w);
        }
      }
      for (final w in localWorkouts) {
        final key = w['timestamp']?.toString() ?? '';
        if (key.isNotEmpty) {
          if (!mergedWorkoutsMap.containsKey(key)) {
            mergedWorkoutsMap[key] = Map<String, dynamic>.from(w);
            final id = key.replaceAll(RegExp(r'[^0-9]'), '');
            final workoutDoc = doc.collection('workout_logs').doc(id);
            batch.set(workoutDoc, w, SetOptions(merge: true));
            opCount++;
            await commitBatchIfNeeded();
          }
        }
      }
      final sortedWorkouts = mergedWorkoutsMap.values.toList();
      sortedWorkouts.sort((a, b) {
        final tA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(2000);
        final tB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(2000);
        return tB.compareTo(tA);
      });
      await prefs.setStringList(
        'completed_workout_logs',
        sortedWorkouts.map((w) => jsonEncode(w)).toList(),
      );
      // Đồng bộ vào cơ sở dữ liệu SQLite
      await WorkoutRepository.instance.saveMultipleWorkoutLogs(sortedWorkouts);

      // 5. Food Logs 2-Way Merge
      final rawFoodLogs = prefs.getStringList('user_food_logs') ?? [];
      final List<FoodLogEntry> localFoodList = [];
      for (final str in rawFoodLogs) {
        try {
          localFoodList.add(FoodLogEntry.fromJson(jsonDecode(str) as Map<String, dynamic>));
        } catch (_) {}
      }
      try {
        final sqliteFoods = await NutritionRepository.instance.getFoodLogs();
        for (final sf in sqliteFoods) {
          if (!localFoodList.any((lf) => lf.id == sf.id)) {
            localFoodList.add(sf);
          }
        }
      } catch (_) {}

      final cloudFoodList = await getAllFoodLogs();
      final Map<String, FoodLogEntry> mergedFoodMap = {};
      for (final f in cloudFoodList) {
        mergedFoodMap[f.id] = f;
      }
      for (final f in localFoodList) {
        if (!mergedFoodMap.containsKey(f.id)) {
          mergedFoodMap[f.id] = f;
          final foodDoc = doc.collection('food_logs').doc(f.id);
          batch.set(foodDoc, f.toJson(), SetOptions(merge: true));
          opCount++;
          await commitBatchIfNeeded();
        }
      }
      final sortedFood = mergedFoodMap.values.toList();
      sortedFood.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await prefs.setStringList(
        'user_food_logs',
        sortedFood.map((f) => jsonEncode(f.toJson())).toList(),
      );
      // Đồng bộ vào cơ sở dữ liệu SQLite
      await NutritionRepository.instance.saveMultipleFoodLogs(sortedFood);

      // 6. Water Logs 2-Way Merge & Bảo toàn lượng nước uống hôm nay
      final localWaterHistory = await StorageService.getWaterHistoryLogs();
      final cloudWaterHistory = await getWaterHistoryLogs();
      final todayStr = StorageService.getTodayDateString();

      final localTodayCups = prefs.getInt('water_cups_today') ?? 0;
      final localTodayMl = prefs.getInt('water_volume_ml_today') ?? (localTodayCups * 250);

      final Map<String, Map<String, dynamic>> mergedWaterMap = {};
      for (final item in cloudWaterHistory) {
        final date = item['date']?.toString() ?? '';
        if (date.isNotEmpty) {
          mergedWaterMap[date] = {
            'date': date,
            'cups': (item['cups'] as num?)?.toInt() ?? 0,
            'volumeMl': (item['volumeMl'] as num?)?.toInt() ?? 0,
          };
        }
      }

      for (final localItem in localWaterHistory) {
        final date = localItem.date;
        if (mergedWaterMap.containsKey(date)) {
          final cloudItem = mergedWaterMap[date]!;
          final cCups = (cloudItem['cups'] as num?)?.toInt() ?? 0;
          final cMl = (cloudItem['volumeMl'] as num?)?.toInt() ?? 0;
          final maxCups = localItem.cups > cCups ? localItem.cups : cCups;
          final maxMl = localItem.volumeMl > cMl ? localItem.volumeMl : cMl;
          mergedWaterMap[date] = {
            'date': date,
            'cups': maxCups,
            'volumeMl': maxMl,
          };
          if (localItem.cups > cCups || localItem.volumeMl > cMl) {
            final waterDoc = doc.collection('water_logs').doc(date);
            batch.set(waterDoc, {
              'date': date,
              'volumeMl': maxMl,
              'cups': maxCups,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            opCount++;
            await commitBatchIfNeeded();
          }
        } else {
          mergedWaterMap[date] = {
            'date': date,
            'cups': localItem.cups,
            'volumeMl': localItem.volumeMl,
          };
          final waterDoc = doc.collection('water_logs').doc(date);
          batch.set(waterDoc, {
            'date': date,
            'volumeMl': localItem.volumeMl,
            'cups': localItem.cups,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          opCount++;
          await commitBatchIfNeeded();
        }
      }

      // Xử lý riêng cho ngày hôm nay (todayStr)
      int finalTodayCups = localTodayCups;
      int finalTodayMl = localTodayMl;
      if (mergedWaterMap.containsKey(todayStr)) {
        final mCups = (mergedWaterMap[todayStr]!['cups'] as num?)?.toInt() ?? 0;
        final mMl = (mergedWaterMap[todayStr]!['volumeMl'] as num?)?.toInt() ?? 0;
        if (mCups > finalTodayCups) finalTodayCups = mCups;
        if (mMl > finalTodayMl) finalTodayMl = mMl;
      }
      mergedWaterMap[todayStr] = {
        'date': todayStr,
        'cups': finalTodayCups,
        'volumeMl': finalTodayMl,
      };

      // Ghi nhận đầy đủ vào SharedPreferences để bảo toàn dữ liệu khi khởi động lại
      await prefs.setString('water_date', todayStr);
      await prefs.setInt('water_cups_today', finalTodayCups);
      await prefs.setInt('water_volume_ml_today', finalTodayMl);

      final List<String> encodedWaterList = mergedWaterMap.values.map((item) {
        return jsonEncode({
          'date': item['date'],
          'cups': item['cups'],
          'volumeMl': item['volumeMl'],
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }).toList();
      await prefs.setStringList('daily_water_history', encodedWaterList);
      // Đồng bộ vào cơ sở dữ liệu SQLite
      await WaterRepository.instance.saveMultipleWaterLogs(mergedWaterMap.values.toList());

      if (finalTodayCups > 0 || finalTodayMl > 0) {
        final waterDoc = doc.collection('water_logs').doc(todayStr);
        batch.set(waterDoc, {
          'date': todayStr,
          'volumeMl': finalTodayMl,
          'cups': finalTodayCups,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        opCount++;
        await commitBatchIfNeeded();
      }

      // 7. AI Chat Messages 2-Way Merge
      final localChats = await StorageService.getLocalChatHistory();
      final cloudChats = await getChatHistory();
      final Map<String, ChatMessage> chatMap = {};
      for (final c in cloudChats) {
        chatMap[c.id] = c;
      }
      for (final c in localChats) {
        if (!chatMap.containsKey(c.id)) {
          chatMap[c.id] = c;
          final chatDoc = doc.collection('ai_chat_history').doc(c.id);
          batch.set(chatDoc, c.toFirestore(), SetOptions(merge: true));
          opCount++;
          await commitBatchIfNeeded();
        }
      }
      final mergedChats = chatMap.values.toList();
      mergedChats.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await StorageService.saveMultipleLocalChatMessages(mergedChats);

      // 8. Body Measurements 2-Way Merge (Số đo cơ thể & % mỡ)
      try {
        final localMeasurements = await BodyMeasurementRepository.instance.getMeasurements();
        final cloudMeasurements = await getBodyMeasurements();
        final Map<String, BodyMeasurement> measurementMap = {};
        for (final m in cloudMeasurements) {
          measurementMap[m.id] = m;
        }
        for (final m in localMeasurements) {
          if (!measurementMap.containsKey(m.id)) {
            measurementMap[m.id] = m;
            final mDoc = doc.collection('body_measurements').doc(m.id);
            batch.set(mDoc, m.toMap(), SetOptions(merge: true));
            opCount++;
            await commitBatchIfNeeded();
          }
        }
        for (final m in measurementMap.values) {
          await BodyMeasurementRepository.instance.saveMeasurement(m, syncToFirestore: false);
        }
      } catch (e) {
        debugPrint('Sync body measurements error: $e');
      }

      // 9. Favorite Foods 2-Way Merge (Món ăn quen thuộc)
      try {
        final localFavorites = await NutritionRepository.instance.getFavoriteFoods();
        final cloudFavorites = await getFavoriteFoods();
        final Map<String, FavoriteFood> favoriteMap = {};
        for (final f in cloudFavorites) {
          favoriteMap[f.id] = f;
        }
        for (final f in localFavorites) {
          if (!favoriteMap.containsKey(f.id)) {
            favoriteMap[f.id] = f;
            final fDoc = doc.collection('favorite_foods').doc(f.id);
            batch.set(fDoc, f.toMap(), SetOptions(merge: true));
            opCount++;
            await commitBatchIfNeeded();
          }
        }
        for (final f in favoriteMap.values) {
          await NutritionRepository.instance.addFavoriteFood(f, syncToFirestore: false);
        }
      } catch (e) {
        debugPrint('Sync favorite foods error: $e');
      }

      // 10. Security settings sync (App lock)
      try {
        final cloudAppLock = await getAppLockSetting();
        if (cloudAppLock != null) {
          await prefs.setBool('biometric_app_lock_enabled', cloudAppLock);
        } else {
          final localAppLock = prefs.getBool('biometric_app_lock_enabled');
          if (localAppLock != null) {
            await saveAppLockSetting(localAppLock);
          }
        }
      } catch (e) {
        debugPrint('Sync app lock error: $e');
      }

      if (opCount > 0) {
        await batch.commit();
      }

      // 8. Tái tạo bộ nhớ đệm và phát tín hiệu cập nhật cho toàn bộ app
      StorageService.invalidateMemoryCaches();
      await StorageService.checkAndUpdateStreak();
      StorageService.notifyProfileChanged();
      StorageService.notifyWorkoutChanged();
      StorageService.notifyFoodChanged();
      StorageService.notifyWaterChanged();
      StorageService.notifyStepChanged();
      StorageService.notifyChatChanged();
      StorageService.notifyDataChanged();

      debugPrint('Đồng bộ 2 chiều (2-Way Sync) thành công giữa Local và Cloud Firestore ($opCount thao tác đám mây).');
    } catch (e) {
      debugPrint('Firestore syncOnLogin error: $e');
    }
  }
}
