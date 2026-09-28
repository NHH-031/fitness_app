import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../widgets/calorie_balance_hero_widget.dart';
import '../widgets/step_counter_widget.dart';
import '../widgets/calories_chart_widget.dart';
import '../widgets/ai_food_logging_widget.dart';
import '../widgets/health_score_widget.dart';
import '../widgets/water_reminder_widget.dart';
import '../widgets/daily_ai_briefing_widget.dart';
import '../widgets/app_ui_components.dart';
import '../services/storage_service.dart';
import '../utils/app_formatters.dart';
import '../utils/app_haptics.dart';
import '../widgets/achievements_sheet.dart';
import '../widgets/badge_unlock_dialog.dart';
import '../services/locale_service.dart';
import '../services/achievement_service.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const eventChannel = EventChannel('com.example.fitness_tracker/steps');
  int _streak = 0;
  int _currentSteps = 0;
  int _initialSteps = -1;
  String _userName = 'ATHLETE';
  DateTime _selectedDate = DateTime.now();
  DateTime _joinedDate = DateTime.now();
  StreamSubscription? _badgeSubscription;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _loadProfile();
    _loadJoinedDate();
    _listenToSteps();
    StorageService.profileUpdateNotifier.addListener(_onDataUpdated);
    _badgeSubscription = AchievementService.onBadgeUnlocked.listen((badge) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            BadgeUnlockDialog.show(context, badge);
          }
        });
      }
    });
    AchievementService.checkBadges();
  }

  @override
  void dispose() {
    _badgeSubscription?.cancel();
    StorageService.profileUpdateNotifier.removeListener(_onDataUpdated);
    super.dispose();
  }

  void _onDataUpdated() {
    _loadProfile();
    _loadJoinedDate();
    _loadStreak();
  }

  Future<void> _loadJoinedDate() async {
    final jd = await StorageService.getUserJoinedDate();
    if (mounted) {
      setState(() {
        _joinedDate = DateTime(jd.year, jd.month, jd.day);
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await StorageService.getUserProfile();
    if (mounted) {
      setState(() {
        _userName = profile.name.trim().isEmpty ? 'ATHLETE' : profile.name.toUpperCase();
      });
    }
  }

  Future<void> _loadStreak() async {
    int streak = await StorageService.checkAndUpdateStreak();
    if (mounted) {
      setState(() {
        _streak = streak;
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
          _currentSteps = steps - _initialSteps;
        });
      }
    }, onError: (dynamic error) {
      debugPrint("Step Sensor EventChannel Error: $error");
    });
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }

  bool get _canGoPrevious {
    final curDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return curDay.isAfter(_joinedDate);
  }

  String _getDateNavigationLabel() {
    if (_isToday(_selectedDate)) {
      return LocaleService.tr(
        'date_nav_today',
        args: {'date': AppFormatters.formatDayMonth(_selectedDate)},
      );
    } else if (_isYesterday(_selectedDate)) {
      return LocaleService.tr(
        'date_nav_yesterday',
        args: {'date': AppFormatters.formatDayMonth(_selectedDate)},
      );
    } else {
      final weekdayVi = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'][_selectedDate.weekday - 1];
      final weekdayEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][_selectedDate.weekday - 1];
      final w = LocaleService.isVietnamese ? weekdayVi : weekdayEn;
      return '$w, ${AppFormatters.formatDateFull(_selectedDate)}';
    }
  }

  void _goToPreviousDay() {
    if (_canGoPrevious) {
      setState(() {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      });
    }
  }

  void _goToNextDay() {
    if (!_isToday(_selectedDate)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstAllowed = _joinedDate.isBefore(today) ? _joinedDate : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstAllowed,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F0FF),
              onPrimary: Colors.black,
              surface: Color(0xFF161A29),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF161A29),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _resetToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isViewingToday = _isToday(_selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    LocaleService.isVietnamese ? 'XIN CHÀO' : 'WELCOME',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('👋', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: AppTheme.textPrimaryColor,
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
                  // Streak Pill with squircle & bouncing tap
                  BouncingTap(
                    onTap: () {
                      AppHaptics.medium();
                      AchievementsSheet.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: ShapeDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: SmoothRectangleBorder(
                          borderRadius: const SmoothBorderRadius.all(
                            SmoothRadius(cornerRadius: 16, cornerSmoothing: 0.6),
                          ),
                          side: BorderSide(
                            color: Colors.orange.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedFire, color: Colors.orange, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            LocaleService.tr('streak_days', args: {'count': _streak.toString()}),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // DATE SELECTOR NAVIGATION BAR (< Hôm qua | Hôm nay >)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: ShapeDecoration(
                  color: AppTheme.cardColor,
                  shape: SmoothRectangleBorder(
                    borderRadius: const SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 18, cornerSmoothing: 0.6),
                    ),
                    side: BorderSide(
                      color: isViewingToday
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.28)
                          : Colors.orange.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: isViewingToday
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.05)
                          : Colors.orange.withValues(alpha: 0.08),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    BouncingTap(
                      onTap: _canGoPrevious ? _goToPreviousDay : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          color: _canGoPrevious ? const Color(0xFF00F0FF) : Colors.white24,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: BouncingTap(
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: isViewingToday
                                    ? HugeIcons.strokeRoundedClock01
                                    : HugeIcons.strokeRoundedHistory,
                                size: 16,
                                color: isViewingToday
                                    ? const Color(0xFF00F0FF)
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _getDateNavigationLabel(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: isViewingToday
                                        ? Colors.white
                                        : Colors.orange,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar01,
                                size: 15,
                                color: isViewingToday
                                    ? const Color(0xFF00F0FF)
                                    : Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    BouncingTap(
                      onTap: isViewingToday ? null : _goToNextDay,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: isViewingToday ? Colors.white24 : const Color(0xFF00F0FF),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Past Day Floating Alert Banner
              if (!isViewingToday) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocaleService.tr(
                            'viewing_past_day_banner',
                            args: {
                              'date': AppFormatters.formatDateFull(_selectedDate)
                            },
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _resetToToday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            LocaleService.tr('back_to_today_btn'),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // 0. Daily AI PT Briefing (Morning AI Coach message)
              DailyAiBriefingWidget(
                selectedDate: _selectedDate,
              ),

              const SizedBox(height: 18),

              // 1. Hero Calorie Balance Card (Real-time In vs Out & History)
              CalorieBalanceHeroWidget(
                currentSteps: _currentSteps,
                selectedDate: _selectedDate,
              ),

              const SizedBox(height: 20),

              // 2. Health Score Widget (Connected to Real-time Calorie Data & History)
              HealthScoreWidget(
                currentSteps: _currentSteps,
                selectedDate: _selectedDate,
              ),

              const SizedBox(height: 20),

              // 3. Step Counter Widget (Hardware Steps & History)
              StepCounterWidget(
                goalSteps: 10000,
                selectedDate: _selectedDate,
              ),

              const SizedBox(height: 20),

              // 4. Real-time Calories Burn Chart (Dynamic 24h curve & History)
              CaloriesChartWidget(
                currentSteps: _currentSteps,
                selectedDate: _selectedDate,
              ),

              const SizedBox(height: 20),

              // 5. AI Food Logging & Nutrition Diary (Voice / Keyboard & Meal History)
              AiFoodLoggingWidget(
                selectedDate: _selectedDate,
                onFoodUpdated: () {
                  setState(() {});
                },
              ),

              const SizedBox(height: 20),

              // 6. Water Reminder Widget
              WaterReminderWidget(
                selectedDate: _selectedDate,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
