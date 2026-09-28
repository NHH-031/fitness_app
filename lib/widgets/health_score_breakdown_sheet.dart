import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../screens/main_screen.dart';
import 'health_score_widget.dart';
import 'app_ui_components.dart';

class HealthScoreBreakdownSheet extends StatefulWidget {
  final int currentSteps;
  final DateTime? date;

  const HealthScoreBreakdownSheet({
    super.key,
    this.currentSteps = 0,
    this.date,
  });

  static void show(
    BuildContext context, {
    int currentSteps = 0,
    DateTime? date,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => HealthScoreBreakdownSheet(
        currentSteps: currentSteps,
        date: date,
      ),
    );
  }

  @override
  State<HealthScoreBreakdownSheet> createState() => _HealthScoreBreakdownSheetState();
}

class _HealthScoreBreakdownSheetState extends State<HealthScoreBreakdownSheet> {
  HealthScoreBreakdown? _breakdown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScoreData();
    StorageService.dataUpdateNotifier.addListener(_loadScoreData);
  }

  @override
  void dispose() {
    StorageService.dataUpdateNotifier.removeListener(_loadScoreData);
    super.dispose();
  }

  Future<void> _loadScoreData() async {
    final targetDate = widget.date ?? DateTime.now();
    final now = DateTime.now();
    final bool isToday = targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    final userProfile = await StorageService.getUserProfile();
    final caloriesIn = await StorageService.getTotalCaloriesInByDate(targetDate);
    final macros = await StorageService.getTotalMacrosByDate(targetDate);
    final workoutMinutes = await StorageService.getWorkoutMinutesByDate(targetDate);
    final workoutLogs = await StorageService.getWorkoutLogsByDate(targetDate);
    final waterCups = await StorageService.getWaterCupsByDate(targetDate);
    final streak = await StorageService.getCurrentStreak();

    int effectiveSteps = widget.currentSteps;
    if (!isToday) {
      effectiveSteps = await StorageService.getStepsByDate(targetDate);
    }

    final breakdown = HealthScoreCalculator.evaluate(
      currentSteps: effectiveSteps,
      goalSteps: 10000,
      caloriesIn: caloriesIn,
      targetCalories: userProfile.targetCalories,
      proteinGrams: macros['protein'] ?? 0,
      targetProtein: userProfile.targetProtein,
      workoutMinutes: workoutMinutes,
      workoutCount: workoutLogs.length,
      waterCups: waterCups,
      streakDays: streak,
    );

    if (mounted) {
      setState(() {
        _breakdown = breakdown;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _breakdown;
    final isVi = LocaleService.isVietnamese;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF10131E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2C3248), width: 1.5),
          left: BorderSide(color: Color(0xFF2C3248), width: 1.5),
          right: BorderSide(color: Color(0xFF2C3248), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const BottomSheetDragHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (breakdown?.statusColor ?? Colors.redAccent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (breakdown?.statusColor ?? Colors.redAccent).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: breakdown?.statusColor ?? Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('health_score_breakdown_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVi
                            ? 'Đánh giá 4 trụ cột lối sống hôm nay'
                            : '4-pillar lifestyle evaluation today',
                        style: const TextStyle(
                          color: Color(0xFF8E95A9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E2438), height: 1),

          // Content body
          Expanded(
            child: _isLoading || breakdown == null
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Score Gauge Hero Card
                      _buildScoreGaugeCard(breakdown),

                      const SizedBox(height: 16),

                      // Smart Advice & Reminder Card
                      _buildSmartAdviceCard(breakdown),

                      const SizedBox(height: 20),

                      // Section Title
                      Text(
                        isVi ? 'CHI TIẾT 4 TRỤ CỘT ĐIỂM SỐ' : '4 PILLARS BREAKDOWN',
                        style: const TextStyle(
                          color: Color(0xFF8E95A9),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pillar 1: Nutrition (35 pts)
                      _buildPillarCard(
                        icon: Icons.restaurant,
                        title: LocaleService.tr('health_pillar_nutrition'),
                        score: breakdown.nutritionScore,
                        maxScore: 35,
                        color: const Color(0xFF00E5FF),
                        detailText: isVi
                            ? 'Nạp: ${breakdown.caloriesIn} / ${breakdown.targetCalories} kcal • Đạm: ${breakdown.proteinGrams}g'
                            : 'In: ${breakdown.caloriesIn} / ${breakdown.targetCalories} kcal • Protein: ${breakdown.proteinGrams}g',
                        note: breakdown.caloriesIn == 0
                            ? (isVi ? 'Chưa ghi nhật ký món ăn hôm nay' : 'No food logged today')
                            : (breakdown.caloriesIn > breakdown.targetCalories * 1.25
                                ? (isVi ? 'Đang thặng dư calo' : 'Calorie surplus')
                                : (isVi ? 'Năng lượng kiểm soát tốt' : 'Calorie pace on track')),
                      ),

                      const SizedBox(height: 12),

                      // Pillar 2: Physical Exercise (35 pts)
                      _buildPillarCard(
                        icon: Icons.fitness_center,
                        title: LocaleService.tr('health_pillar_workout'),
                        score: breakdown.workoutScore,
                        maxScore: 35,
                        color: const Color(0xFFFF9500),
                        detailText: isVi
                            ? '${breakdown.workoutMinutes} phút tập luyện • ${breakdown.workoutCount} buổi tập'
                            : '${breakdown.workoutMinutes} mins active • ${breakdown.workoutCount} workouts',
                        note: breakdown.workoutMinutes >= 30
                            ? (isVi ? 'Đạt chuẩn rèn luyện thể chất WHO' : 'Met WHO daily active target')
                            : (breakdown.workoutMinutes > 0
                                ? (isVi ? 'Đã khởi động thể lực' : 'Good physical start')
                                : (isVi ? 'Chưa có buổi tập nào hôm nay' : 'No workouts logged today')),
                      ),

                      const SizedBox(height: 12),

                      // Pillar 3: Daily Steps (20 pts)
                      _buildPillarCard(
                        icon: Icons.directions_walk,
                        title: LocaleService.tr('health_pillar_steps'),
                        score: breakdown.stepScore,
                        maxScore: 20,
                        color: const Color(0xFF00FFA3),
                        detailText: isVi
                            ? '${breakdown.currentSteps} / ${breakdown.goalSteps} bước • ~${(breakdown.currentSteps * 0.04).round()} kcal'
                            : '${breakdown.currentSteps} / ${breakdown.goalSteps} steps • ~${(breakdown.currentSteps * 0.04).round()} kcal',
                        note: breakdown.currentSteps >= breakdown.goalSteps
                            ? (isVi ? 'Đã chinh phục 10k bước!' : '10k step milestone conquered!')
                            : (isVi
                                ? 'Đạt ${(breakdown.currentSteps / breakdown.goalSteps * 100).round()}% mục tiêu bước chân'
                                : '${(breakdown.currentSteps / breakdown.goalSteps * 100).round()}% of daily goal'),
                      ),

                      const SizedBox(height: 12),

                      // Pillar 4: Hydration & Habits (10 pts)
                      _buildPillarCard(
                        icon: Icons.water_drop,
                        title: LocaleService.tr('health_pillar_habits'),
                        score: breakdown.habitScore,
                        maxScore: 10,
                        color: const Color(0xFF38BDF8),
                        detailText: isVi
                            ? '${breakdown.waterCups} cốc nước (${breakdown.waterCups * 250} ml) • Chuỗi: ${breakdown.streakDays} ngày'
                            : '${breakdown.waterCups} cups (${breakdown.waterCups * 250} ml) • Streak: ${breakdown.streakDays} days',
                        note: breakdown.waterCups >= 8
                            ? (isVi ? 'Đủ nước cho ngày dài năng động' : 'Fully hydrated')
                            : (isVi ? 'Mục tiêu 8 cốc nước/ngày' : 'Target: 8 cups/day'),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
          ),

          // Bottom Quick Navigation Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF141927),
              border: Border(top: BorderSide(color: Color(0xFF1E2438), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      MainScreen.switchTab(1); // Workout tab
                    },
                    icon: const Icon(Icons.fitness_center, size: 18, color: Color(0xFFFF9500)),
                    label: Text(
                      LocaleService.tr('health_action_workout'),
                      style: const TextStyle(
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF9500), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFF0072FF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        MainScreen.switchTab(2); // Food tab
                      },
                      icon: const Icon(Icons.restaurant, size: 18, color: Colors.black),
                      label: Text(
                        LocaleService.tr('health_action_food'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGaugeCard(HealthScoreBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B2B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: breakdown.statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: breakdown.statusColor.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Indicator with score
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: (breakdown.totalScore / 100.0).clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(breakdown.statusColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      breakdown.totalScore.toString(),
                      style: TextStyle(
                        color: breakdown.statusColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Status text and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: breakdown.statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: breakdown.statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    breakdown.statusText,
                    style: TextStyle(
                      color: breakdown.statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleService.isVietnamese
                      ? 'Điểm tổng hợp từ cân bằng calo, hoạt động thể chất và lối sống hàng ngày.'
                      : 'Comprehensive score computed from calorie balance, workouts, and daily habits.',
                  style: const TextStyle(
                    color: Color(0xFF9AA2B8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAdviceCard(HealthScoreBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: breakdown.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: breakdown.statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(breakdown.adviceIcon, color: breakdown.statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleService.isVietnamese ? 'LỜI KHUYÊN DÀNH CHO BẠN' : 'SMART RECOMMENDATION',
                  style: TextStyle(
                    color: breakdown.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  breakdown.adviceText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required String title,
    required int score,
    required int maxScore,
    required Color color,
    required String detailText,
    required String note,
  }) {
    final double ratio = (score / maxScore).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242A40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '/$maxScore',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  detailText,
                  style: const TextStyle(color: Color(0xFF8E95A9), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                note,
                style: TextStyle(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
