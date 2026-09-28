import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../screens/active_workout_screen.dart';
import '../theme.dart';

class AiCoachCardWidget extends StatefulWidget {
  final VoidCallback? onWorkoutStarted;

  const AiCoachCardWidget({
    super.key,
    this.onWorkoutStarted,
  });

  @override
  State<AiCoachCardWidget> createState() => _AiCoachCardWidgetState();
}

class _AiCoachCardWidgetState extends State<AiCoachCardWidget> {
  int _selectedMinutes = 10;
  String _selectedGoalKey = 'goal_fat_burn';
  bool _isLoading = false;
  CustomWorkoutRoutine? _generatedRoutine;
  String? _errorMessage;
  UserProfile? _userProfile;

  final List<int> _durations = [10, 20, 30];
  final List<Map<String, dynamic>> _goals = [
    {
      'key': 'goal_fat_burn',
      'fallback': 'Full Body Fat Burn',
      'hugeIcon': HugeIcons.strokeRoundedFire,
      'color': const Color(0xFFFF3B30),
    },
    {
      'key': 'goal_core_abs',
      'fallback': 'Core & Abs',
      'hugeIcon': HugeIcons.strokeRoundedBodyPartSixPack,
      'color': const Color(0xFFFFD700),
    },
    {
      'key': 'goal_flexibility',
      'fallback': 'Flexibility & Back Relief',
      'hugeIcon': HugeIcons.strokeRoundedYoga01,
      'color': const Color(0xFF00F0FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    StorageService.profileUpdateNotifier.addListener(_loadProfile);
  }

  @override
  void dispose() {
    StorageService.profileUpdateNotifier.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await StorageService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        // Auto-align default goal with user's profile fitness goal if available
        final userGoal = profile.fitnessGoal.toLowerCase();
        if (userGoal == 'cutting') {
          _selectedGoalKey = 'goal_fat_burn';
        } else if (userGoal == 'bulking') {
          _selectedGoalKey = 'goal_core_abs';
        } else if (userGoal == 'endurance') {
          _selectedGoalKey = 'goal_flexibility';
        }
      });
    }
  }

  Future<void> _generateRoutine() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Re-fetch latest fresh profile from storage to ensure real-time biometrics
      final freshProfile = await StorageService.getUserProfile();
      _userProfile = freshProfile;

      final goalItem = _goals.firstWhere(
        (g) => g['key'] == _selectedGoalKey,
        orElse: () => _goals.first,
      );
      final routine = await GeminiService.generateCustomWorkout(
        durationMinutes: _selectedMinutes,
        goal: goalItem['fallback'] ?? 'Full Body Fat Burn',
        equipment: 'Bodyweight only',
        userProfile: freshProfile,
      );
      if (mounted) {
        setState(() {
          _generatedRoutine = routine;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = LocaleService.isVietnamese
              ? 'Không thể tạo bài tập lúc này. Vui lòng thử lại!'
              : 'Could not generate workout. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _startWorkout(CustomWorkoutRoutine routine) {
    widget.onWorkoutStarted?.call();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          title: routine.title,
          durationSeconds: routine.durationMinutes * 60,
          estimatedCalories: routine.estimatedCalories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF9D00FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D00FF).withValues(alpha: 0.09),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9D00FF), Color(0xFF00F0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedBrainCircuit,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('ai_coach_title'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppTheme.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr('ai_coach_subtitle'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_userProfile != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedShieldCheck,
                    color: Color(0xFF00F0FF),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      LocaleService.tr(
                        'ai_synced_badge',
                        args: {
                          'name': _userProfile!.name,
                          'goal': _userProfile!.goalDisplayName.toUpperCase(),
                        },
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00F0FF),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (_generatedRoutine == null) ...[
            // 1. Time Selection
            Text(
              LocaleService.tr('free_time_today'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _durations.map((mins) {
                final isSelected = _selectedMinutes == mins;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          LocaleService.tr('mins_chip', args: {'mins': '$mins'}),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isSelected ? Colors.black : AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedMinutes = mins);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 2. Goal Selection
            Text(
              LocaleService.tr('workout_goal'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goals.map((goal) {
                final label = LocaleService.tr(goal['key'] as String);
                final hugeIcon = goal['hugeIcon'] as List<List<dynamic>>;
                final iconColor = goal['color'] as Color;
                final isSelected = _selectedGoalKey == goal['key'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: hugeIcon,
                        size: 16,
                        color: isSelected ? Colors.black : iconColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isSelected ? Colors.black : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00F0FF),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF00F0FF)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedGoalKey = goal['key'] as String);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 3. Equipment Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedBodyWeight,
                    size: 16,
                    color: Color(0xFF00F0FF),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      LocaleService.tr('equipment_label'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9D00FF), Color(0xFF00F0FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9D00FF).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                LocaleService.tr('generating_routine'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedAiSparkles,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                LocaleService.tr('generate_workout_btn'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Generated Routine Preview
            _buildRoutinePreview(_generatedRoutine!),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFF2D55),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutinePreview(CustomWorkoutRoutine routine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                routine.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00F0FF)),
              ),
              child: Text(
                '~${routine.estimatedCalories} kcal',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00F0FF),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // AI Advice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF9D00FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF9D00FF).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAiSparkles,
                color: Color(0xFF9D00FF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  routine.coachAdvice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondaryColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Exercises List
        ...routine.exercises.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (item.formTip.isNotEmpty)
                        Text(
                          item.formTip,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.sets} x ${item.reps}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 14),

        // Start Workout Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startWorkout(routine),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedPlay, size: 20, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  LocaleService.tr('start_workout_btn'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Re-generate button
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _generatedRoutine = null;
              });
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedReload,
              size: 16,
              color: AppTheme.textSecondaryColor,
            ),
            label: Text(
              LocaleService.tr('customize_again_btn'),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
