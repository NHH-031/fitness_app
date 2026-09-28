import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import '../widgets/exercise_pose_widget.dart';
import '../screens/workout_screen.dart';

/// Kết quả người dùng tùy chỉnh trước khi bắt đầu bài tập
class WorkoutSetupResult {
  final int targetSets;
  final int targetReps;
  final int estimatedCalories;
  final double? weightKg;
  final int durationSeconds;

  const WorkoutSetupResult({
    required this.targetSets,
    required this.targetReps,
    required this.estimatedCalories,
    this.weightKg,
    required this.durationSeconds,
  });
}

/// Helper tính toán lượng calo tiêu hao dựa trên số hiệp, số rep và mức tạ thực tế
class WorkoutCalorieHelper {
  /// Tính toán lại lượng calo tiêu hao tỷ lệ với số set, số rep và mức tạ
  static int calculateAdjustedCalories({
    required int baseCalories,
    required int baseSets,
    required int baseRepsOrSeconds,
    required int userSets,
    required int userRepsOrSeconds,
    double? baseWeight,
    double? userWeight,
  }) {
    final baseWork = baseSets * baseRepsOrSeconds;
    if (baseWork <= 0) return baseCalories;

    final userWork = userSets * userRepsOrSeconds;
    double ratio = userWork / baseWork;

    // Nếu bài tập có tạ, áp dụng hệ số tạ (Progressive Overload Factor)
    if (baseWeight != null && userWeight != null && baseWeight > 0) {
      final weightFactor = (userWeight / baseWeight).clamp(0.4, 3.0);
      // 65% phụ thuộc tổng số lần lặp + 35% phụ thuộc tải trọng tạ
      ratio *= (0.65 + 0.35 * weightFactor);
    }

    final calculated = (baseCalories * ratio).round();
    // Giới hạn giá trị hợp lý (10 kcal - 2000 kcal)
    return max(10, min(2000, calculated));
  }
}

/// Bottom Sheet cho phép người dùng tùy chỉnh số Sets, Reps, Mức tạ và xem Calo tính lại
class WorkoutSetupSheet extends StatefulWidget {
  final WorkoutExercise exercise;

  const WorkoutSetupSheet({
    super.key,
    required this.exercise,
  });

  /// Hàm tiện ích hiển thị Bottom Sheet
  static Future<WorkoutSetupResult?> show(
    BuildContext context, {
    required WorkoutExercise exercise,
  }) {
    return showModalBottomSheet<WorkoutSetupResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkoutSetupSheet(exercise: exercise),
    );
  }

  @override
  State<WorkoutSetupSheet> createState() => _WorkoutSetupSheetState();
}

class _WorkoutSetupSheetState extends State<WorkoutSetupSheet> {
  late int _sets;
  late int _reps;
  double? _weightKg;
  late int _calculatedCalories;

  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  bool get _isDumbbell {
    final guide = ExerciseGuideData.getForExercise(widget.exercise.title);
    return widget.exercise.equipment == 'dumbbell' || guide.isDumbbell;
  }

  @override
  void initState() {
    super.initState();
    _sets = widget.exercise.targetSets > 0 ? widget.exercise.targetSets : 3;
    _reps = widget.exercise.targetReps > 0 ? widget.exercise.targetReps : 12;
    _weightKg = _isDumbbell ? (widget.exercise.weightKg ?? 10.0) : null;

    _setsController.text = '$_sets';
    _repsController.text = '$_reps';
    if (_weightKg != null) {
      _weightController.text = _weightKg!.toStringAsFixed(1);
    }

    _recalculate();
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {
      final baseSets = widget.exercise.targetSets > 0 ? widget.exercise.targetSets : 3;
      final baseReps = widget.exercise.targetReps > 0 ? widget.exercise.targetReps : 12;
      final baseCalories = widget.exercise.caloriesValue;
      final baseWeight = _isDumbbell ? (widget.exercise.weightKg ?? 10.0) : null;

      _calculatedCalories = WorkoutCalorieHelper.calculateAdjustedCalories(
        baseCalories: baseCalories,
        baseSets: baseSets,
        baseRepsOrSeconds: baseReps,
        userSets: _sets,
        userRepsOrSeconds: _reps,
        baseWeight: baseWeight,
        userWeight: _weightKg,
      );
    });
  }

  void _updateSets(int newSets) {
    final clamped = newSets.clamp(1, 30);
    setState(() {
      _sets = clamped;
      _setsController.text = '$clamped';
    });
    AppHaptics.selection();
    _recalculate();
  }

  void _updateReps(int newReps) {
    final clamped = newReps.clamp(1, 200);
    setState(() {
      _reps = clamped;
      _repsController.text = '$clamped';
    });
    AppHaptics.selection();
    _recalculate();
  }

  void _updateWeight(double newWeight) {
    final clamped = (newWeight.clamp(1.0, 100.0) * 2).round() / 2;
    setState(() {
      _weightKg = clamped;
      _weightController.text = clamped.toStringAsFixed(1);
    });
    AppHaptics.selection();
    _recalculate();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isDumbbell ? AppTheme.primaryColor : const Color(0xFF00F0FF);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: max(20, bottomInset + 16),
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2D35), width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh Handle gạt mở
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header bài tập
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: themeColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isDumbbell ? Icons.fitness_center : Icons.accessibility_new,
                                  size: 13,
                                  color: themeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isDumbbell
                                      ? LocaleService.tr('equipment_badge_dumbbell')
                                      : LocaleService.tr('equipment_badge_bodyweight'),
                                  style: TextStyle(
                                    color: themeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocaleService.tr(
                              'target_reps_sets_format',
                              args: {
                                'sets': '${widget.exercise.targetSets}',
                                'reps': '${widget.exercise.targetReps}',
                              },
                            ),
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 24),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 1. Tùy chỉnh SỐ HIỆP (SETS)
            _buildSectionHeader(
              title: LocaleService.tr('custom_sets_title'),
              subtitle: LocaleService.tr('custom_sets_sub'),
              icon: Icons.repeat_rounded,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStepButton(
                  icon: Icons.remove,
                  onTap: () => _updateSets(_sets - 1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        suffixText: LocaleService.tr('sets_unit'),
                        suffixStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          _sets = parsed.clamp(1, 30);
                          _recalculate();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStepButton(
                  icon: Icons.add,
                  onTap: () => _updateSets(_sets + 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Chip chọn nhanh số hiệp
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [2, 3, 4, 5, 6].map((s) {
                  final isSel = _sets == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$s ${LocaleService.tr('sets_unit')}'),
                      selected: isSel,
                      selectedColor: themeColor,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      side: BorderSide(
                        color: isSel ? themeColor : Colors.white12,
                      ),
                      onSelected: (_) => _updateSets(s),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // 2. Tùy chỉnh SỐ LẦN LẶP (REPS) HOẶC THỜI GIAN
            _buildSectionHeader(
              title: widget.exercise.isReps
                  ? LocaleService.tr('custom_reps_title')
                  : LocaleService.tr('custom_duration_title'),
              subtitle: widget.exercise.isReps
                  ? LocaleService.tr('custom_reps_sub')
                  : LocaleService.tr('custom_duration_sub'),
              icon: widget.exercise.isReps
                  ? Icons.fitness_center_rounded
                  : Icons.timer_outlined,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStepButton(
                  icon: Icons.remove,
                  onTap: () => _updateReps(_reps - (widget.exercise.isReps ? 1 : 5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        suffixText: widget.exercise.isReps ? 'reps' : 'giây',
                        suffixStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          _reps = parsed.clamp(1, 300);
                          _recalculate();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStepButton(
                  icon: Icons.add,
                  onTap: () => _updateReps(_reps + (widget.exercise.isReps ? 1 : 5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Chip chọn nhanh reps
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (widget.exercise.isReps
                        ? [8, 10, 12, 15, 20, 25]
                        : [30, 45, 60, 90, 120])
                    .map((r) {
                  final isSel = _reps == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(widget.exercise.isReps ? '$r reps' : '${r}s'),
                      selected: isSel,
                      selectedColor: themeColor,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      side: BorderSide(
                        color: isSel ? themeColor : Colors.white12,
                      ),
                      onSelected: (_) => _updateReps(r),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 3. Tùy chỉnh MỨC TẠ (Chỉ hiện cho bài tập Dumbbell)
            if (_isDumbbell && _weightKg != null) ...[
              const SizedBox(height: 18),
              _buildSectionHeader(
                title: LocaleService.tr('custom_weight_title'),
                subtitle: LocaleService.tr('custom_weight_sub'),
                icon: Icons.monitor_weight_outlined,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStepButton(
                    icon: Icons.remove,
                    onTap: () => _updateWeight(_weightKg! - 1.0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          suffixText: 'kg',
                          suffixStyle: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '.'));
                          if (parsed != null && parsed > 0) {
                            _weightKg = parsed.clamp(1.0, 100.0);
                            _recalculate();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStepButton(
                    icon: Icons.add,
                    onTap: () => _updateWeight(_weightKg! + 1.0),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [4.0, 6.0, 8.0, 10.0, 12.0, 15.0, 20.0].map((w) {
                    final isSel = (_weightKg! - w).abs() < 0.1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('${w.toStringAsFixed(1)} kg'),
                        selected: isSel,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        side: BorderSide(
                          color: isSel ? AppTheme.primaryColor : Colors.white12,
                        ),
                        onSelected: (_) => _updateWeight(w),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Card Hiển thị CALO TỰ ĐỘNG TÍNH TOÁN LẠI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.deepOrange.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '~$_calculatedCalories kcal',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                LocaleService.tr('recalculated_badge'),
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          LocaleService.tr(
                            'recalculated_calorie_desc',
                            args: {
                              'sets': '$_sets',
                              'reps': '$_reps',
                              'unit': widget.exercise.isReps ? 'reps' : 'giây',
                            },
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Nút BẮT ĐẦU TẬP NGAY
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  AppHaptics.medium();
                  Navigator.pop(
                    context,
                    WorkoutSetupResult(
                      targetSets: _sets,
                      targetReps: _reps,
                      estimatedCalories: _calculatedCalories,
                      weightKg: _weightKg,
                      durationSeconds: widget.exercise.isReps
                          ? widget.exercise.durationSeconds
                          : _reps,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LocaleService.tr('start_workout_with_custom_btn'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00F0FF)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
