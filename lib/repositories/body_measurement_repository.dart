import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/body_measurement.dart';

class BodyMeasurementRepository {
  BodyMeasurementRepository._();
  static final BodyMeasurementRepository instance = BodyMeasurementRepository._();

  /// Lưu hoặc cập nhật số đo cơ thể vào SQLite
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'body_measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy toàn bộ lịch sử các lần đo, mới nhất xếp trước
  Future<List<BodyMeasurement>> getMeasurements() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'body_measurements',
      orderBy: 'date DESC, created_at DESC',
    );
    return results.map((row) => BodyMeasurement.fromMap(row)).toList();
  }

  /// Lấy số đo cơ thể gần đây nhất
  Future<BodyMeasurement?> getLatestMeasurement() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'body_measurements',
      orderBy: 'date DESC, created_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return BodyMeasurement.fromMap(results.first);
  }

  /// Xóa bản ghi số đo theo ID
  Future<void> deleteMeasurement(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'body_measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa toàn bộ số đo
  Future<void> clearAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('body_measurements');
  }
}
