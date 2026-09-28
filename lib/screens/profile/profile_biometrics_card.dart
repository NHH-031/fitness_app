import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/user_profile.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';

class ProfileBiometricsCard extends StatelessWidget {
  final UserProfile profile;
  final double bmi;
  final Color bmiColor;
  final double weightDiff;

  const ProfileBiometricsCard({
    super.key,
    required this.profile,
    required this.bmi,
    required this.bmiColor,
    required this.weightDiff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedDashboardSpeed01,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                LocaleService.tr('biometrics_card_title'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // BMI & Status Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('bmi_title'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: bmiColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Container(width: 1, height: 40, color: Colors.white12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.bmiCategory,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: bmiColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weightDiff.abs() < 0.5
                            ? LocaleService.tr('weight_diff_perfect')
                            : weightDiff > 0
                                ? LocaleService.tr('weight_diff_lose', args: {
                                    'amount': weightDiff.toStringAsFixed(1)
                                  })
                                : LocaleService.tr('weight_diff_gain', args: {
                                    'amount': (-weightDiff).toStringAsFixed(1)
                                  }),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // BMR & TDEE 2-column Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: LocaleService.tr('bmr_title'),
                  value: '${profile.bmr.round()} kcal',
                  subtext: LocaleService.tr('bmr_sub'),
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: LocaleService.tr('tdee_title'),
                  value: '${profile.tdee.round()} kcal',
                  subtext: LocaleService.tr('tdee_sub'),
                  icon: Icons.bolt_rounded,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.25,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
