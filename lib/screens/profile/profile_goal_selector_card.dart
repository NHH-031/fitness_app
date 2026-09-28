import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';

class ProfileGoalSelectorCard extends StatelessWidget {
  final String currentGoal;
  final Function(String) onGoalSelected;

  const ProfileGoalSelectorCard({
    super.key,
    required this.currentGoal,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final goals = [
      {
        'id': 'cutting',
        'name': LocaleService.tr('goal_cutting_name'),
        'hugeIcon': HugeIcons.strokeRoundedTarget01,
        'iconColor': const Color(0xFFFF3B30),
        'sub': LocaleService.tr('goal_cutting_sub'),
      },
      {
        'id': 'bulking',
        'name': LocaleService.tr('goal_bulking_name'),
        'hugeIcon': HugeIcons.strokeRoundedBodyPartMuscle,
        'iconColor': const Color(0xFFFFD700),
        'sub': LocaleService.tr('goal_bulking_sub'),
      },
      {
        'id': 'balanced',
        'name': LocaleService.tr('goal_balanced_name'),
        'hugeIcon': HugeIcons.strokeRoundedBalanceScale,
        'iconColor': AppColors.info,
        'sub': LocaleService.tr('goal_balanced_sub'),
      },
      {
        'id': 'endurance',
        'name': LocaleService.tr('goal_endurance_name'),
        'hugeIcon': HugeIcons.strokeRoundedRunningShoes,
        'iconColor': AppColors.success,
        'sub': LocaleService.tr('goal_endurance_sub'),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedFlag01,
                    color: Color(0xFF9D00FF),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    LocaleService.tr('fitness_goal_title'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D00FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  LocaleService.tr('tap_to_change'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFD68BFD),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: goals.map((g) {
              final isSelected = currentGoal == g['id'];
              return GestureDetector(
                onTap: () => onGoalSelected(g['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF9D00FF).withValues(alpha: 0.2)
                        : const Color(0xFF14141E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF9D00FF)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (g['iconColor'] as Color).withValues(
                              alpha: isSelected ? 0.25 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: HugeIcon(
                          icon: g['hugeIcon'] as List<List<dynamic>>,
                          color: g['iconColor'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                            Text(
                              g['sub'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? const Color(0xFFD68BFD)
                                    : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          color: AppColors.info,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
