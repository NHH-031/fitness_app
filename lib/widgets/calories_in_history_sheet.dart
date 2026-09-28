import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../screens/main_screen.dart';
import 'app_ui_components.dart';

class CaloriesInHistorySheet extends StatefulWidget {
  final DateTime? date;

  const CaloriesInHistorySheet({
    super.key,
    this.date,
  });

  static void show(BuildContext context, {DateTime? date}) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => CaloriesInHistorySheet(date: date),
    );
  }

  @override
  State<CaloriesInHistorySheet> createState() => _CaloriesInHistorySheetState();
}

class _CaloriesInHistorySheetState extends State<CaloriesInHistorySheet> {
  List<FoodLogEntry> _foods = [];
  Map<String, int> _macros = {'protein': 0, 'carbs': 0, 'fat': 0};
  int _totalCalories = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    StorageService.foodUpdateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    StorageService.foodUpdateNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final targetDate = widget.date ?? DateTime.now();
    final foods = await StorageService.getFoodLogsByDate(targetDate);
    final macros = await StorageService.getTotalMacrosByDate(targetDate);
    final total = await StorageService.getTotalCaloriesInByDate(targetDate);
    if (mounted) {
      setState(() {
        _foods = foods;
        _macros = macros;
        _totalCalories = total;
        _isLoading = false;
      });
    }
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
      case 'bữa sáng':
        return const Color(0xFFFFB300);
      case 'lunch':
      case 'bữa trưa':
        return const Color(0xFF00E676);
      case 'dinner':
      case 'bữa tối':
        return const Color(0xFF7C4DFF);
      case 'snack':
      case 'bữa phụ':
      default:
        return const Color(0xFF00F0FF);
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
      case 'bữa sáng':
        return Icons.wb_sunny_rounded;
      case 'lunch':
      case 'bữa trưa':
        return Icons.lunch_dining_rounded;
      case 'dinner':
      case 'bữa tối':
        return Icons.nightlight_round;
      case 'snack':
      case 'bữa phụ':
      default:
        return Icons.eco_rounded;
    }
  }

  String _formatMealDisplayName(String mealType) {
    if (!LocaleService.isVietnamese) return mealType;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Bữa Sáng';
      case 'lunch':
        return 'Bữa Trưa';
      case 'dinner':
        return 'Bữa Tối';
      case 'snack':
        return 'Bữa Phụ';
      default:
        return mealType;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _confirmDelete(FoodLogEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocaleService.isVietnamese ? 'Xóa món ăn?' : 'Delete food item?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          LocaleService.isVietnamese
              ? 'Bạn có chắc chắn muốn xóa món "${entry.name}" (${entry.calories} kcal) khỏi nhật ký dinh dưỡng hôm nay?'
              : 'Are you sure you want to remove "${entry.name}" (${entry.calories} kcal) from today\'s food log?',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              LocaleService.isVietnamese ? 'Hủy' : 'Cancel',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              LocaleService.isVietnamese ? 'Xóa' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteFoodLog(entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleService.isVietnamese
                ? 'Đã xóa món "${entry.name}"'
                : 'Removed "${entry.name}"',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E1E2C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToFoodTab() {
    Navigator.of(context).pop();
    MainScreen.switchTab(2); // Tab 2 is FoodScreen
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF12121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            const BottomSheetDragHandle(),

            // Top Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Color(0xFF00F0FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleService.isVietnamese
                              ? 'LỊCH SỬ NẠP CALO HÔM NAY'
                              : 'TODAY\'S CALORIE INTAKE',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocaleService.isVietnamese
                              ? 'Chi tiết các món ăn & năng lượng đã nạp'
                              : 'Detailed breakdown of meals and energy logged',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Total Calo & Macro Summary Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      const Color(0xFF0072FF).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocaleService.isVietnamese ? 'TỔNG NĂNG LƯỢNG NẠP' : 'TOTAL ENERGY IN',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white60,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_totalCalories kcal',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00F0FF),
                              ),
                            ),
                          ],
                        ),
                        // Quick Action Button: Go to Food Tab
                        InkWell(
                          onTap: _navigateToFoodTab,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_circle_outline_rounded,
                                    color: Color(0xFF00F0FF), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  LocaleService.isVietnamese ? 'Thêm món' : 'Log Food',
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Macro row
                    Row(
                      children: [
                        _buildMacroPill(
                          label: LocaleService.isVietnamese ? 'Đạm' : 'Protein',
                          value: '${_macros['protein'] ?? 0}g',
                          color: const Color(0xFFFF5252),
                        ),
                        const SizedBox(width: 8),
                        _buildMacroPill(
                          label: LocaleService.isVietnamese ? 'Tinh bột' : 'Carbs',
                          value: '${_macros['carbs'] ?? 0}g',
                          color: const Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 8),
                        _buildMacroPill(
                          label: LocaleService.isVietnamese ? 'Chất béo' : 'Fat',
                          value: '${_macros['fat'] ?? 0}g',
                          color: const Color(0xFF00E676),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Content List or Empty State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                    )
                  : _foods.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _foods.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = _foods[index];
                            final mealColor = _getMealColor(entry.mealType);
                            final mealIcon = _getMealIcon(entry.mealType);
                            final mealName = _formatMealDisplayName(entry.mealType);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1B26),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Meal Type Icon
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: mealColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(mealIcon, color: mealColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  // Food info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: mealColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                mealName,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: mealColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatTime(entry.timestamp),
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.white38,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${entry.protein}g Protein • ${entry.carbs}g Carbs • ${entry.fat}g Fat',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Calories & Delete
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '+${entry.calories}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF00F0FF),
                                        ),
                                      ),
                                      const Text(
                                        'kcal',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(entry),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white38,
                                      size: 18,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.only(left: 4),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Bottom Full Switch Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _navigateToFoodTab,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    LocaleService.isVietnamese
                        ? 'ĐẾN TRANG NHẬT KÝ DINH DƯỠNG'
                        : 'GO TO NUTRITION DIARY',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_meals_rounded,
                color: Color(0xFF00F0FF),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleService.isVietnamese
                  ? 'Chưa ghi nhận món ăn nào hôm nay'
                  : 'No food items logged yet today',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              LocaleService.isVietnamese
                  ? 'Chụp ảnh món ăn với Gemini AI hoặc thêm nhanh bữa ăn tại trang Dinh dưỡng để bắt đầu theo dõi thâm hụt calo!'
                  : 'Snap a meal photo with Gemini AI or quickly log dishes on the Nutrition tab!',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigateToFoodTab,
              icon: const Icon(Icons.camera_alt_rounded, size: 16),
              label: Text(
                LocaleService.isVietnamese ? 'Thêm món ăn ngay' : 'Log Food Now',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
