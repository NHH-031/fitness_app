import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';

class ProfileMacroBlueprintCard extends StatelessWidget {
  final Map<String, int> targetMacros;
  final double userWeight;

  const ProfileMacroBlueprintCard({
    super.key,
    required this.targetMacros,
    required this.userWeight,
  });

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedPieChart,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        LocaleService.tr('macro_blueprint_title'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${targetMacros['calories']} ${LocaleService.tr('per_day')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMacroNutrientTile(
                  name: LocaleService.tr('macro_protein_short'),
                  grams: targetMacros['protein'] ?? 0,
                  color: AppColors.protein,
                  note:
                      '${(userWeight > 0 ? (targetMacros['protein']! / userWeight).toStringAsFixed(1) : '2.0')}g/kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroNutrientTile(
                  name: LocaleService.tr('macro_carbs_short'),
                  grams: targetMacros['carbs'] ?? 0,
                  color: AppColors.carbs,
                  note: LocaleService.isVietnamese ? 'Năng lượng' : 'Energy',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroNutrientTile(
                  name: LocaleService.tr('macro_fat_short'),
                  grams: targetMacros['fat'] ?? 0,
                  color: AppColors.fat,
                  note: LocaleService.isVietnamese ? 'Nội tiết' : 'Hormones',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    LocaleService.tr('macro_note'),
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroNutrientTile({
    required String name,
    required int grams,
    required Color color,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${grams}g',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
