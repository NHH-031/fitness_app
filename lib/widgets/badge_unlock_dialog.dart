import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import '../models/fitness_badge.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import 'app_ui_components.dart';
import 'confetti_overlay.dart';

class BadgeUnlockDialog extends StatefulWidget {
  final FitnessBadge badge;

  const BadgeUnlockDialog({
    super.key,
    required this.badge,
  });

  static Future<void> show(BuildContext context, FitnessBadge badge) {
    AppHaptics.success();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConfettiOverlay(
        child: BadgeUnlockDialog(badge: badge),
      ),
    );
  }

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog> {
  bool _blasted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_blasted) {
      _blasted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ConfettiOverlay.of(context)?.blast();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;
    final title = isVi ? widget.badge.titleVi : widget.badge.titleEn;
    final desc = isVi ? widget.badge.descriptionVi : widget.badge.descriptionEn;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: ShapeDecoration(
          color: const Color(0xFF131A2A),
          shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(
              SmoothRadius(cornerRadius: 26, cornerSmoothing: 0.6),
            ),
            side: BorderSide(
              color: Color(0xFFFFD700),
              width: 1.5,
            ),
          ),
          shadows: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Trophy / Medal Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFEA79), Color(0xFFFF9900)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.badge.iconEmoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                isVi ? 'MỞ KHÓA HUY HIỆU MỚI! 🎉' : 'NEW BADGE UNLOCKED! 🎉',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Celebrate Button
              BouncingTap(
                onTap: () {
                  AppHaptics.light();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF9900)],
                    ),
                    shape: const SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius.all(
                        SmoothRadius(cornerRadius: 16, cornerSmoothing: 0.6),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFFFF9900).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isVi ? 'TUYỆT VỜI! TIẾP TỤC ⚡' : 'AWESOME! KEEP GOING ⚡',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
