import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/favorite_food.dart';
import '../models/food_log_entry.dart';
import '../services/firestore_service.dart';

/// Repository quản lý toàn bộ dữ liệu thực phẩm, dinh dưỡng và tính toán Macros (Protein/Carb/Fat).
/// Sử dụng SQLite để đạt hiệu năng O(1) và giảm thiểu hoàn toàn gánh nặng I/O của SharedPreferences.
class NutritionRepository {
  NutritionRepository._();
  static final NutritionRepository instance = NutritionRepository._();

  // In-memory cache ngày tháng phục vụ việc hiển thị Dashboard tức thì
  static Map<String, List<FoodLogEntry>>? cachedFoodByDate;

  /// Xóa sạch bộ nhớ cache ram
  static void invalidateCache() {
    cachedFoodByDate = null;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Thêm hoặc cập nhật một món ăn vào cơ sở dữ liệu SQLite và đồng bộ lên Firestore
  Future<void> saveFoodLog(FoodLogEntry entry) async {
    final dateStr = _formatDate(entry.timestamp);

    final db = await AppDatabase.instance.database;
    await db.insert(
      'food_entries',
      entry.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Cập nhật bộ nhớ cache ram (tránh trùng lặp)
    if (cachedFoodByDate != null) {
      final list = cachedFoodByDate!.putIfAbsent(dateStr, () => []);
      if (!list.any((e) => e.id == entry.id)) {
        list.insert(0, entry);
      }
    }

    // Đẩy lên Firestore
    FirestoreService().saveFoodLog(entry);
  }

  /// Lấy toàn bộ danh sách các món ăn đã ghi nhận trong hệ thống
  Future<List<FoodLogEntry>> getFoodLogs() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'food_entries',
      orderBy: 'timestamp DESC',
    );
    return results.map((row) => FoodLogEntry.fromJson(row)).toList();
  }

  /// Lấy danh sách món ăn đã nạp trong ngày hôm nay
  Future<List<FoodLogEntry>> getTodayFoodLogs() async {
    final todayStr = _formatDate(DateTime.now());
    return getFoodLogsByDateStr(todayStr);
  }

  /// Lấy danh sách món ăn theo đối tượng DateTime
  Future<List<FoodLogEntry>> getFoodLogsByDate(DateTime date) async {
    final dateStr = _formatDate(date);
    return getFoodLogsByDateStr(dateStr);
  }

  /// Lấy danh sách món ăn theo chuỗi ngày YYYY-MM-DD
  Future<List<FoodLogEntry>> getFoodLogsByDateStr(String dateStr) async {
    if (cachedFoodByDate != null && cachedFoodByDate!.containsKey(dateStr)) {
      return List.from(cachedFoodByDate![dateStr]!);
    }

    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'food_entries',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'timestamp DESC',
    );

    final list = results.map((row) => FoodLogEntry.fromJson(row)).toList();
    cachedFoodByDate ??= {};
    cachedFoodByDate![dateStr] = list;
    return list;
  }

  /// Xóa một món ăn theo ID
  Future<void> deleteFoodLog(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'food_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Cập nhật cache ram
    if (cachedFoodByDate != null) {
      for (final dateKey in cachedFoodByDate!.keys) {
        cachedFoodByDate![dateKey]!.removeWhere((item) => item.id == id);
      }
    }

    FirestoreService().deleteFoodLog(id);
  }

  /// Tổng calo nạp vào hôm nay
  Future<int> getTodayTotalCalories() async {
    final logs = await getTodayFoodLogs();
    int sum = 0;
    for (final e in logs) {
      sum += e.calories;
    }
    return sum;
  }

  /// Tổng protein nạp vào hôm nay (g)
  Future<int> getTodayTotalProtein() async {
    final logs = await getTodayFoodLogs();
    int sum = 0;
    for (final e in logs) {
      sum += e.protein;
    }
    return sum;
  }

  /// Tổng carbs nạp vào hôm nay (g)
  Future<int> getTodayTotalCarbs() async {
    final logs = await getTodayFoodLogs();
    int sum = 0;
    for (final e in logs) {
      sum += e.carbs;
    }
    return sum;
  }

  /// Tổng chất béo nạp vào hôm nay (g)
  Future<int> getTodayTotalFat() async {
    final logs = await getTodayFoodLogs();
    int sum = 0;
    for (final e in logs) {
      sum += e.fat;
    }
    return sum;
  }

  /// Lấy tổng lượng calo nạp vào của một ngày bất kỳ
  Future<int> getTotalCaloriesInByDate(DateTime date) async {
    final logs = await getFoodLogsByDate(date);
    int sum = 0;
    for (final e in logs) {
      sum += e.calories;
    }
    return sum;
  }

  /// Kiểm tra xem có món ăn nào trong ngày chỉ định không
  Future<bool> hasFoodOnDate(DateTime date) async {
    final logs = await getFoodLogsByDate(date);
    return logs.isNotEmpty;
  }

  /// Lưu hàng loạt món ăn vào SQLite (dùng cho 2-Way Sync khi đăng nhập)
  Future<void> saveMultipleFoodLogs(List<FoodLogEntry> entries) async {
    if (entries.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final e in entries) {
      batch.insert(
        'food_entries',
        e.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    invalidateCache();
  }

  /// Xóa sạch dữ liệu thực phẩm trong SQLite
  Future<void> clearAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('food_entries');
    await db.delete('favorite_foods');
    invalidateCache();
  }

  // ==========================================
  // PHIÊN BẢN 2.0: MÓN ĂN YÊU THÍCH (FAVORITES)
  // ==========================================

  /// Lấy danh sách toàn bộ món ăn ưa thích
  Future<List<FavoriteFood>> getFavoriteFoods() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'favorite_foods',
      orderBy: 'created_at DESC',
    );
    return results.map((row) => FavoriteFood.fromMap(row)).toList();
  }

  /// Thêm một món ăn vào danh mục ưa thích (lưu SQLite và đồng bộ Firestore)
  Future<void> addFavoriteFood(FavoriteFood food, {bool syncToFirestore = true}) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'favorite_foods',
      food.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (syncToFirestore) {
      await FirestoreService().saveFavoriteFood(food);
    }
  }

  /// Xóa một món ăn khỏi danh mục ưa thích (xóa SQLite và xóa trên Firestore)
  Future<void> deleteFavoriteFood(String id, {bool syncToFirestore = true}) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'favorite_foods',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (syncToFirestore) {
      await FirestoreService().deleteFavoriteFood(id);
    }
  }

  /// Kiểm tra xem món ăn theo tên đã có trong mục ưa thích chưa
  Future<bool> isFoodFavorite(String name) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'favorite_foods',
      where: 'LOWER(name) = ?',
      whereArgs: [name.trim().toLowerCase()],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Lấy món ăn ưa thích theo tên
  Future<FavoriteFood?> getFavoriteFoodByName(String name) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'favorite_foods',
      where: 'LOWER(name) = ?',
      whereArgs: [name.trim().toLowerCase()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return FavoriteFood.fromMap(results.first);
  }
}

