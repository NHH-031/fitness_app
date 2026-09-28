import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/fitness_badge.dart';
import '../services/achievement_service.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import 'app_ui_components.dart';

class AchievementsSheet extends StatefulWidget {
  const AchievementsSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.medium();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AchievementsSheet(),
    );
  }

  @override
  State<AchievementsSheet> createState() => _AchievementsSheetState();
}

class _AchievementsSheetState extends State<AchievementsSheet> {
  List<FitnessBadge> _badges = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'unlocked', 'locked'

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final list = await AchievementService.getBadges(triggerUnlock: false);
    if (mounted) {
      setState(() {
        _badges = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;
    final unlockedCount = _badges.where((b) => b.isUnlocked).length;
    final totalCount = _badges.length;
    final progressPercent = totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

    List<FitnessBadge> displayed = _badges;
    if (_selectedFilter == 'unlocked') {
      displayed = _badges.where((b) => b.isUnlocked).toList();
    } else if (_selectedFilter == 'locked') {
      displayed = _badges.where((b) => !b.isUnlocked).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const ShapeDecoration(
        color: Color(0xFF0F1523),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.only(
            topLeft: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.6),
            topRight: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.6),
          ),
          side: BorderSide(
            color: Color(0xFFFFD700),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedChampion,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVi ? 'BẢNG THÀNH TÍCH & HUY HIỆU' : 'ACHIEVEMENTS & BADGES',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVi
                              ? 'Đã mở khóa $unlockedCount / $totalCount danh hiệu'
                              : 'Unlocked $unlockedCount of $totalCount badges',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                BouncingTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Level Progress Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isVi ? 'TIẾN TRÌNH RÈN LUYỆN' : 'MASTERY PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                ),
              ],
            ),
          ),

          // Filter Segment Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('all', isVi ? 'Tất cả ($totalCount)' : 'All ($totalCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('unlocked', isVi ? 'Đã đạt ($unlockedCount)' : 'Unlocked ($unlockedCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('locked', isVi ? 'Chưa đạt (${totalCount - unlockedCount})' : 'Locked (${totalCount - unlockedCount})'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Badges Grid List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: displayed.length,
                    itemBuilder: (context, index) {
                      final badge = displayed[index];
                      return _buildBadgeCard(badge, isVi);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Expanded(
      child: BouncingTap(
        onTap: () {
          AppHaptics.selection();
          setState(() {
            _selectedFilter = key;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(FitnessBadge badge, bool isVi) {
    final isUnlocked = badge.isUnlocked;
    final title = isVi ? badge.titleVi : badge.titleEn;
    final desc = isVi ? badge.descriptionVi : badge.descriptionEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: isUnlocked
            ? const Color(0xFF162035)
            : const Color(0xFF111726),
        shape: SmoothRectangleBorder(
          borderRadius: const SmoothBorderRadius.all(
            SmoothRadius(cornerRadius: 18, cornerSmoothing: 0.6),
          ),
          side: BorderSide(
            color: isUnlocked
                ? const Color(0xFFFFD700).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.07),
            width: 1.1,
          ),
        ),
        shadows: isUnlocked
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji / Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                    : Colors.white12,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                badge.iconEmoji,
                style: TextStyle(
                  fontSize: 26,
                  color: isUnlocked ? null : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isUnlocked ? Colors.white : Colors.white60,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, size: 10, color: Color(0xFF00FF88)),
                            const SizedBox(width: 3),
                            Text(
                              isVi ? 'ĐÃ ĐẠT' : 'UNLOCKED',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00FF88),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        badge.progressLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
