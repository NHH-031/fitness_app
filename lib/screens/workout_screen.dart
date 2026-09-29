import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../widgets/exercise_pose_widget.dart';
import '../widgets/weekly_activity_widget.dart';
import '../widgets/ai_coach_card_widget.dart';
import '../widgets/badges_achievement_widget.dart';
import '../widgets/app_ui_components.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../widgets/workout_setup_sheet.dart';
import '../widgets/muscle_anatomy_map_widget.dart';
import '../widgets/exercise_guide_sheet.dart';
import 'active_workout_screen.dart';

enum ExerciseEquipmentFilter { all, bodyweight, dumbbell }

class WorkoutExercise {
  final String title;
  final String duration;
  final String calories;
  final String equipment; // 'bodyweight' | 'dumbbell'
  final bool isReps;
  final int targetSets;
  final int targetReps;
  final double? weightKg;
  final int durationSeconds;
  final int restSeconds;

  const WorkoutExercise({
    required this.title,
    required this.duration,
    required this.calories,
    required this.equipment,
    this.isReps = true,
    this.targetSets = 3,
    this.targetReps = 12,
    this.weightKg,
    this.durationSeconds = 45,
    this.restSeconds = 60,
  });

  int get caloriesValue {
    final match = RegExp(r'\d+').firstMatch(calories);
    return match != null ? int.parse(match.group(0)!) : 50;
  }
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // true = Men, false = Women
  bool _isMale = true;
  ExerciseEquipmentFilter _selectedEquipment = ExerciseEquipmentFilter.all;

  final GlobalKey<WeeklyActivityWidgetState> _weeklyKey = GlobalKey();
  final GlobalKey<BadgesAchievementWidgetState> _badgesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserGender();
    StorageService.workoutUpdateNotifier.addListener(_onDataUpdated);
    StorageService.profileUpdateNotifier.addListener(_onDataUpdated);
  }

  @override
  void dispose() {
    StorageService.workoutUpdateNotifier.removeListener(_onDataUpdated);
    StorageService.profileUpdateNotifier.removeListener(_onDataUpdated);
    super.dispose();
  }

  void _onDataUpdated() {
    _loadUserGender();
    _refreshStats();
  }

  Future<void> _loadUserGender() async {
    final profile = await StorageService.getUserProfile();
    if (mounted) {
      setState(() {
        _isMale = profile.gender != 'female';
      });
    }
  }

  List<WorkoutExercise> get _maleExercises => LocaleService.isVietnamese
      ? [
          // Bodyweight (9 bài tập thể trọng chuẩn nam giới)
          const WorkoutExercise(
            title: 'Hít đất',
            duration: '3 hiệp × 15 reps',
            calories: '120 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
          ),
          const WorkoutExercise(
            title: 'Hít xà đơn',
            duration: '3 hiệp × 8 reps',
            calories: '110 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 8,
          ),
          const WorkoutExercise(
            title: 'Hít đất kim cương',
            duration: '3 hiệp × 12 reps',
            calories: '75 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
          ),
          const WorkoutExercise(
            title: 'Gập bụng',
            duration: '3 hiệp × 20 reps',
            calories: '50 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          const WorkoutExercise(
            title: 'Plank siết cơ bụng',
            duration: '3 phút',
            calories: '35 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Nhảy Burpees đốt mỡ',
            duration: '6 phút',
            calories: '90 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Leo núi Mountain Climbers',
            duration: '5 phút',
            calories: '65 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Chùng chân Lunges',
            duration: '3 hiệp × 12 reps',
            calories: '95 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
          ),
          const WorkoutExercise(
            title: 'Vặn bụng Russian Twists',
            duration: '3 hiệp × 20 reps',
            calories: '55 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          // Dumbbells (8 bài tập tạ tăng cơ nam: ngực, vai, lưng xô, tay, chân)
          const WorkoutExercise(
            title: 'Đẩy ngực tạ đơn',
            duration: '3 hiệp × 12 reps (10kg)',
            calories: '115 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 10.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Đẩy vai qua đầu',
            duration: '3 hiệp × 10 reps (8kg)',
            calories: '105 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 10,
            weightKg: 8.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Kéo tạ lưng xô',
            duration: '3 hiệp × 12 reps (10kg)',
            calories: '110 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 10.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Cuốn tạ tay trước',
            duration: '3 hiệp × 12 reps (8kg)',
            calories: '85 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 8.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Squat ôm tạ Goblet',
            duration: '3 hiệp × 12 reps (12kg)',
            calories: '130 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 12.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Deadlift tạ đơn RDL',
            duration: '3 hiệp × 10 reps (14kg)',
            calories: '125 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 10,
            weightKg: 14.0,
            restSeconds: 75,
          ),
          const WorkoutExercise(
            title: 'Dang tạ ngang',
            duration: '3 hiệp × 15 reps (5kg)',
            calories: '75 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
            weightKg: 5.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Đưa tạ sau đầu bắp tay sau',
            duration: '3 hiệp × 12 reps (8kg)',
            calories: '80 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 8.0,
            restSeconds: 45,
          ),
        ]
      : [
          // English Male Exercises
          const WorkoutExercise(
            title: 'Push-ups',
            duration: '3 sets × 15 reps',
            calories: '120 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
          ),
          const WorkoutExercise(
            title: 'Pull-ups',
            duration: '3 sets × 8 reps',
            calories: '110 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 8,
          ),
          const WorkoutExercise(
            title: 'Diamond Push-ups',
            duration: '3 sets × 12 reps',
            calories: '75 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
          ),
          const WorkoutExercise(
            title: 'Crunches',
            duration: '3 sets × 20 reps',
            calories: '50 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          const WorkoutExercise(
            title: 'High-intensity Plank',
            duration: '3 Mins',
            calories: '35 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Burpees (Full Body Fat Burn)',
            duration: '6 Mins',
            calories: '90 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Mountain Climbers',
            duration: '5 Mins',
            calories: '65 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Jumping Lunges',
            duration: '3 sets × 12 reps',
            calories: '95 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
          ),
          const WorkoutExercise(
            title: 'Russian Twists',
            duration: '3 sets × 20 reps',
            calories: '55 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Floor Press',
            duration: '3 sets × 12 reps (10kg)',
            calories: '115 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 10.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Shoulder Press',
            duration: '3 sets × 10 reps (8kg)',
            calories: '105 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 10,
            weightKg: 8.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Bent-Over Row',
            duration: '3 sets × 12 reps (10kg)',
            calories: '110 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 10.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Bicep Curls',
            duration: '3 sets × 12 reps (8kg)',
            calories: '85 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 8.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Goblet Squat',
            duration: '3 sets × 12 reps (12kg)',
            calories: '130 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 12.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Romanian Deadlift',
            duration: '3 sets × 10 reps (14kg)',
            calories: '125 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 10,
            weightKg: 14.0,
            restSeconds: 75,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Lateral Raises',
            duration: '3 sets × 15 reps (5kg)',
            calories: '75 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
            weightKg: 5.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Overhead Triceps Extension',
            duration: '3 sets × 12 reps (8kg)',
            calories: '80 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 8.0,
            restSeconds: 45,
          ),
        ];

  List<WorkoutExercise> get _femaleExercises => LocaleService.isVietnamese
      ? [
          // Bodyweight (8 bài tập nữ săn chắc thon gọn)
          const WorkoutExercise(
            title: 'Squat mông đùi',
            duration: '3 hiệp × 15 reps',
            calories: '90 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
          ),
          const WorkoutExercise(
            title: 'Cầu mông Glute Bridges',
            duration: '3 hiệp × 20 reps',
            calories: '65 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          const WorkoutExercise(
            title: 'Đá mông Donkey Kicks',
            duration: '3 hiệp × 15 reps',
            calories: '60 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
          ),
          const WorkoutExercise(
            title: 'Đạp xe gập bụng Bicycle',
            duration: '3 hiệp × 20 reps',
            calories: '55 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          const WorkoutExercise(
            title: 'Plank siết cơ bụng',
            duration: '3 phút',
            calories: '25 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Nhảy Jumping Jacks',
            duration: '7 phút',
            calories: '70 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Chùng chân Lunges',
            duration: '3 hiệp × 12 reps',
            calories: '70 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
          ),
          const WorkoutExercise(
            title: 'Giãn cơ Yoga dẻo dai',
            duration: '15 phút',
            calories: '60 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 90,
          ),
          // Dumbbells (8 bài tập tạ chuyên biệt vòng 3 & eo thon cho nữ)
          const WorkoutExercise(
            title: 'Cầu mông đặt tạ',
            duration: '3 hiệp × 15 reps (6kg)',
            calories: '85 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
            weightKg: 6.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Deadlift tạ đơn RDL',
            duration: '3 hiệp × 12 reps (6kg)',
            calories: '95 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 6.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Squat tạ đơn (Sumo / Goblet)',
            duration: '3 hiệp × 12 reps (8kg)',
            calories: '100 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 8.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Squat ôm tạ Goblet',
            duration: '3 hiệp × 12 reps (6kg)',
            calories: '95 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 6.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Chùng chân Lunges',
            duration: '3 hiệp × 10 reps (4kg)',
            calories: '90 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 10,
            weightKg: 4.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dang tạ ngang',
            duration: '3 hiệp × 12 reps (2kg)',
            calories: '60 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 2.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Kéo tạ lưng xô',
            duration: '3 hiệp × 12 reps (4kg)',
            calories: '75 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 4.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Cuốn tạ tay trước',
            duration: '3 hiệp × 12 reps (3kg)',
            calories: '65 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 3.0,
            restSeconds: 45,
          ),
        ]
      : [
          // English Female Exercises
          const WorkoutExercise(
            title: 'Squats (Glutes & Legs)',
            duration: '3 sets × 15 reps',
            calories: '90 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
          ),
          const WorkoutExercise(
            title: 'Glute Bridges',
            duration: '3 sets × 20 reps',
            calories: '65 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          const WorkoutExercise(
            title: 'Donkey Kicks',
            duration: '3 sets × 15 reps',
            calories: '60 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
          ),
          const WorkoutExercise(
            title: 'Bicycle Crunches',
            duration: '3 sets × 20 reps',
            calories: '55 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 20,
          ),
          const WorkoutExercise(
            title: 'Knee Plank (Gentle Core)',
            duration: '3 Mins',
            calories: '25 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Jumping Jacks',
            duration: '7 Mins',
            calories: '70 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Reverse Lunges',
            duration: '3 sets × 12 reps',
            calories: '70 kcal',
            equipment: 'bodyweight',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
          ),
          const WorkoutExercise(
            title: 'Yoga Flexibility Stretch',
            duration: '15 Mins',
            calories: '60 kcal',
            equipment: 'bodyweight',
            isReps: false,
            durationSeconds: 90,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Hip Thrust',
            duration: '3 sets × 15 reps (6kg)',
            calories: '85 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 15,
            weightKg: 6.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Romanian Deadlift',
            duration: '3 sets × 12 reps (6kg)',
            calories: '95 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 6.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Sumo / Goblet Squat',
            duration: '3 sets × 12 reps (8kg)',
            calories: '100 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 8.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Goblet Squat',
            duration: '3 sets × 12 reps (6kg)',
            calories: '95 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 6.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Reverse Lunges',
            duration: '3 sets × 10 reps (4kg)',
            calories: '90 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 10,
            weightKg: 4.0,
            restSeconds: 60,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Lateral Raises',
            duration: '3 sets × 12 reps (2kg)',
            calories: '60 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 2.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Bent-Over Row',
            duration: '3 sets × 12 reps (4kg)',
            calories: '75 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 4.0,
            restSeconds: 45,
          ),
          const WorkoutExercise(
            title: 'Dumbbell Bicep Curls',
            duration: '3 sets × 12 reps (3kg)',
            calories: '65 kcal',
            equipment: 'dumbbell',
            isReps: true,
            targetSets: 3,
            targetReps: 12,
            weightKg: 3.0,
            restSeconds: 45,
          ),
        ];

  List<WorkoutExercise> get _filteredExercises {
    final list = _isMale ? _maleExercises : _femaleExercises;
    if (_selectedEquipment == ExerciseEquipmentFilter.bodyweight) {
      return list.where((e) => e.equipment == 'bodyweight').toList();
    } else if (_selectedEquipment == ExerciseEquipmentFilter.dumbbell) {
      return list.where((e) => e.equipment == 'dumbbell').toList();
    }
    return list;
  }

  void _refreshStats() {
    _weeklyKey.currentState?.refreshData();
    _badgesKey.currentState?.refreshBadges();
  }

  Widget _buildFilterChip({
    required ExerciseEquipmentFilter filter,
    required String label,
    required int count,
    required List<List<dynamic>> icon,
  }) {
    final isSelected = _selectedEquipment == filter;
    return Expanded(
      child: BouncingTap(
        hapticType: AppHapticFeedbackType.selection,
        scaleDown: 0.95,
        onTap: () {
          setState(() {
            _selectedEquipment = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                '$label ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allList = _isMale ? _maleExercises : _femaleExercises;
    final currentExercises = _filteredExercises;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('activity_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr('activity_subtitle'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDumbbell01,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 1. Weekly Goal & Heatmap Widget
            WeeklyActivityWidget(key: _weeklyKey),

            const SizedBox(height: 20),

            // 2. AI Personal Coach Card Widget
            AiCoachCardWidget(
              onWorkoutStarted: () {
                Future.delayed(const Duration(milliseconds: 500), _refreshStats);
              },
            ),

            const SizedBox(height: 20),

            // 3. Badges & Achievements Widget
            BadgesAchievementWidget(key: _badgesKey),

            const SizedBox(height: 24),

            // 4. Interactive Muscle Anatomy Map (v2.0) with Male & Female Support
            MuscleAnatomyMapWidget(
              initialIsMale: _isMale,
              onGenderChanged: (isMale) {
                setState(() {
                  _isMale = isMale;
                });
              },
            ),

            const SizedBox(height: 28),

            // 5. Exercises Header with Gender Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('bodyweight_exercises_title'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isMale
                          ? LocaleService.tr('target_male_sub')
                          : LocaleService.tr('target_female_sub'),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                // Gender Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      BouncingTap(
                        hapticType: AppHapticFeedbackType.selection,
                        scaleDown: 0.94,
                        onTap: () => setState(() => _isMale = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _isMale ? AppTheme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            LocaleService.tr('gender_men'),
                            style: TextStyle(
                              color: _isMale ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      BouncingTap(
                        hapticType: AppHapticFeedbackType.selection,
                        scaleDown: 0.94,
                        onTap: () => setState(() => _isMale = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: !_isMale ? AppTheme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            LocaleService.tr('gender_women'),
                            style: TextStyle(
                              color: !_isMale ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 5. Equipment Filter Bar (Tất cả / Tự do / Tạ đơn)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  _buildFilterChip(
                    filter: ExerciseEquipmentFilter.all,
                    label: LocaleService.tr('filter_all'),
                    count: allList.length,
                    icon: HugeIcons.strokeRoundedLayers01,
                  ),
                  _buildFilterChip(
                    filter: ExerciseEquipmentFilter.bodyweight,
                    label: LocaleService.tr('filter_bodyweight'),
                    count: allList.where((e) => e.equipment == 'bodyweight').length,
                    icon: HugeIcons.strokeRoundedBodyPartMuscle,
                  ),
                  _buildFilterChip(
                    filter: ExerciseEquipmentFilter.dumbbell,
                    label: LocaleService.tr('filter_dumbbells'),
                    count: allList.where((e) => e.equipment == 'dumbbell').length,
                    icon: HugeIcons.strokeRoundedDumbbell01,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Standard & Dumbbell Exercises Cards
            ...currentExercises.map((ex) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  // Equipment badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ex.equipment == 'dumbbell'
                                          ? const Color(0xFFFF9F0A).withValues(alpha: 0.18)
                                          : const Color(0xFF00F0FF).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: ex.equipment == 'dumbbell'
                                            ? const Color(0xFFFF9F0A).withValues(alpha: 0.5)
                                            : const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          ex.equipment == 'dumbbell'
                                              ? Icons.fitness_center_rounded
                                              : Icons.accessibility_new_rounded,
                                          size: 11,
                                          color: ex.equipment == 'dumbbell'
                                              ? const Color(0xFFFF9F0A)
                                              : const Color(0xFF00F0FF),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ex.equipment == 'dumbbell'
                                              ? LocaleService.tr('equipment_badge_dumbbell')
                                              : LocaleService.tr('equipment_badge_bodyweight'),
                                          style: TextStyle(
                                            color: ex.equipment == 'dumbbell'
                                                ? const Color(0xFFFF9F0A)
                                                : const Color(0xFF00F0FF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Reps / Time mode tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ex.isReps
                                          ? LocaleService.tr('mode_reps_tag')
                                          : LocaleService.tr('mode_time_tag'),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            ex.duration,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ExercisePoseAnimator(
                      exerciseTitle: ex.title,
                      height: 135,
                      isMale: _isMale,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedBodyPartMuscle,
                                  color: Color(0xFFFF453A),
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    ExerciseGuideData.getForExercise(ex.title).targetMuscles,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => ExerciseGuideSheet.show(context, exerciseTitle: ex.title, isMale: _isMale),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book, color: Color(0xFF00F0FF), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Kỹ thuật chuẩn',
                                  style: TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedFire, color: Colors.orange, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          LocaleService.tr('estimated_burn', args: {'calories': ex.calories}),
                          style: const TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BouncingTap(
                      hapticType: AppHapticFeedbackType.medium,
                      scaleDown: 0.96,
                      onTap: () async {
                        final setupResult = await WorkoutSetupSheet.show(context, exercise: ex);
                        if (setupResult == null || !context.mounted) return;

                        final completed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveWorkoutScreen(
                              title: ex.title,
                              durationSeconds: setupResult.durationSeconds,
                              estimatedCalories: setupResult.estimatedCalories,
                              equipment: ex.equipment,
                              isRepsBased: ex.isReps,
                              targetSets: setupResult.targetSets,
                              targetReps: setupResult.targetReps,
                              weightKg: setupResult.weightKg,
                              restDurationSeconds: ex.restSeconds,
                              isMale: _isMale,
                            ),
                          ),
                        );

                        _refreshStats();

                        if (completed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleService.tr('workout_completed_snack', args: {'title': ex.title}),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const HugeIcon(icon: HugeIcons.strokeRoundedPlay, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              LocaleService.tr('start_workout_btn_action'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
