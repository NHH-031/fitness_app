import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database Manager quản lý kết nối SQLite cục bộ cho ứng dụng.
/// Thay thế việc lưu trữ toàn bộ logs vào SharedPreferences, tăng tốc độ đọc/ghi I/O O(1).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _database;
  static bool _ffiInitialized = false;

  /// Đảm bảo môi trường Desktop và Unit Test sử dụng SQLite FFI
  static void ensureFfiInitialized() {
    if (_ffiInitialized) return;
    if (!kIsWeb &&
        (Platform.isWindows ||
            Platform.isLinux ||
            Platform.isMacOS ||
            Platform.environment.containsKey('FLUTTER_TEST'))) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
  }

  /// Trả về instance Database đã sẵn sàng
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    ensureFfiInitialized();

    String dbPath;
    if (kIsWeb) {
      dbPath = 'fitness_tracker.db';
    } else if (Platform.environment.containsKey('FLUTTER_TEST')) {
      // Khi chạy flutter test, dùng database in-memory để kiểm thử nhanh và sạch
      return await databaseFactory.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, v) async {
              await _onCreate(db, v);
              await _createV2Tables(db);
            },
          ));
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, 'fitness_tracker.db');
    }

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, v) async {
        await _onCreate(db, v);
        await _createV2Tables(db);
      },
      onOpen: (db) async {
        await _createV2Tables(db);
        // Tự động kiểm tra và di chuyển dữ liệu cũ từ SharedPreferences sang SQLite
        await _migrateFromSharedPreferences(db);
      },
    );

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng lưu trữ lịch sử bài tập (WorkoutLog)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        duration INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        sets INTEGER,
        reps INTEGER,
        weight REAL,
        equipment TEXT,
        timestamp TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_date ON workout_logs (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_timestamp ON workout_logs (timestamp)');

    // 2. Bảng lưu trữ thực phẩm dinh dưỡng (FoodEntry)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_entries (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        carbs INTEGER NOT NULL,
        fat INTEGER NOT NULL,
        meal_type TEXT NOT NULL,
        image_path TEXT,
        timestamp TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_food_date ON food_entries (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_food_timestamp ON food_entries (timestamp)');

    // 3. Bảng lưu trữ lịch sử nước uống hàng ngày (DailyWaterHistory)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_water_history (
        date TEXT PRIMARY KEY,
        cups INTEGER NOT NULL,
        volume_ml INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Bảng lưu trữ tin nhắn hội thoại AI Coach (ChatMessage)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_timestamp ON chat_messages (timestamp)');
  }

  /// Di chuyển an toàn dữ liệu từ SharedPreferences sang SQLite khi nâng cấp lên Giai đoạn 3
  static Future<void> _migrateFromSharedPreferences(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const migrationFlag = 'sqlite_migrated_v1';
      if (prefs.getBool(migrationFlag) == true) {
        return; // Đã di chuyển xong trước đó
      }

      final batch = db.batch();

      // 1. Di chuyển Workout Logs cũ
      final oldWorkouts = prefs.getStringList('completed_workout_logs') ?? [];
      for (final raw in oldWorkouts) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          final timestamp = m['timestamp']?.toString() ?? DateTime.now().toIso8601String();
          final date = timestamp.split('T')[0];
          batch.insert(
            'workout_logs',
            {
              'title': m['title']?.toString() ?? 'Workout',
              'duration': (m['duration'] as num?)?.toInt() ?? 0,
              'calories': (m['calories'] as num?)?.toInt() ?? 0,
              'sets': (m['sets'] as num?)?.toInt(),
              'reps': (m['reps'] as num?)?.toInt(),
              'weight': (m['weight'] as num?)?.toDouble(),
              'equipment': m['equipment']?.toString(),
              'timestamp': timestamp,
              'date': date,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } catch (_) {}
      }

      // 2. Di chuyển Food Logs cũ
      final oldFoods = prefs.getStringList('user_food_logs') ?? [];
      for (final raw in oldFoods) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          final timestamp = m['timestamp']?.toString() ?? DateTime.now().toIso8601String();
          final date = timestamp.split('T')[0];
          batch.insert(
            'food_entries',
            {
              'id': m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'name': m['name']?.toString() ?? 'Food Item',
              'calories': (m['calories'] as num?)?.toInt() ?? 0,
              'protein': (m['protein'] as num?)?.toInt() ?? 0,
              'carbs': (m['carbs'] as num?)?.toInt() ?? 0,
              'fat': (m['fat'] as num?)?.toInt() ?? 0,
              'meal_type': m['mealType']?.toString() ?? 'Breakfast',
              'image_path': m['imagePath']?.toString(),
              'timestamp': timestamp,
              'date': date,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
      }

      // 3. Di chuyển Daily Water History cũ
      final oldWater = prefs.getStringList('daily_water_history') ?? [];
      for (final raw in oldWater) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          final date = m['date']?.toString();
          if (date != null && date.isNotEmpty) {
            batch.insert(
              'daily_water_history',
              {
                'date': date,
                'cups': (m['cups'] as num?)?.toInt() ?? 0,
                'volume_ml': (m['volumeMl'] as num?)?.toInt() ?? 0,
                'updated_at': m['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (_) {}
      }

      // 4. Di chuyển Chat History cũ
      final oldChat = prefs.getStringList('ai_chat_history') ?? [];
      for (final raw in oldChat) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          final id = m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          batch.insert(
            'chat_messages',
            {
              'id': id,
              'role': m['role']?.toString() ?? ((m['isUser'] == true) ? 'user' : 'model'),
              'text': m['text']?.toString() ?? '',
              'timestamp': m['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
      }

      await batch.commit(noResult: true);
      await prefs.setBool(migrationFlag, true);
    } catch (e) {
      debugPrint("Lỗi migration dữ liệu sang SQLite: $e");
    }
  }

  /// Khởi tạo các bảng mở rộng cho Fitness Tracker v2.0
  static Future<void> _createV2Tables(Database db) async {
    // 5. Bảng món ăn yêu thích (FavoriteFood) - Giai đoạn 1
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorite_foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        carbs INTEGER NOT NULL,
        fat INTEGER NOT NULL,
        serving_size TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fav_food_name ON favorite_foods (name)');

    // 6. Bảng theo dõi số đo cơ thể & body fat - Giai đoạn 4
    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_measurements (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight REAL,
        neck_cm REAL,
        chest_cm REAL,
        waist_cm REAL,
        hips_cm REAL,
        bicep_cm REAL,
        thigh_cm REAL,
        body_fat_percent REAL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_body_meas_date ON body_measurements (date)');

    // 7. Bảng hình ảnh tiến trình before/after - Giai đoạn 4
    await db.execute('''
      CREATE TABLE IF NOT EXISTS progress_photos (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        image_path TEXT NOT NULL,
        pose TEXT,
        weight REAL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prog_photo_date ON progress_photos (date)');
  }

  /// Xóa dữ liệu khi người dùng đăng xuất hoặc dọn dẹp app
  Future<void> clearAllUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('workout_logs');
      await txn.delete('food_entries');
      await txn.delete('daily_water_history');
      await txn.delete('chat_messages');
      await txn.delete('favorite_foods');
      await txn.delete('body_measurements');
      await txn.delete('progress_photos');
    });
  }

  /// Đóng kết nối database (dùng khi kiểm thử hoặc tắt app)
  static Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}

