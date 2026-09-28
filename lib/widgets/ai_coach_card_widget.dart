import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../screens/active_workout_screen.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';

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
  int _selectedMinutes = 15;
  bool _isCustomMinutes = false;
  String _selectedGoalKey = 'goal_fat_burn';
  String _selectedEquipment = 'bodyweight'; // 'bodyweight' | 'dumbbell' | 'hybrid'
  bool _isLoading = false;
  CustomWorkoutRoutine? _generatedRoutine;
  String? _errorMessage;
  UserProfile? _userProfile;

  final TextEditingController _customGoalController = TextEditingController();
  final List<int> _durations = [10, 15, 20, 30, 45, 60];

  final List<Map<String, dynamic>> _goals = [
    {
      'key': 'goal_fat_burn',
      'fallback': 'Full Body Fat Burn',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFFF3B30),
    },
    {
      'key': 'goal_core_abs',
      'fallback': 'Core & Abs Sculpting',
      'icon': Icons.sports_gymnastics_rounded,
      'color': const Color(0xFFFFD700),
    },
    {
      'key': 'goal_upper_body',
      'fallback': 'Upper Body Strength (Chest & Arms)',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFF00F0FF),
    },
    {
      'key': 'goal_lower_body',
      'fallback': 'Lower Body (Glutes & Legs)',
      'icon': Icons.directions_run_rounded,
      'color': const Color(0xFFFF2D55),
    },
    {
      'key': 'goal_flexibility',
      'fallback': 'Flexibility & Back Relief',
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFF30D158),
    },
    {
      'key': 'goal_hiit_cardio',
      'fallback': 'High Intensity Cardio & Stamina',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFFF9500),
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
    _customGoalController.dispose();
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
          _selectedGoalKey = 'goal_upper_body';
        } else if (userGoal == 'endurance') {
          _selectedGoalKey = 'goal_hiit_cardio';
        }
      });
    }
  }

  void _showCustomDurationDialog() {
    final controller = TextEditingController(text: '$_selectedMinutes');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocaleService.tr('custom_duration_dialog_title'),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: LocaleService.tr('custom_duration_hint'),
            hintStyle: const TextStyle(color: Colors.grey),
            suffixText: 'phút',
            suffixStyle: const TextStyle(color: Color(0xFF00F0FF)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.tr('continue_btn'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null && parsed >= 5 && parsed <= 180) {
                setState(() {
                  _selectedMinutes = parsed;
                  _isCustomMinutes = true;
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateRoutine() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final freshProfile = await StorageService.getUserProfile();
      _userProfile = freshProfile;

      // Xác định mục tiêu bài tập: Ưu tiên mục tiêu người dùng tự nhập
      final customGoalText = _customGoalController.text.trim();
      final String effectiveGoal;
      if (customGoalText.isNotEmpty) {
        effectiveGoal = customGoalText;
      } else {
        final goalItem = _goals.firstWhere(
          (g) => g['key'] == _selectedGoalKey,
          orElse: () => _goals.first,
        );
        effectiveGoal = LocaleService.isVietnamese
            ? LocaleService.tr(goalItem['key'] as String)
            : (goalItem['fallback'] as String? ?? 'Full Body Fat Burn');
      }

      final routine = await GeminiService.generateCustomWorkout(
        durationMinutes: _selectedMinutes,
        goal: effectiveGoal,
        equipment: _selectedEquipment,
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
          equipment: _selectedEquipment,
          isRepsBased: true,
          targetSets: 3,
          targetReps: 12,
          weightKg: _selectedEquipment == 'bodyweight' ? null : 10.0,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._durations.map((mins) {
                    final isSelected = !_isCustomMinutes && _selectedMinutes == mins;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          LocaleService.tr('mins_chip', args: {'mins': '$mins'}),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isSelected ? Colors.black : AppTheme.textPrimaryColor,
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
                            setState(() {
                              _selectedMinutes = mins;
                              _isCustomMinutes = false;
                            });
                          }
                        },
                      ),
                    );
                  }),
                  // Nút Tùy chỉnh phút
                  ChoiceChip(
                    avatar: Icon(
                      Icons.edit_calendar_rounded,
                      size: 14,
                      color: _isCustomMinutes ? Colors.black : const Color(0xFF00F0FF),
                    ),
                    label: Text(
                      _isCustomMinutes
                          ? '$_selectedMinutes phút'
                          : LocaleService.tr('custom_duration_chip'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _isCustomMinutes ? Colors.black : const Color(0xFF00F0FF),
                      ),
                    ),
                    selected: _isCustomMinutes,
                    selectedColor: const Color(0xFF00F0FF),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isCustomMinutes ? const Color(0xFF00F0FF) : Colors.white12,
                      ),
                    ),
                    onSelected: (_) => _showCustomDurationDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Goal Selection (Mục tiêu bài tập)
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
                final icon = goal['icon'] as IconData;
                final iconColor = goal['color'] as Color;
                final isSelected = _customGoalController.text.trim().isEmpty &&
                    _selectedGoalKey == goal['key'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
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
                      setState(() {
                        _selectedGoalKey = goal['key'] as String;
                        _customGoalController.clear();
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            // Ô nhập mục tiêu mong muốn tự do
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _customGoalController.text.trim().isNotEmpty
                      ? const Color(0xFF00F0FF)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF00F0FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customGoalController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                      decoration: InputDecoration(
                        hintText: LocaleService.tr('custom_goal_hint'),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                  if (_customGoalController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _customGoalController.clear();
                        });
                      },
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Equipment Selection (Dụng cụ tập luyện - Hỗ trợ Tạ đơn)
            Text(
              LocaleService.tr('ai_equipment_title'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildEquipmentChip(
                    id: 'bodyweight',
                    title: LocaleService.tr('ai_equipment_bodyweight'),
                    icon: Icons.accessibility_new_rounded,
                    color: const Color(0xFF00F0FF),
                  ),
                  const SizedBox(width: 8),
                  _buildEquipmentChip(
                    id: 'dumbbell',
                    title: LocaleService.tr('ai_equipment_dumbbell'),
                    icon: Icons.fitness_center_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _buildEquipmentChip(
                    id: 'hybrid',
                    title: LocaleService.tr('ai_equipment_hybrid'),
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFFD700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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

  Widget _buildEquipmentChip({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedEquipment == id;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 15,
        color: isSelected ? Colors.black : color,
      ),
      label: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          color: isSelected ? Colors.black : AppTheme.textPrimaryColor,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedEquipment = id);
          AppHaptics.selection();
        }
      },
    );
  }

  Widget _buildRoutinePreview(CustomWorkoutRoutine routine) {
    final isDumbbell = _selectedEquipment != 'bodyweight';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDumbbell ? AppTheme.primaryColor : const Color(0xFF00F0FF))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedEquipment == 'dumbbell'
                          ? '🏋️ ${LocaleService.tr('ai_equipment_dumbbell')}'
                          : _selectedEquipment == 'hybrid'
                              ? '⚡ ${LocaleService.tr('ai_equipment_hybrid')}'
                              : '🏃 ${LocaleService.tr('ai_equipment_bodyweight')}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDumbbell ? AppTheme.primaryColor : const Color(0xFF00F0FF),
                      ),
                    ),
                  ),
                ],
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
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  LocaleService.tr('start_workout_btn'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 14,
                    color: Colors.white,
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
