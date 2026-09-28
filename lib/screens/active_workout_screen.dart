import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../widgets/exercise_pose_widget.dart';
import '../widgets/app_ui_components.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import '../services/achievement_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String title;
  final int durationSeconds;
  final int estimatedCalories;
  final String lottieUrl;
  final String? equipment;
  final bool isRepsBased;
  final int targetSets;
  final int targetReps;
  final double? weightKg;
  final int restDurationSeconds;

  const ActiveWorkoutScreen({
    super.key,
    required this.title,
    this.durationSeconds = 60,
    required this.estimatedCalories,
    this.lottieUrl = '',
    this.equipment,
    this.isRepsBased = false,
    this.targetSets = 3,
    this.targetReps = 12,
    this.weightKg,
    this.restDurationSeconds = 60,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // Timer Mode state
  Timer? _timer;
  late int _remainingSeconds;
  late int _totalSeconds;
  bool _isRunning = true;
  bool _isCompleted = false;

  // Reps & Sets Mode state
  late bool _isRepsMode;
  int _currentSet = 1;
  late int _targetSets;
  int _currentReps = 0;
  late int _targetReps;
  double? _weightKg;
  String? _equipment;
  late int _restDurationSeconds;
  bool _isResting = false;
  int _restRemainingSeconds = 0;
  Timer? _restTimer;
  int _elapsedWorkoutSeconds = 0;
  Timer? _workoutElapsedTimer;

  bool get _hasWeight =>
      (_equipment == 'dumbbell' || ExerciseGuideData.getForExercise(_currentTitle).isDumbbell) &&
      _weightKg != null &&
      _weightKg! > 0;

  late String _currentTitle;
  late int _currentCalories;

  List<Map<String, dynamic>> get _sampleExercises => LocaleService.isVietnamese
      ? [
          {'title': 'Hít đất', 'calories': 120, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Đẩy ngực tạ đơn', 'calories': 115, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 10.0},
          {'title': 'Đẩy vai qua đầu', 'calories': 105, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 8.0},
          {'title': 'Cuốn tạ tay trước', 'calories': 85, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 8.0},
          {'title': 'Kéo tạ lưng xô', 'calories': 110, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 10.0},
          {'title': 'Squat ôm tạ Goblet', 'calories': 130, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 12.0},
          {'title': 'Deadlift tạ đơn RDL', 'calories': 125, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 14.0},
          {'title': 'Dang tạ ngang', 'calories': 75, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 5.0},
          {'title': 'Cầu mông đặt tạ', 'calories': 85, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 8.0},
          {'title': 'Hít xà đơn', 'calories': 110, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Gập bụng', 'calories': 50, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Plank siết cơ bụng', 'calories': 35, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Nhảy Burpees đốt mỡ', 'calories': 90, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Leo núi Mountain Climbers', 'calories': 65, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Chùng chân Lunges', 'calories': 95, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Hít đất kim cương', 'calories': 75, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Vặn bụng Russian Twists', 'calories': 55, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Squat mông đùi', 'calories': 90, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Cầu mông Glute Bridges', 'calories': 65, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Đạp xe gập bụng Bicycle', 'calories': 55, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Nhảy Jumping Jacks', 'calories': 70, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Đá mông Donkey Kicks', 'calories': 60, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Giãn cơ Yoga dẻo dai', 'calories': 60, 'duration': 45, 'equipment': 'bodyweight'},
        ]
      : [
          {'title': 'Push-ups', 'calories': 120, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Dumbbell Floor Press', 'calories': 115, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 10.0},
          {'title': 'Dumbbell Shoulder Press', 'calories': 105, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 8.0},
          {'title': 'Dumbbell Bicep Curls', 'calories': 85, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 8.0},
          {'title': 'Dumbbell Bent-Over Row', 'calories': 110, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 10.0},
          {'title': 'Dumbbell Goblet Squat', 'calories': 130, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 12.0},
          {'title': 'Dumbbell Romanian Deadlift', 'calories': 125, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 14.0},
          {'title': 'Dumbbell Lateral Raises', 'calories': 75, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 5.0},
          {'title': 'Dumbbell Hip Thrust', 'calories': 85, 'duration': 45, 'isReps': true, 'equipment': 'dumbbell', 'weight': 8.0},
          {'title': 'Pull-ups', 'calories': 110, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Crunches', 'calories': 50, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'High-intensity Plank', 'calories': 35, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Burpees (Full Body Fat Burn)', 'calories': 90, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Mountain Climbers', 'calories': 65, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Jumping Lunges', 'calories': 95, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Diamond Push-ups', 'calories': 75, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Russian Twists', 'calories': 55, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Squats (Glutes & Legs)', 'calories': 90, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Glute Bridges', 'calories': 65, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Bicycle Crunches', 'calories': 55, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Jumping Jacks', 'calories': 70, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Donkey Kicks', 'calories': 60, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Reverse Lunges', 'calories': 70, 'duration': 45, 'equipment': 'bodyweight'},
          {'title': 'Yoga Flexibility Stretch', 'calories': 60, 'duration': 45, 'equipment': 'bodyweight'},
        ];

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _currentCalories = widget.estimatedCalories;
    _totalSeconds = widget.durationSeconds;
    _remainingSeconds = _totalSeconds;

    _isRepsMode = widget.isRepsBased;
    _targetSets = widget.targetSets;
    _targetReps = widget.targetReps;
    _restDurationSeconds = widget.restDurationSeconds;

    final guide = ExerciseGuideData.getForExercise(widget.title);
    final isDumbbell = widget.equipment != null
        ? widget.equipment == 'dumbbell'
        : (guide.isDumbbell || (widget.weightKg != null && widget.weightKg! > 0));

    _equipment = isDumbbell ? 'dumbbell' : 'bodyweight';
    if (isDumbbell) {
      _weightKg = widget.weightKg ?? 8.0;
    } else {
      _weightKg = null;
    }

    _startElapsedTimer();
    if (!_isRepsMode) {
      _startTimer();
    }
  }

  void _switchExercise(
    String newTitle,
    int calories, {
    bool? isReps,
    String? equipment,
    double? weight,
  }) {
    setState(() {
      _currentTitle = newTitle;
      _currentCalories = calories;

      final guide = ExerciseGuideData.getForExercise(newTitle);
      final isDumbbell = equipment != null ? equipment == 'dumbbell' : guide.isDumbbell;
      _equipment = isDumbbell ? 'dumbbell' : 'bodyweight';
      if (isDumbbell) {
        _weightKg = weight ?? 8.0;
      } else {
        _weightKg = null;
      }

      if (isReps != null) {
        _isRepsMode = isReps;
        _currentSet = 1;
        _currentReps = 0;
        _isResting = false;
        _restTimer?.cancel();
        if (_isRepsMode) {
          _timer?.cancel();
        } else {
          _remainingSeconds = _totalSeconds;
          _startTimer();
        }
      }
    });
  }

  void _startElapsedTimer() {
    _workoutElapsedTimer?.cancel();
    _workoutElapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && !_isCompleted) {
        setState(() {
          _elapsedWorkoutSeconds++;
        });
      }
    });
  }

  void _toggleMode() {
    AppHaptics.medium();
    setState(() {
      _isRepsMode = !_isRepsMode;
      if (_isRepsMode) {
        _timer?.cancel();
      } else {
        _restTimer?.cancel();
        _isResting = false;
        _remainingSeconds = _totalSeconds;
        _startTimer();
      }
    });
  }

  void _completeCurrentSet() {
    AppHaptics.heavy();
    if (_currentSet < _targetSets) {
      setState(() {
        _isResting = true;
        _restRemainingSeconds = _restDurationSeconds;
      });
      _startRestTimer();
    } else {
      _finishWorkout();
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemainingSeconds > 0) {
        setState(() {
          _restRemainingSeconds--;
        });
        if (_restRemainingSeconds <= 3 && _restRemainingSeconds > 0) {
          AppHaptics.light();
        }
      } else {
        _restTimer?.cancel();
        AppHaptics.success();
        _skipRest();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    AppHaptics.selection();
    setState(() {
      _isResting = false;
      _currentSet++;
      _currentReps = 0;
    });
  }

  void _addRestTime(int seconds) {
    AppHaptics.selection();
    setState(() {
      _restRemainingSeconds += seconds;
    });
  }

  void _adjustReps(int delta) {
    AppHaptics.selection();
    setState(() {
      _currentReps = (_currentReps + delta).clamp(0, 99);
    });
  }

  void _adjustWeight(double delta) {
    if (_weightKg == null) return;
    AppHaptics.selection();
    setState(() {
      _weightKg = (_weightKg! + delta).clamp(1.0, 100.0);
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
    _restTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    if (!_isRepsMode) {
      _startTimer();
    } else if (_isResting) {
      _startRestTimer();
    }
  }

  void _addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
      _totalSeconds += seconds;
    });
  }

  void _finishWorkout() {
    _timer?.cancel();
    _restTimer?.cancel();
    _workoutElapsedTimer?.cancel();

    final elapsedSeconds = _isRepsMode
        ? _elapsedWorkoutSeconds
        : (_totalSeconds - _remainingSeconds);
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
    _restTimer?.cancel();
    _workoutElapsedTimer?.cancel();
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              fontSize: 15,
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
                            _isRepsMode
                                ? _formatTime(_elapsedWorkoutSeconds)
                                : _formatTime(_totalSeconds - _remainingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            LocaleService.tr('workout_time_label'),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      if (_isRepsMode) ...[
                        Container(width: 1, height: 35, color: Colors.white12),
                        Column(
                          children: [
                            const Icon(Icons.repeat_rounded, color: Color(0xFFFF9F0A), size: 24),
                            const SizedBox(height: 4),
                            Text(
                              '$_targetSets × $_targetReps',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Text(
                              'Sets × Reps',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                        if (_hasWeight) ...[
                          Container(width: 1, height: 35, color: Colors.white12),
                          Column(
                            children: [
                              const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF2D55), size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '${_weightKg!.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                LocaleService.isVietnamese ? 'Mức tạ' : 'Weight',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(width: 1, height: 35, color: Colors.white12),
                          Column(
                            children: [
                              const Icon(Icons.accessibility_new_rounded, color: Color(0xFF00E5FF), size: 24),
                              const SizedBox(height: 4),
                              Text(
                                LocaleService.isVietnamese ? 'Tự do' : 'Bodyweight',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                LocaleService.isVietnamese ? 'Hình thức' : 'Type',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ],
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                tooltip: _isRepsMode
                    ? LocaleService.tr('switch_to_timer_mode')
                    : LocaleService.tr('switch_to_reps_mode'),
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isRepsMode
                        ? const Color(0xFFFF9F0A).withValues(alpha: 0.2)
                        : const Color(0xFF00C6FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isRepsMode ? const Color(0xFFFF9F0A) : const Color(0xFF00C6FF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRepsMode ? Icons.repeat_rounded : Icons.timer_outlined,
                        color: _isRepsMode ? const Color(0xFFFF9F0A) : const Color(0xFF00C6FF),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isRepsMode ? 'Reps' : 'Timer',
                        style: TextStyle(
                          color: _isRepsMode ? const Color(0xFFFF9F0A) : const Color(0xFF00C6FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                onPressed: _toggleMode,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  // Quick Exercise Switcher Chips
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
                                  isReps: sample['isReps'] as bool?,
                                  equipment: sample['equipment'] as String?,
                                  weight: (sample['weight'] as num?)?.toDouble(),
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
                    isPlaying: _isRunning && !_isResting,
                    height: 155,
                  ),

                  const SizedBox(height: 16),

                  // Dual Mode Display: Reps & Sets Mode vs Countdown Timer Mode
                  if (_isRepsMode) ...[
                    if (_isResting) ...[
                      // Rest Interval Screen
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.nightlight_round, color: Color(0xFF00F0FF), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  LocaleService.tr('rest_timer_title'),
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CircularPercentIndicator(
                              radius: 72.0,
                              lineWidth: 9.0,
                              percent: _restDurationSeconds > 0
                                  ? (_restRemainingSeconds / _restDurationSeconds).clamp(0.0, 1.0)
                                  : 0.0,
                              animation: false,
                              circularStrokeCap: CircularStrokeCap.round,
                              backgroundColor: Colors.white12,
                              progressColor: const Color(0xFF00F0FF),
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_restRemainingSeconds}s',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    LocaleService.tr('set_indicator', args: {
                                      'current': '${_currentSet + 1}',
                                      'total': '$_targetSets',
                                    }),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              LocaleService.tr('rest_timer_sub'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _addRestTime(15),
                                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                  label: Text(LocaleService.tr('add_15s_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white24),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                ElevatedButton.icon(
                                  onPressed: _skipRest,
                                  icon: const Icon(Icons.skip_next_rounded, size: 18, color: Colors.black),
                                  label: Text(LocaleService.tr('skip_rest_btn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00F0FF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Active Reps & Sets Controller
                      Column(
                        children: [
                          // Sets segmented pills (Horizontally scrollable to prevent overflow on any number of sets)
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_targetSets, (index) {
                                  final setNum = index + 1;
                                  final isDone = setNum < _currentSet;
                                  final isCurrent = setNum == _currentSet;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? const Color(0xFF30D158).withValues(alpha: 0.2)
                                          : isCurrent
                                              ? AppTheme.primaryColor.withValues(alpha: 0.25)
                                              : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDone
                                            ? const Color(0xFF30D158)
                                            : isCurrent
                                                ? AppTheme.primaryColor
                                                : Colors.white12,
                                        width: isCurrent ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isDone) ...[
                                          const Icon(Icons.check, size: 12, color: Color(0xFF30D158)),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          'Set $setNum',
                                          style: TextStyle(
                                            color: isDone
                                                ? const Color(0xFF30D158)
                                                : isCurrent
                                                    ? Colors.white
                                                    : Colors.grey,
                                            fontSize: 11,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Interactive Reps Counter Circle with Touch to Count
                          BouncingTap(
                            hapticType: AppHapticFeedbackType.selection,
                            scaleDown: 0.94,
                            onTap: () {
                              setState(() {
                                _currentReps++;
                              });
                            },
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    guide.themeColor.withValues(alpha: 0.35),
                                    guide.themeColor.withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: guide.themeColor.withValues(alpha: 0.7),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: guide.themeColor.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_currentReps',
                                    style: const TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '/ $_targetReps reps',
                                    style: TextStyle(
                                      color: guide.themeColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+1 Rep',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            LocaleService.tr('rep_tap_instruction'),
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                          ),
                          const SizedBox(height: 14),
                          // Reps & Weight Adjuster Row
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              // Rep adjust
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                                      onPressed: () => _adjustReps(-1),
                                    ),
                                    Text(
                                      '$_currentReps Reps',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                                      onPressed: () => _adjustReps(1),
                                    ),
                                  ],
                                ),
                              ),
                              if (_hasWeight)
                                // Weight adjust
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                                        onPressed: () => _adjustWeight(-1.0),
                                      ),
                                      Text(
                                        '${_weightKg!.toStringAsFixed(1)} kg',
                                        style: const TextStyle(color: Color(0xFFFF9F0A), fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                                        onPressed: () => _adjustWeight(1.0),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                // Bodyweight indicator badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.accessibility_new_rounded, size: 16, color: Color(0xFF00E5FF)),
                                      const SizedBox(width: 6),
                                      Text(
                                        LocaleService.isVietnamese ? 'Tự do (Bodyweight)' : 'Bodyweight',
                                        style: const TextStyle(
                                          color: Color(0xFF00E5FF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 18),
                          // Complete Set Button
                          SizedBox(
                            width: double.infinity,
                            child: BouncingTap(
                              hapticType: AppHapticFeedbackType.heavy,
                              scaleDown: 0.96,
                              onTap: _completeCurrentSet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _currentSet == _targetSets
                                        ? [const Color(0xFFFF3B30), const Color(0xFFFF9500)]
                                        : [guide.themeColor, guide.themeColor.withValues(alpha: 0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: guide.themeColor.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _currentSet == _targetSets ? Icons.local_fire_department_rounded : Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currentSet == _targetSets
                                          ? LocaleService.tr('all_sets_finished_btn')
                                          : LocaleService.tr('finish_set_btn', args: {'set': '$_currentSet'}),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 1.0,
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
                  ] else ...[
                    // Standard Circular Countdown Timer
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
                  ],

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
