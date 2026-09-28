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
import 'active_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // true = Men, false = Women
  bool _isMale = true;

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

  List<Map<String, String>> get _maleExercises => LocaleService.isVietnamese
      ? [
          {'title': 'Hít đất', 'duration': '10 phút', 'calories': '120 kcal'},
          {'title': 'Hít xà đơn', 'duration': '8 phút', 'calories': '110 kcal'},
          {'title': 'Gập bụng', 'duration': '5 phút', 'calories': '50 kcal'},
          {'title': 'Plank siết cơ bụng', 'duration': '3 phút', 'calories': '35 kcal'},
          {'title': 'Nhảy Burpees đốt mỡ', 'duration': '6 phút', 'calories': '90 kcal'},
          {'title': 'Leo núi Mountain Climbers', 'duration': '5 phút', 'calories': '65 kcal'},
          {'title': 'Chùng chân Lunges', 'duration': '8 phút', 'calories': '95 kcal'},
          {'title': 'Hít đất kim cương', 'duration': '6 phút', 'calories': '75 kcal'},
          {'title': 'Vặn bụng Russian Twists', 'duration': '6 phút', 'calories': '55 kcal'},
        ]
      : [
          {'title': 'Push-ups', 'duration': '10 Mins', 'calories': '120 kcal'},
          {'title': 'Pull-ups', 'duration': '8 Mins', 'calories': '110 kcal'},
          {'title': 'Crunches', 'duration': '5 Mins', 'calories': '50 kcal'},
          {'title': 'High-intensity Plank', 'duration': '3 Mins', 'calories': '35 kcal'},
          {'title': 'Burpees (Full Body Fat Burn)', 'duration': '6 Mins', 'calories': '90 kcal'},
          {'title': 'Mountain Climbers', 'duration': '5 Mins', 'calories': '65 kcal'},
          {'title': 'Jumping Lunges', 'duration': '8 Mins', 'calories': '95 kcal'},
          {'title': 'Diamond Push-ups', 'duration': '6 Mins', 'calories': '75 kcal'},
          {'title': 'Russian Twists', 'duration': '6 Mins', 'calories': '55 kcal'},
        ];

  List<Map<String, String>> get _femaleExercises => LocaleService.isVietnamese
      ? [
          {'title': 'Squat mông đùi', 'duration': '10 phút', 'calories': '90 kcal'},
          {'title': 'Giãn cơ Yoga dẻo dai', 'duration': '15 phút', 'calories': '60 kcal'},
          {'title': 'Plank siết cơ bụng', 'duration': '3 phút', 'calories': '25 kcal'},
          {'title': 'Cầu mông Glute Bridges', 'duration': '8 phút', 'calories': '65 kcal'},
          {'title': 'Đạp xe gập bụng Bicycle', 'duration': '6 phút', 'calories': '55 kcal'},
          {'title': 'Nhảy Jumping Jacks', 'duration': '7 phút', 'calories': '70 kcal'},
          {'title': 'Đá mông Donkey Kicks', 'duration': '8 phút', 'calories': '60 kcal'},
          {'title': 'Chùng chân Lunges', 'duration': '8 phút', 'calories': '70 kcal'},
        ]
      : [
          {'title': 'Squats (Glutes & Legs)', 'duration': '10 Mins', 'calories': '90 kcal'},
          {'title': 'Yoga Flexibility Stretch', 'duration': '15 Mins', 'calories': '60 kcal'},
          {'title': 'Knee Plank (Gentle Core)', 'duration': '3 Mins', 'calories': '25 kcal'},
          {'title': 'Glute Bridges', 'duration': '8 Mins', 'calories': '65 kcal'},
          {'title': 'Bicycle Crunches', 'duration': '6 Mins', 'calories': '55 kcal'},
          {'title': 'Jumping Jacks', 'duration': '7 Mins', 'calories': '70 kcal'},
          {'title': 'Donkey Kicks', 'duration': '8 Mins', 'calories': '60 kcal'},
          {'title': 'Reverse Lunges', 'duration': '8 Mins', 'calories': '70 kcal'},
        ];

  void _refreshStats() {
    _weeklyKey.currentState?.refreshData();
    _badgesKey.currentState?.refreshBadges();
  }

  @override
  Widget build(BuildContext context) {
    final currentExercises = _isMale ? _maleExercises : _femaleExercises;

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

            const SizedBox(height: 28),

            // 4. Standard Bodyweight Exercises Header with Gender Switcher
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

            const SizedBox(height: 16),

            // Standard Exercises Cards
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
                          child: Text(
                            ex['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            ex['duration']!,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ExercisePoseAnimator(
                      exerciseTitle: ex['title']!,
                      height: 135,
                    ),
                    const SizedBox(height: 10),
                    Container(
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
                              ExerciseGuideData.getForExercise(ex['title']!).targetMuscles,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedFire, color: Colors.orange, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          LocaleService.tr('estimated_burn', args: {'calories': ex['calories']!}),
                          style: const TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BouncingTap(
                      hapticType: AppHapticFeedbackType.medium,
                      scaleDown: 0.96,
                      onTap: () async {
                        final calMatch = RegExp(r'\d+').firstMatch(ex['calories'] ?? '');
                        final calories = calMatch != null ? int.parse(calMatch.group(0)!) : 50;

                        final completed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveWorkoutScreen(
                              title: ex['title']!,
                              durationSeconds: 45,
                              estimatedCalories: calories,
                            ),
                          ),
                        );

                        _refreshStats();

                        if (completed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleService.tr('workout_completed_snack', args: {'title': ex['title']!}),
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
