import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';

class ProfileHeroCard extends StatelessWidget {
  final UserProfile profile;
  final bool isGuest;
  final String Function(String) getGoalDisplayName;
  final VoidCallback? onTap;

  const ProfileHeroCard({
    super.key,
    required this.profile,
    required this.isGuest,
    required this.getGoalDisplayName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = profile.gender.toLowerCase() == 'male';
    final user = AuthService().currentUser;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.info.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.info.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Glowing Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.info, Color(0xFF9D00FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF161622),
                    ),
                    child: ClipOval(
                      child: (user?.photoURL != null &&
                              user!.photoURL!.isNotEmpty)
                          ? Image.network(
                              user.photoURL!,
                              width: 66,
                              height: 66,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  isMale
                                      ? Icons.sports_gymnastics_rounded
                                      : Icons.fitness_center_rounded,
                                  color: AppColors.info,
                                  size: 34,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                isMale
                                    ? Icons.sports_gymnastics_rounded
                                    : Icons.fitness_center_rounded,
                                color: AppColors.info,
                                size: 34,
                              ),
                            ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isMale ? Colors.blueAccent : Colors.pinkAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Icon(
                    isMale ? Icons.male_rounded : Icons.female_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // User Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (user?.displayName != null &&
                                  user!.displayName!.isNotEmpty)
                              ? user.displayName!
                              : profile.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          LocaleService.tr('years_old',
                              args: {'age': profile.age.toString()}),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                      if (isGuest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            LocaleService.isVietnamese ? 'Khách' : 'Guest',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user?.email != null && user!.email!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 12, color: AppColors.info),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user.email!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    LocaleService.tr('height_weight_summary', args: {
                      'height': profile.height.toStringAsFixed(0),
                      'weight': profile.weight.toStringAsFixed(1),
                      'target': profile.targetWeight.toStringAsFixed(1),
                    }),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D00FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF9D00FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      LocaleService.tr('goal_tag',
                          args: {'goal': getGoalDisplayName(profile.fitnessGoal)}),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFFD68BFD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
