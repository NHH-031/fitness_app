import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/user_profile.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';

class ProfileAiInterconnectionCard extends StatelessWidget {
  final UserProfile profile;
  final String Function(String) getGoalDisplayName;

  const ProfileAiInterconnectionCard({
    super.key,
    required this.profile,
    required this.getGoalDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9D00FF).withValues(alpha: 0.15),
            AppColors.info.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: const Color(0xFF9D00FF).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAiSparkles,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                LocaleService.tr('ai_integration_title'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_activity'),
            status: LocaleService.tr('ai_sync_activity', args: {
              'age': profile.age.toString(),
              'gender': profile.gender == 'male'
                  ? LocaleService.tr('field_male')
                  : LocaleService.tr('field_female'),
              'goal': getGoalDisplayName(profile.fitnessGoal),
            }),
            hugeIcon: HugeIcons.strokeRoundedDumbbell01,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_food'),
            status: LocaleService.tr('ai_sync_food', args: {
              'cal': profile.targetCalories.toString(),
            }),
            hugeIcon: HugeIcons.strokeRoundedApple01,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_dashboard'),
            status: LocaleService.tr('ai_sync_dashboard', args: {
              'bmr': profile.bmr.round().toString(),
            }),
            hugeIcon: HugeIcons.strokeRoundedHome01,
          ),
        ],
      ),
    );
  }

  Widget _buildAiSyncItem({
    required String tabName,
    required String status,
    required List<List<dynamic>> hugeIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              HugeIcon(icon: hugeIcon, color: AppColors.info, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tabName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
