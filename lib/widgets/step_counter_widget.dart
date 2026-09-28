import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import 'step_history_sheet.dart';

class StepCounterWidget extends StatefulWidget {
  final int goalSteps;
  final DateTime? selectedDate;

  const StepCounterWidget({
    super.key,
    required this.goalSteps,
    this.selectedDate,
  });

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  static const methodChannel = MethodChannel('com.example.fitness_tracker/service');
  static const eventChannel = EventChannel('com.example.fitness_tracker/steps');

  int _currentSteps = 0;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedSteps();
    _initStepCounter();
    StorageService.stepUpdateNotifier.addListener(_loadSavedSteps);
  }

  @override
  void didUpdateWidget(covariant StepCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadSavedSteps();
    }
  }

  @override
  void dispose() {
    StorageService.stepUpdateNotifier.removeListener(_loadSavedSteps);
    super.dispose();
  }

  Future<void> _loadSavedSteps() async {
    final targetDate = widget.selectedDate ?? DateTime.now();
    final bool isToday = _isToday(targetDate);
    final saved = isToday
        ? await StorageService.getTodaySteps()
        : await StorageService.getStepsByDate(targetDate);

    if (mounted) {
      setState(() {
        _currentSteps = saved;
      });
    }
  }

  Future<void> _initStepCounter() async {
    // Xin quyền Activity Recognition
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      // Khởi động Foreground Service trên Android để đếm bước ngầm
      try {
        await methodChannel.invokeMethod('startService');
      } catch (e) {
        debugPrint("Failed to start step service: ${e.toString()}");
      }

      // Lắng nghe luồng dữ liệu cảm biến phần cứng liên tục
      eventChannel.receiveBroadcastStream().listen((dynamic event) async {
        if (event is int) {
          // Tính toán và lưu trữ mốc bước chân ngày mới (kể cả khi đã tắt app)
          final calculated = await StorageService.processHardwareSteps(event);
          final targetDate = widget.selectedDate ?? DateTime.now();
          if (mounted && _isToday(targetDate)) {
            setState(() {
              _currentSteps = calculated;
            });
          }
        }
      }, onError: (dynamic error) {
        debugPrint("StepCounter Event Error: $error");
      });
    } else {
      debugPrint("Activity recognition permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percent = widget.goalSteps > 0
        ? (_currentSteps / widget.goalSteps).clamp(0.0, 1.0)
        : 0.0;

    // 1. Quãng đường (km) = bước * 0.75m
    final String distanceKm = (_currentSteps * 0.00075).toStringAsFixed(2);
    // 2. Calo đốt cháy (kcal) = bước * 0.04
    final int activeKcal = (_currentSteps * 0.04).round();
    // 3. Thời gian đi bộ tích cực (phút) = bước / 100
    final int activeMins = (_currentSteps / 100).round();
    // 4. Số bước còn lại để hoàn thành mục tiêu
    final int remainingSteps = max(0, widget.goalSteps - _currentSteps);

    final bool isCompleted = _currentSteps >= widget.goalSteps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.06),
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
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedRunningShoes,
                        color: Color(0xFF00F0FF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        LocaleService.tr('step_counter_title'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      '${widget.goalSteps} b',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => StepHistorySheet.show(
                      context,
                      goalSteps: widget.goalSteps,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedHistory, size: 12, color: Color(0xFF00F0FF)),
                          const SizedBox(width: 3),
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

          const SizedBox(height: 18),

          // Main Row: Left Circular Ring & Right 3 Movement Metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // BÊN TRÁI: Vòng tròn đo bước chân
              CircularPercentIndicator(
                radius: 68.0,
                lineWidth: 10.0,
                animation: true,
                animateFromLastPercent: true,
                percent: percent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedWalking,
                      color: isCompleted ? const Color(0xFF00FFA3) : const Color(0xFF00F0FF),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentSteps.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr('steps_label'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                        color: AppTheme.textSecondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(percent * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? const Color(0xFF00FFA3) : const Color(0xFF00F0FF),
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: isCompleted ? const Color(0xFF00FFA3) : const Color(0xFF00F0FF),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                widgetIndicator: Center(
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: isCompleted ? const Color(0xFF00FFA3) : Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // BÊN PHẢI: 3 Chỉ số thể chất chi tiết
              Expanded(
                child: Column(
                  children: [
                    // 1. Quãng đường
                    _buildMetricRow(
                      icon: HugeIcons.strokeRoundedLocation01,
                      iconColor: const Color(0xFF00F0FF),
                      value: '$distanceKm km',
                      label: LocaleService.tr('step_distance_label'),
                    ),
                    const SizedBox(height: 8),

                    // 2. Calo tiêu hao
                    _buildMetricRow(
                      icon: HugeIcons.strokeRoundedFire,
                      iconColor: Colors.orangeAccent,
                      value: '$activeKcal kcal',
                      label: LocaleService.tr('step_calories_label'),
                    ),
                    const SizedBox(height: 8),

                    // 3. Thời gian đi bộ
                    _buildMetricRow(
                      icon: HugeIcons.strokeRoundedClock01,
                      iconColor: const Color(0xFF00FFA3),
                      value: LocaleService.isVietnamese ? '$activeMins phút' : '$activeMins mins',
                      label: LocaleService.tr('step_time_label'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dưới cùng: Lời nhắc / Mục tiêu còn lại
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF00FFA3).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF00FFA3).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: isCompleted ? HugeIcons.strokeRoundedTrophy : HugeIcons.strokeRoundedFlag01,
                  color: isCompleted ? const Color(0xFF00FFA3) : const Color(0xFF00F0FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCompleted
                        ? LocaleService.tr('step_goal_completed')
                        : LocaleService.tr('step_remaining_hint', args: {'steps': remainingSteps.toString()}),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFF00FFA3) : Colors.white70,
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

  Widget _buildMetricRow({
    required List<List<dynamic>> icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
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
