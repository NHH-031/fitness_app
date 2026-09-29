import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import 'health_score_breakdown_sheet.dart';
import 'health_score_history_sheet.dart';
import 'app_ui_components.dart';

class HealthScoreBreakdown {
  final int totalScore;
  final int nutritionScore;
  final int workoutScore;
  final int stepScore;
  final int habitScore;

  // Raw Metrics
  final int caloriesIn;
  final int targetCalories;
  final int proteinGrams;
  final int targetProtein;
  final int workoutMinutes;
  final int workoutCount;
  final int currentSteps;
  final int goalSteps;
  final int waterCups;
  final int streakDays;

  // Status & Dynamic Guidance
  final String statusKey;
  final String statusText;
  final Color statusColor;
  final String adviceText;
  final IconData adviceIcon;

  const HealthScoreBreakdown({
    required this.totalScore,
    required this.nutritionScore,
    required this.workoutScore,
    required this.stepScore,
    required this.habitScore,
    required this.caloriesIn,
    required this.targetCalories,
    required this.proteinGrams,
    required this.targetProtein,
    required this.workoutMinutes,
    required this.workoutCount,
    required this.currentSteps,
    required this.goalSteps,
    required this.waterCups,
    required this.streakDays,
    required this.statusKey,
    required this.statusText,
    required this.statusColor,
    required this.adviceText,
    required this.adviceIcon,
  });
}

class HealthScoreCalculator {
  /// Evaluates multi-pillar lifestyle metrics and returns comprehensive HealthScoreBreakdown
  static HealthScoreBreakdown evaluate({
    required int currentSteps,
    int goalSteps = 10000,
    required int caloriesIn,
    int targetCalories = 2000,
    int proteinGrams = 0,
    int targetProtein = 120,
    required int workoutMinutes,
    int workoutCount = 0,
    int waterCups = 0,
    int streakDays = 0,
  }) {
    // 1. Vận động bước chân (Tối đa 20 điểm)
    double stepRatio = goalSteps > 0 ? (currentSteps / goalSteps) : 0.0;
    int stepScore = (stepRatio * 20).round().clamp(0, 20);

    // 2. Rèn luyện bài tập (Tối đa 35 điểm)
    int workoutScore = 0;
    if (workoutMinutes > 0 || workoutCount > 0) {
      workoutScore = (workoutMinutes / 30.0 * 30).round();
      if (workoutCount > 0 && workoutScore < 15) {
        workoutScore = 15; // Hoàn thành ít nhất 1 buổi tập = tối thiểu 15đ
      }
      if (workoutMinutes >= 35) {
        workoutScore = 35; // Vượt chuẩn 30-45p thể lực
      }
    }
    workoutScore = workoutScore.clamp(0, 35);

    // 3. Dinh dưỡng & Năng lượng (Tối đa 35 điểm)
    int nutritionScore = 0;
    if (caloriesIn > 0) {
      double ratio = targetCalories > 0 ? (caloriesIn / targetCalories) : 1.0;
      int baseNutri = 0;
      if (ratio >= 0.70 && ratio <= 1.10) {
        baseNutri = 28; // Tỉ lệ bám sát mục tiêu calo
      } else if (ratio >= 0.40 && ratio < 0.70) {
        baseNutri = (ratio * 35).round(); // Đang nạp từng bữa trong ngày
      } else if (ratio > 1.10 && ratio <= 1.30) {
        baseNutri = 22; // Thặng dư nhẹ
      } else if (ratio > 1.30) {
        baseNutri = 15; // Nạp calo quá mức
      } else {
        baseNutri = 10;
      }

      // Bonus đạm (protein) lên tới 7 điểm
      int proteinBonus = 0;
      if (targetProtein > 0 && proteinGrams > 0) {
        proteinBonus = ((proteinGrams / targetProtein) * 7).round().clamp(0, 7);
      }
      nutritionScore = (baseNutri + proteinBonus).clamp(0, 35);
    }

    // 4. Thủy hóa & Thói quen chuỗi ngày (Tối đa 10 điểm)
    int waterScore = (waterCups / 8.0 * 7).round().clamp(0, 7);
    int streakBonus = streakDays > 0 ? 3 : 0;
    int habitScore = (waterScore + streakBonus).clamp(0, 10);

    // Tổng điểm sức khỏe (0 - 100)
    int totalScore = (stepScore + workoutScore + nutritionScore + habitScore).clamp(0, 100);

    // Thang phân bậc trạng thái 5 mức
    final statusKey = getScoreStatusKey(totalScore);
    final statusText = LocaleService.tr(statusKey);
    final statusColor = getScoreColor(totalScore);

    // Lời khuyên & Nhắc nhở động theo thời gian thực
    final advicePair = _generateAdvice(
      totalScore: totalScore,
      caloriesIn: caloriesIn,
      targetCalories: targetCalories,
      workoutMinutes: workoutMinutes,
      workoutCount: workoutCount,
      currentSteps: currentSteps,
      goalSteps: goalSteps,
      waterCups: waterCups,
    );

    return HealthScoreBreakdown(
      totalScore: totalScore,
      nutritionScore: nutritionScore,
      workoutScore: workoutScore,
      stepScore: stepScore,
      habitScore: habitScore,
      caloriesIn: caloriesIn,
      targetCalories: targetCalories,
      proteinGrams: proteinGrams,
      targetProtein: targetProtein,
      workoutMinutes: workoutMinutes,
      workoutCount: workoutCount,
      currentSteps: currentSteps,
      goalSteps: goalSteps,
      waterCups: waterCups,
      streakDays: streakDays,
      statusKey: statusKey,
      statusText: statusText,
      statusColor: statusColor,
      adviceText: advicePair.$1,
      adviceIcon: advicePair.$2,
    );
  }

  /// Legacy calculate compatibility wrapper
  static int calculate({
    required int currentSteps,
    required int goalSteps,
    required int caloriesIn,
    required int caloriesOutBase,
    required int workoutScore,
  }) {
    // 1. Bước chân (max 20)
    double stepRatio = goalSteps > 0 ? (currentSteps / goalSteps) : 0.0;
    int sScore = (stepRatio * 20).round().clamp(0, 20);

    // 2. Bài tập (max 35)
    int wScore = workoutScore.clamp(0, 35);

    // 3. Calo (max 35)
    int cScore = 0;
    if (caloriesIn > 0) {
      int diff = (caloriesIn - (caloriesOutBase + (currentSteps * 0.04).round())).abs();
      if (diff <= 500) {
        cScore = 30;
      } else if (diff <= 900) {
        cScore = 20;
      } else {
        cScore = 12;
      }
    }

    // 4. Cơ bản
    int habitScore = 10;

    return (sScore + wScore + cScore + habitScore).clamp(0, 100);
  }

  static String getScoreStatusKey(int score) {
    if (score >= 90) return 'score_peak';
    if (score >= 75) return 'score_great';
    if (score >= 60) return 'score_on_track';
    if (score >= 40) return 'score_keep_going';
    return 'score_needs_work';
  }

  static String getScoreStatus(int score) {
    return LocaleService.tr(getScoreStatusKey(score));
  }

  static Color getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00FFA3); // Emerald Green
    if (score >= 75) return const Color(0xFF00E5FF); // Bright Cyan
    if (score >= 60) return const Color(0xFFFBBF24); // Amber
    if (score >= 40) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF4B4B); // Coral Red
  }

  static (String, IconData) _generateAdvice({
    required int totalScore,
    required int caloriesIn,
    required int targetCalories,
    required int workoutMinutes,
    required int workoutCount,
    required int currentSteps,
    required int goalSteps,
    required int waterCups,
  }) {
    if (totalScore >= 85) {
      return (LocaleService.tr('health_tip_excellent'), Icons.local_fire_department);
    }
    if (caloriesIn > (targetCalories * 1.25)) {
      return (LocaleService.tr('health_tip_high_nutrition'), Icons.warning_amber_rounded);
    }
    if (workoutMinutes == 0 && workoutCount == 0) {
      return (LocaleService.tr('health_tip_no_workout'), Icons.fitness_center);
    }
    if (caloriesIn < 300) {
      return (
        LocaleService.tr('health_tip_low_nutrition', args: {'cin': caloriesIn.toString()}),
        Icons.restaurant
      );
    }
    if (currentSteps < (goalSteps * 0.35).round()) {
      return (
        LocaleService.tr('health_tip_low_steps', args: {'steps': currentSteps.toString()}),
        Icons.directions_walk
      );
    }
    if (waterCups < 4) {
      return (LocaleService.tr('health_tip_low_water'), Icons.water_drop);
    }
    return (LocaleService.tr('health_score_sub'), Icons.insights);
  }
}

class HealthScoreWidget extends StatefulWidget {
  final int? currentSteps;
  final DateTime? selectedDate;

  const HealthScoreWidget({
    super.key,
    this.currentSteps,
    this.selectedDate,
  });

  @override
  State<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends State<HealthScoreWidget> {
  static const eventChannel = EventChannel('com.example.fitness_tracker/steps');

  int _internalSteps = 0;
  int _initialSteps = -1;
  final int _goalSteps = 10000;

  HealthScoreBreakdown? _breakdown;

  int get _effectiveSteps => widget.currentSteps ?? _internalSteps;

  @override
  void initState() {
    super.initState();
    _loadRealData();
    StorageService.dataUpdateNotifier.addListener(_loadRealData);
    StorageService.stepUpdateNotifier.addListener(_loadRealData);
    _listenToSteps();
  }

  @override
  void didUpdateWidget(covariant HealthScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSteps != widget.currentSteps ||
        oldWidget.selectedDate != widget.selectedDate) {
      _loadRealData();
    }
  }

  @override
  void dispose() {
    StorageService.dataUpdateNotifier.removeListener(_loadRealData);
    StorageService.stepUpdateNotifier.removeListener(_loadRealData);
    super.dispose();
  }

  Future<void> _loadRealData() async {
    final targetDate = widget.selectedDate ?? DateTime.now();
    final now = DateTime.now();
    final bool isToday = targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    final userProfile = await StorageService.getUserProfile();
    final caloriesIn = await StorageService.getTotalCaloriesInByDate(targetDate);
    final macros = await StorageService.getTotalMacrosByDate(targetDate);
    final workoutMins = await StorageService.getWorkoutMinutesByDate(targetDate);
    final workoutLogs = await StorageService.getWorkoutLogsByDate(targetDate);
    final waterCups = await StorageService.getWaterCupsByDate(targetDate);
    final streak = await StorageService.getCurrentStreak();

    int effectiveSteps = widget.currentSteps ??
        (isToday ? _effectiveSteps : await StorageService.getStepsByDate(targetDate));
    if (effectiveSteps == 0) {
      effectiveSteps = await StorageService.getStepsByDate(targetDate);
    }

    final breakdown = HealthScoreCalculator.evaluate(
      currentSteps: effectiveSteps,
      goalSteps: _goalSteps,
      caloriesIn: caloriesIn,
      targetCalories: userProfile.targetCalories,
      proteinGrams: macros['protein'] ?? 0,
      targetProtein: userProfile.targetProtein,
      workoutMinutes: workoutMins,
      workoutCount: workoutLogs.length,
      waterCups: waterCups,
      streakDays: streak,
    );

    if (mounted) {
      setState(() {
        _breakdown = breakdown;
      });
    }
  }

  void _listenToSteps() {
    eventChannel.receiveBroadcastStream().listen((dynamic event) {
      int steps = event as int;
      if (mounted) {
        setState(() {
          if (_initialSteps == -1) {
            _initialSteps = steps;
          }
          _internalSteps = steps - _initialSteps;
        });
        final targetDate = widget.selectedDate ?? DateTime.now();
        final now = DateTime.now();
        final bool isToday = targetDate.year == now.year &&
            targetDate.month == now.month &&
            targetDate.day == now.day;
        if (isToday) {
          _loadRealData();
        }
      }
    }, onError: (dynamic error) {
      debugPrint("HealthScoreWidget Error: $error");
    });
  }

  List<List<dynamic>> _mapAdviceIcon(IconData icon) {
    if (icon == Icons.local_fire_department) return HugeIcons.strokeRoundedFire;
    if (icon == Icons.fitness_center) return HugeIcons.strokeRoundedDumbbell01;
    if (icon == Icons.restaurant) return HugeIcons.strokeRoundedRestaurant;
    if (icon == Icons.directions_walk) return HugeIcons.strokeRoundedWalking;
    if (icon == Icons.warning_amber_rounded) return HugeIcons.strokeRoundedAlert02;
    return HugeIcons.strokeRoundedActivity01;
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _breakdown;
    final score = breakdown?.totalScore ?? 0;
    final status = breakdown?.statusText ?? HealthScoreCalculator.getScoreStatus(score);
    final scoreColor = breakdown?.statusColor ?? HealthScoreCalculator.getScoreColor(score);
    final advice = breakdown?.adviceText ?? LocaleService.tr('health_score_sub');
    final adviceIcon = breakdown?.adviceIcon ?? Icons.insights;

    return SquircleCard(
      cornerRadius: 26,
      borderColor: scoreColor.withValues(alpha: 0.45),
      glowColor: scoreColor,
      glowRadius: 20,
      padding: const EdgeInsets.all(20),
      gradientColors: [
        scoreColor.withValues(alpha: 0.16),
        AppTheme.cardColor,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedFavourite, color: scoreColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocaleService.tr('health_score_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  BouncingTap(
                    onTap: () => HealthScoreHistorySheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: SmoothRectangleBorder(
                          borderRadius: const SmoothBorderRadius.all(
                            SmoothRadius(cornerRadius: 12, cornerSmoothing: 0.6),
                          ),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedHistory, size: 12, color: Color(0xFF00FFA3)),
                          const SizedBox(width: 3),
                          Text(
                            LocaleService.tr('history_btn'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  BouncingTap(
                    onTap: () {
                      HealthScoreBreakdownSheet.show(
                        context,
                        currentSteps: _effectiveSteps,
                        date: widget.selectedDate,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          LocaleService.isVietnamese ? 'Chi tiết' : 'Details',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Clickable Score & Advice Area (opens Breakdown Sheet) with BouncingTap
          BouncingTap(
            onTap: () {
              HealthScoreBreakdownSheet.show(
                context,
                currentSteps: _effectiveSteps,
                date: widget.selectedDate,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score & Status Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score.toString(),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text('/100', style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: ShapeDecoration(
                        color: scoreColor.withValues(alpha: 0.18),
                        shape: SmoothRectangleBorder(
                          borderRadius: const SmoothBorderRadius.all(
                            SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                          ),
                          side: BorderSide(color: scoreColor.withValues(alpha: 0.5), width: 1),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 14),

                // Dynamic Smart Advice Card with squircle border
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: ShapeDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: SmoothRectangleBorder(
                      borderRadius: const SmoothBorderRadius.all(
                        SmoothRadius(cornerRadius: 12, cornerSmoothing: 0.6),
                      ),
                      side: BorderSide(
                        color: scoreColor.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HugeIcon(
                        icon: _mapAdviceIcon(adviceIcon),
                        color: scoreColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          advice,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
