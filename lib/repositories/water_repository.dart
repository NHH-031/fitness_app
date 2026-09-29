import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/daily_water_log.dart';
import '../services/firestore_service.dart';

/// Repository quản lý toàn bộ dữ liệu nước uống, lịch sử ngày và nhắc nhở uống nước.
/// Tích hợp cơ sở dữ liệu SQLite bảng `daily_water_history` kết hợp SharedPreferences cho cấu hình.
class WaterRepository {
  WaterRepository._();
  static final WaterRepository instance = WaterRepository._();

  static const String _keyWaterReminderEnabled = 'water_reminder_enabled';
  static const String _keyWaterReminderInterval = 'water_reminder_interval';
  static const String _keyWaterCupsToday = 'water_cups_today';
  static const String _keyWaterVolumeMl = 'water_volume_ml_today';
  static const String _keyWaterDate = 'water_date';

  static String _formatDate([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  static String _normalizeDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return "$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
      }
    } catch (_) {}
    return dateStr;
  }

  /// Kiểm tra và tự động chốt sổ lịch sử nước ngày cũ, reset về 0 cho ngày mới
  Future<bool> checkAndResetWaterDaily({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(now);
    final rawSavedDate = prefs.getString(_keyWaterDate);
    final savedDate = rawSavedDate != null ? _normalizeDate(rawSavedDate) : null;

    if (savedDate == todayStr) {
      return false;
    }

    // Nếu đã có ngày lưu trước đó và khác hôm nay: Lưu vào SQLite ngày cũ
    if (savedDate != null && savedDate.isNotEmpty && savedDate != todayStr) {
      final oldCups = prefs.getInt(_keyWaterCupsToday) ?? 0;
      final oldMl = prefs.getInt(_keyWaterVolumeMl) ?? (oldCups * 250);
      await archiveWaterLog(
        dateStr: savedDate,
        cups: oldCups,
        volumeMl: oldMl,
      );
    }

    // Đọc lịch sử đã có trong SQLite cho ngày hôm nay nếu có
    final todayDbLog = await getWaterLogByDateStr(todayStr);
    final existingHistoryCups = todayDbLog?.cups ?? 0;
    final existingHistoryMl = todayDbLog?.volumeMl ?? (existingHistoryCups * 250);

    final currentCupsToday = prefs.getInt(_keyWaterCupsToday) ?? 0;
    final currentMlToday = prefs.getInt(_keyWaterVolumeMl) ?? 0;

    int resolvedCups = 0;
    int resolvedMl = 0;

    if (savedDate != null && savedDate != todayStr) {
      // Ngày mới thật sự lúc 0h
      resolvedCups = existingHistoryCups;
      resolvedMl = existingHistoryMl > 0 ? existingHistoryMl : (resolvedCups * 250);
    } else {
      // savedDate == null: Bảo toàn dữ liệu hiện có
      resolvedCups = max(currentCupsToday, existingHistoryCups);
      resolvedMl = max(currentMlToday, resolvedCups * 250);
    }

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterCupsToday, resolvedCups);
    await prefs.setInt(_keyWaterVolumeMl, resolvedMl);

    if (resolvedCups > 0) {
      await archiveWaterLog(
        dateStr: todayStr,
        cups: resolvedCups,
        volumeMl: resolvedMl,
      );
    }

    return true;
  }

  /// Ghi nhận bản ghi nước uống vào SQLite và đồng bộ Cloud Firestore
  Future<void> archiveWaterLog({
    required String dateStr,
    required int cups,
    required int volumeMl,
  }) async {
    final log = DailyWaterLog(
      date: dateStr,
      cups: cups,
      volumeMl: volumeMl,
      updatedAt: DateTime.now(),
    );

    final db = await AppDatabase.instance.database;
    await db.insert(
      'daily_water_history',
      log.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Đồng bộ tức thì lên Cloud Firestore
    FirestoreService().saveWaterData(dateStr, volumeMl, cups);
  }

  /// Lấy toàn bộ lịch sử các ngày uống nước từ SQLite
  Future<List<DailyWaterLog>> getWaterHistoryLogs() async {
    await checkAndResetWaterDaily();
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'daily_water_history',
      orderBy: 'date DESC',
      limit: 60,
    );
    return results.map((row) => DailyWaterLog.fromJson(row)).toList();
  }

  /// Lấy bản ghi nước uống theo chuỗi ngày YYYY-MM-DD
  Future<DailyWaterLog?> getWaterLogByDateStr(String dateStr) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'daily_water_history',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DailyWaterLog.fromJson(results.first);
  }

  /// Số cốc nước uống hôm nay
  Future<int> getWaterCupsToday() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWaterCupsToday) ?? 0;
  }

  /// Thể tích nước uống hôm nay (ml)
  Future<int> getTodayWaterVolume() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyWaterVolumeMl)) {
      int cups = prefs.getInt(_keyWaterCupsToday) ?? 0;
      int initialMl = cups * 250;
      await prefs.setInt(_keyWaterVolumeMl, initialMl);
      return initialMl;
    }
    return prefs.getInt(_keyWaterVolumeMl) ?? 0;
  }

  /// Thêm cốc nước hôm nay (+1 cốc = +250ml)
  Future<int> addWaterCup() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    int current = prefs.getInt(_keyWaterCupsToday) ?? 0;
    current++;
    final volumeMl = current * 250;

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterCupsToday, current);
    await prefs.setInt(_keyWaterVolumeMl, volumeMl);

    await archiveWaterLog(
      dateStr: todayStr,
      cups: current,
      volumeMl: volumeMl,
    );

    return current;
  }

  /// Bớt cốc nước hôm nay
  Future<int> removeWaterCup() async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    int current = prefs.getInt(_keyWaterCupsToday) ?? 0;
    if (current > 0) {
      current--;
      final volumeMl = current * 250;
      await prefs.setString(_keyWaterDate, todayStr);
      await prefs.setInt(_keyWaterCupsToday, current);
      await prefs.setInt(_keyWaterVolumeMl, volumeMl);

      await archiveWaterLog(
        dateStr: todayStr,
        cups: current,
        volumeMl: volumeMl,
      );
    }
    return current;
  }

  /// Thêm thể tích nước (ml)
  Future<int> addWaterVolume(int ml) async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    int current = prefs.getInt(_keyWaterVolumeMl) ?? 0;
    current = (current + ml).clamp(0, 10000);
    int cups = (current / 250).ceil();

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterVolumeMl, current);
    await prefs.setInt(_keyWaterCupsToday, cups);

    await archiveWaterLog(
      dateStr: todayStr,
      cups: cups,
      volumeMl: current,
    );

    return current;
  }

  /// Bớt thể tích nước (ml)
  Future<int> removeWaterVolume(int ml) async {
    await checkAndResetWaterDaily();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    int current = prefs.getInt(_keyWaterVolumeMl) ?? 0;
    current = (current - ml).clamp(0, 10000);
    int cups = (current / 250).ceil();

    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterVolumeMl, current);
    await prefs.setInt(_keyWaterCupsToday, cups);

    await archiveWaterLog(
      dateStr: todayStr,
      cups: cups,
      volumeMl: current,
    );

    return current;
  }

  /// Reset nước hôm nay về 0
  Future<void> resetWaterVolume() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate();
    await prefs.setString(_keyWaterDate, todayStr);
    await prefs.setInt(_keyWaterVolumeMl, 0);
    await prefs.setInt(_keyWaterCupsToday, 0);

    await archiveWaterLog(
      dateStr: todayStr,
      cups: 0,
      volumeMl: 0,
    );
  }

  /// Thêm cốc nước cho ngày chỉ định
  Future<int> addWaterCupForDate(DateTime date) async {
    final dateStr = _formatDate(date);
    if (dateStr == _formatDate()) {
      return await addWaterCup();
    }
    int current = await getWaterCupsByDate(date);
    current++;
    final volumeMl = current * 250;
    await archiveWaterLog(
      dateStr: dateStr,
      cups: current,
      volumeMl: volumeMl,
    );
    return current;
  }

  /// Bớt cốc nước cho ngày chỉ định
  Future<int> removeWaterCupForDate(DateTime date) async {
    final dateStr = _formatDate(date);
    if (dateStr == _formatDate()) {
      return await removeWaterCup();
    }
    int current = await getWaterCupsByDate(date);
    if (current > 0) {
      current--;
      final volumeMl = current * 250;
      await archiveWaterLog(
        dateStr: dateStr,
        cups: current,
        volumeMl: volumeMl,
      );
    }
    return current;
  }

  /// Lấy số cốc nước theo ngày
  Future<int> getWaterCupsByDate(DateTime date) async {
    final dateStr = _formatDate(date);
    final isToday = dateStr == _formatDate();
    if (isToday) {
      return await getWaterCupsToday();
    }
    final log = await getWaterLogByDateStr(dateStr);
    return log?.cups ?? 0;
  }

  /// Lấy thể tích nước (ml) theo ngày
  Future<int> getWaterVolumeByDate(DateTime date) async {
    final dateStr = _formatDate(date);
    final isToday = dateStr == _formatDate();
    if (isToday) {
      return await getTodayWaterVolume();
    }
    final log = await getWaterLogByDateStr(dateStr);
    return log?.volumeMl ?? ((log?.cups ?? 0) * 250);
  }

  // --- CẤU HÌNH NHẮC NHỞ UỐNG NƯỚC ---
  Future<bool> getWaterReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWaterReminderEnabled) ?? true;
  }

  Future<void> setWaterReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWaterReminderEnabled, enabled);
  }

  Future<int> getWaterReminderInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWaterReminderInterval) ?? 60;
  }

  Future<void> setWaterReminderInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWaterReminderInterval, minutes);
  }

  /// Lưu hàng loạt bản ghi lịch sử nước vào SQLite (dùng cho 2-Way Sync khi đăng nhập)
  Future<void> saveMultipleWaterLogs(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final item in logs) {
      final date = item['date']?.toString();
      if (date != null && date.isNotEmpty) {
        batch.insert(
          'daily_water_history',
          {
            'date': date,
            'cups': (item['cups'] as num?)?.toInt() ?? 0,
            'volume_ml': (item['volumeMl'] as num?)?.toInt() ?? 0,
            'updated_at': item['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  /// Xóa sạch dữ liệu nước uống
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWaterCupsToday);
    await prefs.remove(_keyWaterVolumeMl);
    await prefs.remove(_keyWaterDate);
    final db = await AppDatabase.instance.database;
    await db.delete('daily_water_history');
  }
}
