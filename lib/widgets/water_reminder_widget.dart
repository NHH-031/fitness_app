import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/locale_service.dart';
import '../services/background_service.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'app_ui_components.dart';
import '../utils/app_haptics.dart';
import '../services/achievement_service.dart';

class WaterReminderWidget extends StatefulWidget {
  final DateTime? selectedDate;

  const WaterReminderWidget({
    super.key,
    this.selectedDate,
  });

  @override
  State<WaterReminderWidget> createState() => _WaterReminderWidgetState();
}

class _WaterReminderWidgetState extends State<WaterReminderWidget>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  bool _isEnabled = true;
  int _intervalHours = 2;
  int _cups = 0;
  static const int _goalCups = 8; // 8 x 250ml = 2000ml
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StorageService.waterUpdateNotifier.addListener(_onDataUpdated);
    _loadSettings();
    _scheduleMidnightTimer();
  }

  @override
  void didUpdateWidget(covariant WaterReminderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _refreshCupsOnly();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StorageService.waterUpdateNotifier.removeListener(_onDataUpdated);
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _onDataUpdated() {
    if (mounted) {
      _refreshCupsOnly();
    }
  }

  Future<void> _refreshCupsOnly() async {
    final target = widget.selectedDate ?? DateTime.now();
    final cups = await StorageService.getWaterCupsByDate(target);
    if (mounted) {
      setState(() {
        _cups = cups;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDayRolloverAndRefresh();
    }
  }

  Future<void> _checkDayRolloverAndRefresh() async {
    final resetOccurred = await StorageService.checkAndResetWaterDaily();
    final target = widget.selectedDate ?? DateTime.now();
    final cups = await StorageService.getWaterCupsByDate(target);
    if (mounted) {
      setState(() {
        _cups = cups;
      });
      if (resetOccurred) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('water_reset_toast')),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    _scheduleMidnightTimer();
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight =
        nextMidnight.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(durationUntilMidnight, () async {
      await _checkDayRolloverAndRefresh();
    });
  }

  Future<void> _loadSettings() async {
    final enabled = await StorageService.isWaterReminderEnabled();
    final interval = await StorageService.getWaterReminderInterval();
    final target = widget.selectedDate ?? DateTime.now();
    final cups = await StorageService.getWaterCupsByDate(target);

    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _intervalHours = interval;
        _cups = cups;
      });
    }

    if (enabled) {
      await _notificationService.schedulePeriodicWaterReminder(
        intervalHours: interval,
      );
    }
  }

  Future<void> _toggleReminder(bool value) async {
    AppHaptics.selection();
    setState(() {
      _isEnabled = value;
    });
    await StorageService.setWaterReminderEnabled(value);

    if (value) {
      await _notificationService.schedulePeriodicWaterReminder(
        intervalHours: _intervalHours,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final isExempt = await BackgroundService.isIgnoringBatteryOptimizations();
      if (!mounted) return;
      if (!isExempt) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              LocaleService.isVietnamese
                  ? '⚡ Bật chạy ngầm không giới hạn để chuông nhắc không bị tắt khi khóa màn hình'
                  : '⚡ Allow unrestricted background to prevent alarms from stopping when locked',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: LocaleService.isVietnamese ? 'CẤP QUYỀN' : 'ENABLE',
              textColor: const Color(0xFF00FFA3),
              onPressed: () {
                BackgroundService.requestIgnoreBatteryOptimizations();
              },
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              LocaleService.tr('water_reminder_enabled_snack', args: {'hours': '$_intervalHours'}),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _notificationService.cancelWaterReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('water_reminder_disabled_snack')),
            backgroundColor: Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _changeInterval(int hours) async {
    AppHaptics.selection();
    setState(() {
      _intervalHours = hours;
    });
    await StorageService.setWaterReminderInterval(hours);
    if (_isEnabled) {
      await _notificationService.schedulePeriodicWaterReminder(
        intervalHours: hours,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('water_reminder_updated_snack', args: {'hours': '$hours'})),
            backgroundColor: const Color(0xFF007AFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _addCup() async {
    AppHaptics.medium();
    final target = widget.selectedDate ?? DateTime.now();
    final newCups = await StorageService.addWaterCupForDate(target);
    if (mounted) {
      setState(() {
        _cups = newCups;
      });
    }
    AchievementService.checkBadges();
  }

  Future<void> _removeCup() async {
    AppHaptics.light();
    final target = widget.selectedDate ?? DateTime.now();
    final newCups = await StorageService.removeWaterCupForDate(target);
    if (mounted) {
      setState(() {
        _cups = newCups;
      });
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.scheduleTestNotification(seconds: 5);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleService.tr('water_test_snack')),
          backgroundColor: const Color(0xFF0288D1),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _instantNotification() async {
    await _notificationService.showInstantNotification(
      title: LocaleService.tr('water_instant_title'),
      body: LocaleService.tr('water_instant_body'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleService.tr('water_instant_snack')),
          backgroundColor: const Color(0xFF007AFF),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWaterHistoryModal() {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Color(0xFF141824),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF007AFF), width: 1.5),
            ),
          ),
          child: Column(
            children: [
              const BottomSheetDragHandle(color: Color(0x6600C6FF)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedHistory,
                        color: Color(0xFF00C6FF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleService.tr('water_history_title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocaleService.tr('water_history_sub'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: FutureBuilder<List<DailyWaterLog>>(
                  future: StorageService.getWaterHistoryLogs(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
                        ),
                      );
                    }
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedGlassWater,
                              size: 56,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              LocaleService.tr('water_history_empty'),
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final todayStr = StorageService.getTodayDateString();
                    final yesterdayStr = StorageService.getTodayDateString(
                      DateTime.now().subtract(const Duration(days: 1)),
                    );

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = logs[index];
                        String dateLabel = item.date;
                        if (item.date == todayStr) {
                          dateLabel = '${LocaleService.tr('water_day_today')} (${item.date})';
                        } else if (item.date == yesterdayStr) {
                          dateLabel = '${LocaleService.tr('water_day_yesterday')} (${item.date})';
                        }

                        final progress = (item.cups / _goalCups).clamp(0.0, 1.0);
                        final isGoal = item.isGoalReached;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isGoal
                                  ? const Color(0xFF00FFA3).withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedCalendar01,
                                        size: 14,
                                        color: item.date == todayStr
                                            ? const Color(0xFF00C6FF)
                                            : Colors.white54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateLabel,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: item.date == todayStr
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: item.date == todayStr
                                              ? const Color(0xFF00C6FF)
                                              : AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isGoal
                                          ? const Color(0xFF00FFA3).withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HugeIcon(
                                          icon: isGoal
                                              ? HugeIcons.strokeRoundedCheckmarkCircle01
                                              : HugeIcons.strokeRoundedClock01,
                                          size: 12,
                                          color: isGoal
                                              ? const Color(0xFF00FFA3)
                                              : AppTheme.textSecondaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isGoal
                                              ? LocaleService.tr('water_goal_achieved')
                                              : LocaleService.tr('water_goal_in_progress'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isGoal
                                                ? const Color(0xFF00FFA3)
                                                : AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.volumeMl} / 2000 ml',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00C6FF),
                                    ),
                                  ),
                                  Text(
                                    '${item.cups}/$_goalCups cốc',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isGoal
                                        ? const Color(0xFF00FFA3)
                                        : const Color(0xFF00C6FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_cups / _goalCups).clamp(0.0, 1.0);
    final int totalMl = _cups * 250;
    final int goalMl = _goalCups * 250;

    return SquircleCard(
      cornerRadius: 26,
      cornerSmoothing: 0.65,
      padding: const EdgeInsets.all(20),
      gradientColors: const [
        Color(0xFF131828),
        Color(0xFF0D101C),
      ],
      borderColor: const Color(0xFF00C6FF).withValues(alpha: 0.25),
      glowColor: const Color(0xFF007AFF),
      glowRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + History + Switch
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                  ),
                  shadows: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDroplet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('water_reminder_title'),
                      style: AppTheme.font(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr('water_reminder_sub'),
                      style: AppTheme.font(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Modern History Pill Button
              BouncingTap(
                onTap: _showWaterHistoryModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                      side: BorderSide(color: const Color(0xFF00C6FF).withValues(alpha: 0.3)),
                    ),
                    color: const Color(0xFF00C6FF).withValues(alpha: 0.1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedHistory, size: 14, color: Color(0xFF00C6FF)),
                      const SizedBox(width: 4),
                      Text(
                        LocaleService.tr('water_history_btn'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00C6FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: _isEnabled,
                  activeThumbColor: const Color(0xFF00F0FF),
                  activeTrackColor: const Color(0xFF007AFF).withValues(alpha: 0.6),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white10,
                  onChanged: _toggleReminder,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Main Hydration Display Card (Glassmorphic)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(cornerRadius: 18, cornerSmoothing: 0.6),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              color: Colors.white.withValues(alpha: 0.035),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$totalMl',
                                style: AppTheme.font(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF00E5FF),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: ' / $goalMl ml',
                                style: AppTheme.font(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          LocaleService.tr('water_cups_count',
                              args: {'cups': '$_cups', 'goal': '$_goalCups'}),
                          style: AppTheme.font(
                            fontSize: 12,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Liquid Stepper Bar
                    Row(
                      children: [
                        // Minus Button (Frosted Circle)
                        BouncingTap(
                          onTap: _cups > 0 ? _removeCup : null,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _cups > 0
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.03),
                              border: Border.all(
                                color: _cups > 0
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedMinusSign,
                              size: 18,
                              color: _cups > 0 ? Colors.white70 : Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add Liquid Capsule Button
                        BouncingTap(
                          onTap: _addCup,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: ShapeDecoration(
                              shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF00F0FF), Color(0xFF0072FF)],
                              ),
                              shadows: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.38),
                                  blurRadius: 14,
                                  spreadRadius: -1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  LocaleService.tr('add_cup_btn'),
                                  style: AppTheme.font(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
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
                const SizedBox(height: 16),
                // Glowing Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0072FF), Color(0xFF00F0FF)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Visual Mini Water Cups
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_goalCups, (index) {
                    final isDrunk = index < _cups;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDrunk
                            ? const Color(0xFF00F0FF).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDrunk
                              ? const Color(0xFF00F0FF).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedDroplet,
                        size: 14,
                        color: isDrunk ? const Color(0xFF00F0FF) : Colors.white24,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Fluid Segmented Pills for Repeat Interval
          Row(
            children: [
              Text(
                LocaleService.tr('reminder_every'),
                style: AppTheme.font(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [1, 2, 3].map((hours) {
                    final isSelected = _intervalHours == hours;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: BouncingTap(
                          onTap: () => _changeInterval(hours),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: ShapeDecoration(
                              shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF00F0FF)
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              color: isSelected
                                  ? const Color(0xFF00F0FF).withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.04),
                              shadows: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${hours}h',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Refined Quick Utilities (Replacing old bulky test buttons)
          Row(
            children: [
              Expanded(
                child: BouncingTap(
                  onTap: _instantNotification,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                        side: BorderSide(color: const Color(0xFF00C6FF).withValues(alpha: 0.2)),
                      ),
                      color: const Color(0xFF00C6FF).withValues(alpha: 0.06),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedNotification01, size: 14, color: Color(0xFF00C6FF)),
                        const SizedBox(width: 6),
                        Text(
                          LocaleService.tr('send_now_btn'),
                          style: AppTheme.font(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00C6FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BouncingTap(
                  onTap: _testNotification,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 14, color: Colors.white60),
                        const SizedBox(width: 6),
                        Text(
                          LocaleService.tr('test_timer_btn'),
                          style: AppTheme.font(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
