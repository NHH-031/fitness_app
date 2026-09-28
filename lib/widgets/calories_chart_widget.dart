import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import 'chart_history_sheet.dart';
import 'weekly_calorie_bar_chart.dart';
import 'weight_journey_chart.dart';
import 'app_ui_components.dart';

class CaloriesChartWidget extends StatefulWidget {
  final int currentSteps;
  final DateTime? selectedDate;

  const CaloriesChartWidget({
    super.key,
    this.currentSteps = 0,
    this.selectedDate,
  });

  @override
  State<CaloriesChartWidget> createState() => _CaloriesChartWidgetState();
}

class _CaloriesChartWidgetState extends State<CaloriesChartWidget> {
  int _totalBurned = 0;
  int _totalIntake = 0;
  int _bmrBurned = 0;
  int _stepsBurned = 0;
  int _workoutBurned = 0;
  double _userBmr = 1678.0;

  List<FoodLogEntry> _todayFoods = [];
  List<Map<String, dynamic>> _todayWorkouts = [];

  String _selectedTab = '24h'; // '24h', 'week', 'weight'

  Timer? _realtimeTimer;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _recalculateCalories();
    StorageService.dataUpdateNotifier.addListener(_recalculateCalories);

    // Tự động làm mới thời gian thực mỗi 30 giây để cập nhật tích lũy BMR và giờ hiện tại
    _realtimeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final targetDate = widget.selectedDate ?? DateTime.now();
      if (mounted && _isToday(targetDate)) {
        _recalculateCalories();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CaloriesChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSteps != widget.currentSteps ||
        oldWidget.selectedDate != widget.selectedDate) {
      _recalculateCalories();
    }
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    StorageService.dataUpdateNotifier.removeListener(_recalculateCalories);
    super.dispose();
  }

  Future<void> _recalculateCalories() async {
    final targetDate = widget.selectedDate ?? DateTime.now();
    final bool isToday = _isToday(targetDate);
    final now = DateTime.now();

    final joinedDate = await StorageService.getUserJoinedDate();
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final hasActivity = await StorageService.hasActivityOnDate(targetDate);
    final bool isBeforeJoined = targetDay.isBefore(joinedDate);

    // Nếu là ngày quá khứ trước khi tham gia hoặc không có bất kỳ hoạt động nào -> Đặt toàn bộ về 0
    if (!isToday && (isBeforeJoined || !hasActivity)) {
      if (mounted) {
        setState(() {
          _userBmr = 0;
          _todayFoods = [];
          _todayWorkouts = [];
          _bmrBurned = 0;
          _stepsBurned = 0;
          _workoutBurned = 0;
          _totalBurned = 0;
          _totalIntake = 0;
        });
      }
      return;
    }

    final double fractionOfDay = isToday
        ? ((now.hour * 60 + now.minute) / 1440.0).clamp(0.05, 1.0)
        : 1.0;

    final userProfile = await StorageService.getUserProfile();
    final double personalBmr = userProfile.bmr;

    final foods = await StorageService.getFoodLogsByDate(targetDate);
    final workouts = await StorageService.getWorkoutLogsByDate(targetDate);

    final int cin = await StorageService.getTotalCaloriesInByDate(targetDate);
    final int bmrAccumulated = (personalBmr * fractionOfDay).round();

    int effectiveSteps = widget.currentSteps;
    if (!isToday) {
      effectiveSteps = await StorageService.getStepsByDate(targetDate);
    }
    final int stepsCal = (effectiveSteps * 0.04).round();
    final int workoutsCal = await StorageService.getWorkoutCaloriesByDate(targetDate);
    final int totalOut = bmrAccumulated + stepsCal + workoutsCal;

    if (mounted) {
      setState(() {
        _userBmr = personalBmr;
        _todayFoods = foods;
        _todayWorkouts = workouts;
        _bmrBurned = bmrAccumulated;
        _stepsBurned = stepsCal;
        _workoutBurned = workoutsCal;
        _totalBurned = totalOut;
        _totalIntake = cin;
      });
    }
  }

  /// Tạo danh sách các điểm dữ liệu cho đường Calo Tiêu Hao (Burned Curve - Orange)
  List<FlSpot> _generateBurnedSpots() {
    final targetDate = widget.selectedDate ?? DateTime.now();
    final bool isToday = _isToday(targetDate);

    if (_totalBurned == 0 && !isToday) {
      return List.generate(13, (i) => FlSpot(i.toDouble(), 0.0));
    }
    final now = DateTime.now();
    final double currentHour = isToday
        ? now.hour + (now.minute / 60.0)
        : 24.0;

    // 13 mốc giờ: 0h, 2h, 4h, 6h, 8h, 10h, 12h, 14h, 16h, 18h, 20h, 22h, 24h
    final List<FlSpot> spots = [];

    for (int i = 0; i <= 12; i++) {
      final double h = i * 2.0;

      // 1. BMR tích lũy đến giờ h dựa trên BMR cá nhân
      final double bmrAtH = _userBmr * (h / 24.0);

      // 2. Vận động bước chân phân bổ theo thời gian
      double stepsAtH = 0.0;
      if (h <= currentHour) {
        final ratio = currentHour > 0 ? (h / currentHour).clamp(0.0, 1.0) : 0.0;
        stepsAtH = _stepsBurned * ratio;
      } else {
        stepsAtH = _stepsBurned.toDouble();
      }

      // 3. Bài tập hoàn thành trước hoặc tại mốc giờ h
      double workoutsAtH = 0.0;
      for (final w in _todayWorkouts) {
        final timeStr = w['timestamp']?.toString();
        if (timeStr != null) {
          final time = DateTime.tryParse(timeStr);
          if (time != null) {
            final wHour = time.hour + (time.minute / 60.0);
            if (wHour <= h || h >= currentHour) {
              final cal = (w['calories'] as num?)?.toDouble() ??
                  (((w['duration'] as num?)?.toDouble() ?? 0) * 7.0);
              workoutsAtH += cal;
            }
          }
        }
      }

      final double totalAtH = bmrAtH + stepsAtH + workoutsAtH;
      // Trục Y tính theo k-calories (ví dụ: 1200 kcal = 1.2)
      final double yVal = (totalAtH / 1000.0).clamp(0.0, 6.0);
      spots.add(FlSpot(i.toDouble(), yVal));
    }

    return spots;
  }

  /// Tạo danh sách các điểm dữ liệu cho đường Calo Nạp Vào (Intake Curve - Cyan)
  List<FlSpot> _generateIntakeSpots() {
    final targetDate = widget.selectedDate ?? DateTime.now();
    final bool isToday = _isToday(targetDate);

    if (_totalIntake == 0 && !isToday) {
      return List.generate(13, (i) => FlSpot(i.toDouble(), 0.0));
    }
    final now = DateTime.now();
    final double currentHour = isToday
        ? now.hour + (now.minute / 60.0)
        : 24.0;

    final List<FlSpot> spots = [];

    for (int i = 0; i <= 12; i++) {
      final double h = i * 2.0;

      // Tính tổng calo các món ăn đã nạp trước hoặc tại giờ h
      double intakeAtH = 0.0;
      for (final food in _todayFoods) {
        final fHour = food.timestamp.hour + (food.timestamp.minute / 60.0);
        if (fHour <= h) {
          intakeAtH += food.calories;
        } else if (h >= currentHour && fHour <= currentHour) {
          intakeAtH += food.calories;
        }
      }

      // Đảm bảo không vượt quá tổng calo nạp đã ghi
      if (intakeAtH > _totalIntake) {
        intakeAtH = _totalIntake.toDouble();
      }

      final double yVal = (intakeAtH / 1000.0).clamp(0.0, 6.0);
      spots.add(FlSpot(i.toDouble(), yVal));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;
    final burnedSpots = _generateBurnedSpots();
    final intakeSpots = _generateIntakeSpots();

    final now = DateTime.now();
    final currentIdx = ((now.hour + (now.minute / 60.0)) / 2.0).round().clamp(0, 12);

    // Tính Max Y linh hoạt dựa trên giá trị calo cao nhất
    final double maxKcal = max(_totalBurned, _totalIntake).toDouble();
    final double maxY = max(3.0, ((maxKcal + 600) / 1000.0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleService.tr('calories_burned_title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocaleService.tr('calories_burned_sub'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badges nạp vào & tiêu hao & History
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$_totalIntake in',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00F0FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$_totalBurned out',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ChartHistorySheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 12, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            LocaleService.tr('history_btn'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Segmented Tabs: 24H | 7 NGÀY (TUẦN) | CÂN NẶNG
          Row(
            children: [
              _buildChartTab('24h', isVi ? '24h Hôm nay' : '24h Today'),
              const SizedBox(width: 6),
              _buildChartTab('week', isVi ? '7 Ngày (Tuần)' : '7-Day Week'),
              const SizedBox(width: 6),
              _buildChartTab('weight', isVi ? 'Cân Nặng' : 'Weight'),
            ],
          ),

          const SizedBox(height: 14),

          if (_selectedTab == 'week')
            const WeeklyCalorieBarChart()
          else if (_selectedTab == 'weight')
            const WeightJourneyChart()
          else ...[
          // 4 Breakdown Metrics Pills
          Row(
            children: [
              _buildBurnPill(
                LocaleService.tr('food_intake_pill'),
                '$_totalIntake kcal',
                const Color(0xFF00F0FF),
              ),
              const SizedBox(width: 6),
              _buildBurnPill(
                LocaleService.tr('bmr_basal_pill'),
                '$_bmrBurned kcal',
                Colors.orangeAccent,
              ),
              const SizedBox(width: 6),
              _buildBurnPill(
                LocaleService.tr('steps_active_pill'),
                '$_stepsBurned kcal',
                const Color(0xFF00FFA3),
              ),
              const SizedBox(width: 6),
              _buildBurnPill(
                LocaleService.tr('workouts_pill'),
                '$_workoutBurned kcal',
                const Color(0xFFFFB300),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Legend Indicators
          Row(
            children: [
              _buildLegendDot(const Color(0xFF00F0FF), LocaleService.tr('chart_legend_in')),
              const SizedBox(width: 14),
              _buildLegendDot(Colors.orangeAccent, LocaleService.tr('chart_legend_out')),
              const Spacer(),
              Text(
                LocaleService.tr('chart_current_dot'),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dual Line Real-time Chart
          SizedBox(
            height: 165,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('00:00', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                          case 2:
                            return const Text('04:00', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                          case 4:
                            return const Text('08:00', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                          case 6:
                            return const Text('12:00', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                          case 8:
                            return const Text('16:00', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                          case 10:
                            return const Text('20:00', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                          case 12:
                            return const Text('24:00', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 1) return const Text('1k', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                        if (value == 2) return const Text('2k', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                        if (value == 3) return const Text('3k', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                        if (value == 4) return const Text('4k', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10));
                        return const SizedBox.shrink();
                      },
                      reservedSize: 26,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 12,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // 1. Đường Calo Tiêu Hao (Burned Line - Orange)
                  LineChartBarData(
                    spots: burnedSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.orangeAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        return spot.x.toInt() == currentIdx;
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Colors.orangeAccent,
                          strokeWidth: 2.5,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.25),
                          Colors.orange.withValues(alpha: 0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // 2. Đường Calo Nạp Vào (Intake Line - Cyan)
                  LineChartBarData(
                    spots: intakeSpots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: const Color(0xFF00F0FF),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        return spot.x.toInt() == currentIdx;
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: const Color(0xFF00F0FF),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          const Color(0xFF00F0FF).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartTab(String key, String label) {
    final isSelected = _selectedTab == key;
    return Expanded(
      child: BouncingTap(
        onTap: () {
          AppHaptics.selection();
          setState(() {
            _selectedTab = key;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00F0FF).withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00F0FF)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBurnPill(String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: accentColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
