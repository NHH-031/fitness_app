import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../theme.dart';

class BadgesAchievementWidget extends StatefulWidget {
  final int currentSteps;

  const BadgesAchievementWidget({
    super.key,
    this.currentSteps = 0,
  });

  @override
  State<BadgesAchievementWidget> createState() => BadgesAchievementWidgetState();
}

class BadgesAchievementWidgetState extends State<BadgesAchievementWidget> {
  List<AchievementBadge> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshBadges();
  }

  @override
  void didUpdateWidget(covariant BadgesAchievementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSteps != widget.currentSteps) {
      refreshBadges();
    }
  }

  Future<void> refreshBadges() async {
    final badges = await StorageService.getAchievementBadges(
      currentSteps: widget.currentSteps,
    );
    if (mounted) {
      setState(() {
        _badges = badges;
        _isLoading = false;
      });
    }
  }

  List<List<dynamic>> _getBadgeHugeIcon(String id) {
    switch (id) {
      case '10k_steps':
        return HugeIcons.strokeRoundedMedalFirstPlace;
      case 'cardio_master':
        return HugeIcons.strokeRoundedEnergy;
      case 'dawn_warrior':
        return HugeIcons.strokeRoundedSunrise;
      case 'eternal_flame':
        return HugeIcons.strokeRoundedFire;
      default:
        return HugeIcons.strokeRoundedAward01;
    }
  }

  void _showBadgeDialog(BuildContext context, AchievementBadge badge) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: badge.isUnlocked
                    ? badge.themeColor.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.15),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: badge.isUnlocked
                      ? badge.themeColor.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.5),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Icon with Glow
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.isUnlocked
                        ? badge.themeColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: badge.isUnlocked
                          ? badge.themeColor
                          : Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: badge.isUnlocked
                        ? [
                            BoxShadow(
                              color: badge.themeColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: _getBadgeHugeIcon(badge.id),
                      size: 42,
                      color: badge.isUnlocked ? badge.themeColor : Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Title
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: badge.isUnlocked
                        ? badge.themeColor
                        : AppTheme.textPrimaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badge.isUnlocked
                        ? badge.themeColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badge.isUnlocked
                          ? badge.themeColor.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: badge.isUnlocked
                            ? HugeIcons.strokeRoundedCheckmarkCircle01
                            : HugeIcons.strokeRoundedLockKey,
                        size: 16,
                        color: badge.isUnlocked
                            ? badge.themeColor
                            : AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        badge.isUnlocked
                            ? LocaleService.tr('badge_unlocked_status')
                            : LocaleService.tr('badge_locked_status'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: badge.isUnlocked
                              ? badge.themeColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocaleService.tr('current_status_label'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        badge.progressText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: badge.isUnlocked
                              ? badge.themeColor
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badge.isUnlocked
                          ? badge.themeColor
                          : AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      LocaleService.tr('awesome_btn'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final int unlockedCount = _badges.where((b) => b.isUnlocked).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTrophy,
                        color: Color(0xFFFFD700),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleService.tr('achievements_card_title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocaleService.tr('achievements_card_sub'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Unlocked badge pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  LocaleService.tr('badges_won_ratio', args: {
                    'won': '$unlockedCount',
                    'total': '${_badges.length}',
                  }),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Badges 2x2 Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final badge = _badges[index];
              return _buildBadgeCard(badge);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(AchievementBadge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDialog(context, badge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? badge.themeColor.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.isUnlocked
                ? badge.themeColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: badge.isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: badge.isUnlocked
              ? [
                  BoxShadow(
                    color: badge.themeColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji and Lock / Check overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.isUnlocked
                        ? badge.themeColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: badge.isUnlocked
                          ? badge.themeColor
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: _getBadgeHugeIcon(badge.id),
                      size: 24,
                      color: badge.isUnlocked ? badge.themeColor : Colors.white38,
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badge.isUnlocked
                          ? badge.themeColor
                          : const Color(0xFF1E1E24),
                      border: Border.all(
                        color: badge.isUnlocked
                            ? Colors.black26
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: HugeIcon(
                      icon: badge.isUnlocked
                          ? HugeIcons.strokeRoundedCheckmarkCircle01
                          : HugeIcons.strokeRoundedLockKey,
                      size: 10,
                      color: badge.isUnlocked ? Colors.black : Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badge.isUnlocked
                    ? AppTheme.textPrimaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            // Progress or Unlocked Text
            Text(
              badge.isUnlocked
                  ? LocaleService.tr('unlocked_badge_label')
                  : badge.progressText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: badge.isUnlocked ? FontWeight.bold : FontWeight.w500,
                color: badge.isUnlocked
                    ? badge.themeColor
                    : AppTheme.textSecondaryColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
