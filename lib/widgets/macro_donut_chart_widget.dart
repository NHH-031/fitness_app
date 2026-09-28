import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';

class MacroDonutChartWidget extends StatefulWidget {
  final VoidCallback? onGoalChanged;

  const MacroDonutChartWidget({super.key, this.onGoalChanged});

  @override
  State<MacroDonutChartWidget> createState() => _MacroDonutChartWidgetState();
}

class _MacroDonutChartWidgetState extends State<MacroDonutChartWidget> {
  int _caloriesIn = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fat = 0;
  String _currentGoal = 'balanced'; // 'cutting', 'bulking', 'balanced', 'endurance'
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
    StorageService.foodUpdateNotifier.addListener(_loadData);
    StorageService.profileUpdateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    StorageService.foodUpdateNotifier.removeListener(_loadData);
    StorageService.profileUpdateNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile = await StorageService.getUserProfile();
    final calories = await StorageService.getTodayTotalCaloriesIn();
    final macros = await StorageService.getTodayTotalMacros();
    final goal = await StorageService.getNutritionGoal();

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _caloriesIn = calories;
        _protein = macros['protein'] ?? 0;
        _carbs = macros['carbs'] ?? 0;
        _fat = macros['fat'] ?? 0;
        _currentGoal = profile.fitnessGoal.isNotEmpty ? profile.fitnessGoal : goal;
      });
    }
  }

  Future<void> _setGoal(String goal) async {
    await StorageService.saveNutritionGoal(goal);
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(fitnessGoal: goal);
      await StorageService.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;
    }
    setState(() {
      _currentGoal = goal;
    });
    widget.onGoalChanged?.call();
  }

  // Dynamic targets derived from user's biometrics & Mifflin-St Jeor formula
  int get _targetCalories => _userProfile?.targetCalories ?? 2000;
  int get _targetProtein => _userProfile?.targetMacros['protein'] ?? 150;
  int get _targetCarbs => _userProfile?.targetMacros['carbs'] ?? 200;
  int get _targetFat => _userProfile?.targetMacros['fat'] ?? 65;

  @override
  Widget build(BuildContext context) {
    final totalGrams = _protein + _carbs + _fat;
    final hasData = totalGrams > 0;
    final calProgress = (_caloriesIn / _targetCalories).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPieChart,
                      color: Color(0xFF00F0FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('macro_breakdown_title'),
                        style: AppTheme.font(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        LocaleService.tr('macro_breakdown_subtitle'),
                        style: AppTheme.font(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  LocaleService.tr('target_progress', args: {'percent': '${(calProgress * 100).toInt()}'}),
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: calProgress > 1.0 ? Colors.redAccent : const Color(0xFF00F0FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Goal Selector Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildGoalTab(
                  'cutting',
                  LocaleService.tr('cut_chip'),
                  LocaleService.tr('cut_sub'),
                  HugeIcons.strokeRoundedFire,
                  const Color(0xFFFF5252),
                ),
                _buildGoalTab(
                  'balanced',
                  LocaleService.tr('balanced_chip'),
                  LocaleService.tr('balanced_sub'),
                  HugeIcons.strokeRoundedBalanceScale,
                  const Color(0xFF00F0FF),
                ),
                _buildGoalTab(
                  'bulking',
                  LocaleService.tr('bulk_chip'),
                  LocaleService.tr('bulk_sub'),
                  HugeIcons.strokeRoundedBodyPartMuscle,
                  const Color(0xFFFFD700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Donut Chart & Legend Center
          Row(
            children: [
              // Donut Chart
              SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 48,
                        startDegreeOffset: -90,
                        sections: hasData
                            ? [
                                PieChartSectionData(
                                  color: const Color(0xFF00F0FF),
                                  value: _protein.toDouble(),
                                  title: '',
                                  radius: 18,
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFFFFD700),
                                  value: _carbs.toDouble(),
                                  title: '',
                                  radius: 18,
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFFFF2D55),
                                  value: _fat.toDouble(),
                                  title: '',
                                  radius: 18,
                                ),
                              ]
                            : [
                                PieChartSectionData(
                                  color: Colors.white12,
                                  value: 100,
                                  title: '',
                                  radius: 18,
                                ),
                              ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_caloriesIn',
                          style: AppTheme.font(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '/$_targetCalories',
                          style: AppTheme.font(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: AppTheme.font(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00F0FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Macro Mini Stats Column
              Expanded(
                child: Column(
                  children: [
                    _buildMacroRow(
                      label: LocaleService.tr('macro_protein_short'),
                      current: _protein,
                      target: _targetProtein,
                      color: const Color(0xFF00F0FF),
                      hugeIcon: HugeIcons.strokeRoundedSteak,
                    ),
                    const SizedBox(height: 10),
                    _buildMacroRow(
                      label: LocaleService.tr('macro_carbs_short'),
                      current: _carbs,
                      target: _targetCarbs,
                      color: const Color(0xFFFFD700),
                      hugeIcon: HugeIcons.strokeRoundedBread01,
                    ),
                    const SizedBox(height: 10),
                    _buildMacroRow(
                      label: LocaleService.tr('macro_fat_short'),
                      current: _fat,
                      target: _targetFat,
                      color: const Color(0xFFFF2D55),
                      hugeIcon: HugeIcons.strokeRoundedAvocado,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTab(
    String goalKey,
    String title,
    String subtitle,
    List<List<dynamic>> hugeIcon,
    Color iconColor,
  ) {
    final isSelected = _currentGoal == goalKey;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setGoal(goalKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C2C34) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: hugeIcon,
                    size: 13,
                    color: isSelected ? const Color(0xFF00F0FF) : iconColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title,
                      style: AppTheme.font(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.font(
                  fontSize: 10,
                  color: isSelected ? const Color(0xFF00F0FF) : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required int current,
    required int target,
    required Color color,
    required List<List<dynamic>> hugeIcon,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: hugeIcon,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${current}g',
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${target}g',
                    style: AppTheme.font(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
