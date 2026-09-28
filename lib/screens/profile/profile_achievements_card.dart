import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/locale_service.dart';
import '../../utils/app_haptics.dart';
import '../../widgets/achievements_sheet.dart';

class ProfileAchievementsCard extends StatelessWidget {
  const ProfileAchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;

    return GestureDetector(
      onTap: () {
        AppHaptics.medium();
        AchievementsSheet.show(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedChampion,
                color: Color(0xFFFFD700),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVi
                        ? 'BẢNG THÀNH TÍCH & HUY HIỆU'
                        : 'ACHIEVEMENTS & BADGES',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVi
                        ? 'Xem huy hiệu đã mở khóa & thử thách'
                        : 'View unlocked badges & challenges',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFFFD700), size: 14),
          ],
        ),
      ),
    );
  }
}
