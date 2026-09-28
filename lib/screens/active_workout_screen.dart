import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../widgets/exercise_pose_widget.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import '../services/achievement_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String title;
  final int durationSeconds;
  final int estimatedCalories;
  final String lottieUrl;

  const ActiveWorkoutScreen({
    super.key,
    required this.title,
    this.durationSeconds = 60,
    required this.estimatedCalories,
    this.lottieUrl = '',
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;
  late int _remainingSeconds;
  late int _totalSeconds;
  bool _isRunning = true;
  bool _isCompleted = false;

  late String _currentTitle;
  late int _currentCalories;

  List<Map<String, dynamic>> get _sampleExercises => LocaleService.isVietnamese
      ? [
          {'title': 'Hít đất', 'calories': 120, 'duration': 45},
          {'title': 'Hít xà đơn', 'calories': 110, 'duration': 45},
          {'title': 'Gập bụng', 'calories': 50, 'duration': 45},
          {'title': 'Plank siết cơ bụng', 'calories': 35, 'duration': 45},
          {'title': 'Nhảy Burpees đốt mỡ', 'calories': 90, 'duration': 45},
          {'title': 'Leo núi Mountain Climbers', 'calories': 65, 'duration': 45},
          {'title': 'Chùng chân Lunges', 'calories': 95, 'duration': 45},
          {'title': 'Hít đất kim cương', 'calories': 75, 'duration': 45},
          {'title': 'Vặn bụng Russian Twists', 'calories': 55, 'duration': 45},
          {'title': 'Squat mông đùi', 'calories': 90, 'duration': 45},
          {'title': 'Cầu mông Glute Bridges', 'calories': 65, 'duration': 45},
          {'title': 'Đạp xe gập bụng Bicycle', 'calories': 55, 'duration': 45},
          {'title': 'Nhảy Jumping Jacks', 'calories': 70, 'duration': 45},
          {'title': 'Đá mông Donkey Kicks', 'calories': 60, 'duration': 45},
          {'title': 'Giãn cơ Yoga dẻo dai', 'calories': 60, 'duration': 45},
        ]
      : [
          {'title': 'Push-ups', 'calories': 120, 'duration': 45},
          {'title': 'Pull-ups', 'calories': 110, 'duration': 45},
          {'title': 'Crunches', 'calories': 50, 'duration': 45},
          {'title': 'High-intensity Plank', 'calories': 35, 'duration': 45},
          {'title': 'Burpees (Full Body Fat Burn)', 'calories': 90, 'duration': 45},
          {'title': 'Mountain Climbers', 'calories': 65, 'duration': 45},
          {'title': 'Jumping Lunges', 'calories': 95, 'duration': 45},
          {'title': 'Diamond Push-ups', 'calories': 75, 'duration': 45},
          {'title': 'Russian Twists', 'calories': 55, 'duration': 45},
          {'title': 'Squats (Glutes & Legs)', 'calories': 90, 'duration': 45},
          {'title': 'Glute Bridges', 'calories': 65, 'duration': 45},
          {'title': 'Bicycle Crunches', 'calories': 55, 'duration': 45},
          {'title': 'Jumping Jacks', 'calories': 70, 'duration': 45},
          {'title': 'Donkey Kicks', 'calories': 60, 'duration': 45},
          {'title': 'Reverse Lunges', 'calories': 70, 'duration': 45},
          {'title': 'Yoga Flexibility Stretch', 'calories': 60, 'duration': 45},
        ];

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _currentCalories = widget.estimatedCalories;
    _totalSeconds = widget.durationSeconds;
    _remainingSeconds = _totalSeconds;
    _startTimer();
  }

  void _switchExercise(String newTitle, int calories) {
    setState(() {
      _currentTitle = newTitle;
      _currentCalories = calories;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          AppHaptics.light();
        }
      } else {
        _timer?.cancel();
        AppHaptics.heavy();
        _finishWorkout();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    _startTimer();
  }

  void _addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
      _totalSeconds += seconds;
    });
  }

  void _finishWorkout() {
    _timer?.cancel();
    final elapsedSeconds = _totalSeconds - _remainingSeconds;
    final durationMinutes = elapsedSeconds > 0 ? (elapsedSeconds + 59) ~/ 60 : 1;
    StorageService.logCompletedWorkout(
      durationMinutes: durationMinutes,
      title: _currentTitle,
      calories: _currentCalories,
    );
    AppHaptics.success();
    AchievementService.checkBadges();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
    _showCompletionDialog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.orange,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  LocaleService.tr('workout_great_job'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleService.tr('workout_completed_desc', args: {'title': _currentTitle}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '~$_currentCalories kcal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            LocaleService.tr('burned_label'),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 35, color: Colors.white12),
                      Column(
                        children: [
                          const Icon(Icons.timer, color: Color(0xFF00C6FF), size: 24),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_totalSeconds - _remainingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            LocaleService.tr('workout_time_label'),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Return to workouts
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      LocaleService.tr('finish_btn'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmExit() {
    if (_isCompleted) {
      Navigator.of(context).pop();
      return;
    }

    _pauseTimer();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(LocaleService.tr('exit_workout_title'), style: const TextStyle(color: Colors.white)),
        content: Text(
          LocaleService.tr('exit_workout_content'),
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeTimer();
            },
            child: Text(LocaleService.tr('continue_btn'), style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(LocaleService.tr('exit_btn'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _totalSeconds > 0
        ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final guide = ExerciseGuideData.getForExercise(_currentTitle);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: _confirmExit,
          ),
          title: Text(
            _currentTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  // Danh sách chọn nhanh động tác mẫu khác (Quick Exercise Switcher)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sampleExercises.map((sample) {
                        final isSelected = sample['title'] == _currentTitle;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(sample['title'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _switchExercise(
                                  sample['title'] as String,
                                  sample['calories'] as int,
                                );
                              }
                            },
                            selectedColor: AppTheme.primaryColor,
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Khung mô phỏng động tác mẫu (100% Offline Canvas Vector Animation)
                  ExercisePoseAnimator(
                    exerciseTitle: _currentTitle,
                    isPlaying: _isRunning,
                    height: 160,
                  ),

                  const SizedBox(height: 16),

                  // Bộ đếm thời gian tròn (Circular Countdown Timer)
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 10.0,
                    percent: progress,
                    animation: false,
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: Colors.white12,
                    progressColor: _remainingSeconds <= 10
                        ? Colors.redAccent
                        : guide.themeColor,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: _remainingSeconds <= 10
                                ? Colors.redAccent
                                : Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isRunning ? LocaleService.tr('in_progress_label') : LocaleService.tr('paused_label'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: _isRunning
                                ? guide.themeColor
                                : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Interactive Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // +30s Button
                      IconButton.filledTonal(
                        onPressed: () => _addTime(30),
                        icon: const Text(
                          '+30s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(width: 25),

                      // Pause / Resume Button
                      GestureDetector(
                        onTap: () {
                          if (_isRunning) {
                            _pauseTimer();
                          } else {
                            _resumeTimer();
                          }
                        },
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: guide.themeColor,
                            boxShadow: [
                              BoxShadow(
                                color: guide.themeColor.withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Icon(
                            _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),

                      // Early Finish Button
                      IconButton.filledTonal(
                        onPressed: _finishWorkout,
                        icon: const Icon(
                          Icons.done_all_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.all(14),
                        ),
                        tooltip: 'Finish',
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Form Checklist & Breathing Guide
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: guide.themeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: guide.themeColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedIdea01,
                                color: guide.themeColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              LocaleService.tr('form_guide_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Target Muscles
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF453A).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFFFF453A).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedBodyPartMuscle,
                                color: Color(0xFFFF453A),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${LocaleService.tr('target_muscles_label')} ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text: guide.targetMuscles,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Breathing
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedLungs,
                                color: Color(0xFF00F0FF),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${LocaleService.tr('breathing_label')} ',
                                        style: const TextStyle(
                                          color: Color(0xFF00F0FF),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text: guide.breathingTip,
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 10),
                        // Các bước thực hiện
                        ...guide.steps.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: guide.themeColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      color: guide.themeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
