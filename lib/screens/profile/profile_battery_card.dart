import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';

class ProfileBatteryCard extends StatelessWidget {
  final bool isBatteryExempt;
  final VoidCallback onRequestBatteryOptimization;

  const ProfileBatteryCard({
    super.key,
    required this.isBatteryExempt,
    required this.onRequestBatteryOptimization,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isBatteryExempt
              ? const Color(0xFF00FFA3).withValues(alpha: 0.3)
              : const Color(0xFFFF9E00).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBatteryExempt
                      ? const Color(0xFF00FFA3).withValues(alpha: 0.15)
                      : const Color(0xFFFF9E00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedEnergy,
                  color: isBatteryExempt
                      ? const Color(0xFF00FFA3)
                      : const Color(0xFFFF9E00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocaleService.tr('background_service_title'),
                  style: AppTheme.font(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isBatteryExempt
                      ? const Color(0xFF00FFA3).withValues(alpha: 0.15)
                      : const Color(0xFFFF9E00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isBatteryExempt
                        ? const Color(0xFF00FFA3).withValues(alpha: 0.35)
                        : const Color(0xFFFF9E00).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isBatteryExempt
                            ? const Color(0xFF00FFA3)
                            : const Color(0xFFFF9E00),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBatteryExempt
                          ? LocaleService.tr('battery_optimized_badge')
                          : LocaleService.tr('battery_need_permission_badge'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isBatteryExempt
                            ? const Color(0xFF00FFA3)
                            : const Color(0xFFFF9E00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isBatteryExempt
                ? LocaleService.tr('battery_optimized_active')
                : LocaleService.tr('battery_optimize_prompt'),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          if (!isBatteryExempt) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRequestBatteryOptimization,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedZap,
                  size: 16,
                  color: Colors.black,
                ),
                label: Text(
                  LocaleService.tr('battery_optimize_action'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9E00),
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
