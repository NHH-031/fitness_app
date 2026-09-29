import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../services/firestore_service.dart';

/// Repository quản lý toàn bộ dữ liệu bài tập và lịch sử rèn luyện (Workout).
/// Sử dụng SQLite cục bộ giúp truy vấn O(1) theo chỉ mục ngày tháng và đồng bộ Firestore.
class WorkoutRepository {
  WorkoutRepository._();
  static final WorkoutRepository instance = WorkoutRepository._();

  // In-memory cache ngày tháng để tăng tốc render UI
  static Map<String, List<Map<String, dynamic>>>? _cachedWorkoutsByDate;

  /// Xóa sạch bộ nhớ đệm ram
  static void invalidateCache() {
    _cachedWorkoutsByDate = null;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Ghi nhận buổi tập đã hoàn thành vào SQLite và đồng bộ lên Cloud Firestore
  Future<void> logCompletedWorkout({
    required int durationMinutes,
    required String title,
    int? calories,
    int? sets,
    int? reps,
    double? weightKg,
    String? equipment,
    DateTime? timestamp,
  }) async {
    final time = timestamp ?? DateTime.now();
    final dateStr = _formatDate(time);
    final calculatedCalories = calories ?? (durationMinutes * 7);

    final workoutMap = <String, dynamic>{
      'title': title,
      'duration': durationMinutes,
      'calories': calculatedCalories,
      'sets': ?sets,
      'reps': ?reps,
      'weight': ?weightKg,
      'equipment': ?equipment,
      'timestamp': time.toIso8601String(),
      'date': dateStr,
    };

    final db = await AppDatabase.instance.database;
    await db.insert(
      'workout_logs',
      workoutMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Cập nhật in-memory cache
    if (_cachedWorkoutsByDate != null) {
      _cachedWorkoutsByDate!.putIfAbsent(dateStr, () => []).insert(0, workoutMap);
    }

    // Đẩy lên Cloud Firestore
    FirestoreService().saveWorkoutLog(workoutMap);
  }

  /// Lấy toàn bộ lịch sử các buổi tập, sắp xếp mới nhất lên đầu
  Future<List<Map<String, dynamic>>> getWorkoutLogs() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'workout_logs',
      orderBy: 'timestamp DESC',
    );
    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Lấy danh sách các bài tập đã hoàn thành trong ngày hôm nay
  Future<List<Map<String, dynamic>>> getTodayWorkoutLogs() async {
    final todayStr = _formatDate(DateTime.now());
    return getWorkoutLogsByDateStr(todayStr);
  }

  /// Lấy các bài tập theo đối tượng DateTime
  Future<List<Map<String, dynamic>>> getWorkoutLogsByDate(DateTime date) async {
    final dateStr = _formatDate(date);
    return getWorkoutLogsByDateStr(dateStr);
  }

  /// Lấy các bài tập theo chuỗi YYYY-MM-DD (tận dụng SQL Index)
  Future<List<Map<String, dynamic>>> getWorkoutLogsByDateStr(String dateStr) async {
    if (_cachedWorkoutsByDate != null && _cachedWorkoutsByDate!.containsKey(dateStr)) {
      return List.from(_cachedWorkoutsByDate![dateStr]!);
    }

    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'workout_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'timestamp DESC',
    );

    final list = results.map((row) => Map<String, dynamic>.from(row)).toList();
    _cachedWorkoutsByDate ??= {};
    _cachedWorkoutsByDate![dateStr] = list;
    return list;
  }

  /// Xóa một bản ghi bài tập theo timestamp
  Future<void> deleteWorkoutLog(String timestamp) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'workout_logs',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );

    // Cập nhật lại cache ram
    if (_cachedWorkoutsByDate != null) {
      for (final dateKey in _cachedWorkoutsByDate!.keys) {
        _cachedWorkoutsByDate![dateKey]!.removeWhere((m) => m['timestamp'] == timestamp);
      }
    }

    FirestoreService().deleteWorkoutLog(timestamp);
  }

  /// Tổng calo đốt cháy từ các bài tập trong hôm nay
  Future<int> getTodayWorkoutsCalories() async {
    final todayLogs = await getTodayWorkoutLogs();
    int sum = 0;
    for (final log in todayLogs) {
      final cal = (log['calories'] as num?)?.toInt() ??
          (((log['duration'] as num?)?.toInt() ?? 0) * 7);
      sum += cal;
    }
    return sum;
  }

  /// Tổng thời gian tập luyện trong hôm nay (phút)
  Future<int> getTodayWorkoutsMinutes() async {
    final todayLogs = await getTodayWorkoutLogs();
    int sum = 0;
    for (final log in todayLogs) {
      sum += (log['duration'] as num?)?.toInt() ?? 0;
    }
    return sum;
  }

  /// Kiểm tra xem có bài tập nào vào ngày chỉ định không
  Future<bool> hasWorkoutsOnDate(DateTime date) async {
    final logs = await getWorkoutLogsByDate(date);
    return logs.isNotEmpty;
  }

  /// Lưu hàng loạt bài tập vào SQLite (dùng cho 2-Way Sync khi đăng nhập)
  Future<void> saveMultipleWorkoutLogs(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final w in logs) {
      final timestamp = w['timestamp']?.toString() ?? DateTime.now().toIso8601String();
      final date = w['date']?.toString() ?? timestamp.split('T')[0];
      batch.insert(
        'workout_logs',
        {
          'title': w['title']?.toString() ?? 'Workout',
          'duration': (w['duration'] as num?)?.toInt() ?? 0,
          'calories': (w['calories'] as num?)?.toInt() ?? 0,
          'sets': (w['sets'] as num?)?.toInt(),
          'reps': (w['reps'] as num?)?.toInt(),
          'weight': (w['weight'] as num?)?.toDouble(),
          'equipment': w['equipment']?.toString(),
          'timestamp': timestamp,
          'date': date,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    invalidateCache();
  }

  /// Xóa sạch dữ liệu bài tập trong bảng SQLite
  Future<void> clearAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('workout_logs');
    invalidateCache();
  }
}
