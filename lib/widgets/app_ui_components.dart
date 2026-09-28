import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';

enum AppHapticFeedbackType { light, medium, heavy, selection, none }

/// A premium tactile bouncing touch interaction widget.
/// When pressed, gently scales down and springs back smoothly with physical haptic vibration.
class BouncingTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final AppHapticFeedbackType hapticType;

  const BouncingTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 110),
    this.hapticType = AppHapticFeedbackType.light,
  });

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap> {
  bool _isPressed = false;

  void _triggerHaptic() {
    switch (widget.hapticType) {
      case AppHapticFeedbackType.light:
        AppHaptics.light();
        break;
      case AppHapticFeedbackType.medium:
        AppHaptics.medium();
        break;
      case AppHapticFeedbackType.heavy:
        AppHaptics.heavy();
        break;
      case AppHapticFeedbackType.selection:
        AppHaptics.selection();
        break;
      case AppHapticFeedbackType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
          _triggerHaptic();
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// A high-end Squircle card with iOS/Figma continuous curve smoothing,
/// dual-tone subtle gradient, and radiant rim lighting.
class SquircleCard extends StatelessWidget {
  final Widget child;
  final double cornerRadius;
  final double cornerSmoothing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? surfaceColor;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final Color? glowColor;
  final double glowRadius;
  final VoidCallback? onTap;

  const SquircleCard({
    super.key,
    required this.child,
    this.cornerRadius = 22,
    this.cornerSmoothing = 0.6,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.surfaceColor,
    this.gradientColors,
    this.borderColor,
    this.glowColor,
    this.glowRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          surfaceColor ?? const Color(0xFF161922),
          surfaceColor?.withValues(alpha: 0.85) ?? const Color(0xFF0F1118),
        ];

    final cardContent = Container(
      margin: margin,
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: cornerRadius,
            cornerSmoothing: cornerSmoothing,
          ),
          side: BorderSide(
            color: borderColor ?? Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shadows: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.12),
                  blurRadius: glowRadius,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: cornerRadius,
          cornerSmoothing: cornerSmoothing,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return BouncingTap(onTap: onTap, child: cardContent);
    }
    return cardContent;
  }
}

/// A modern Squircle Primary Button with gradient fill, neon rim, and tactile spring feedback.
class SquircleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final String label;
  final List<Color>? gradientColors;
  final Color textColor;
  final double height;
  final double cornerRadius;
  final bool isFullWidth;
  final Color? glowColor;

  const SquircleButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.gradientColors,
    this.textColor = Colors.black,
    this.height = 48,
    this.cornerRadius = 16,
    this.isFullWidth = true,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        const [
          Color(0xFF00F0FF),
          Color(0xFF00B0FF),
        ];

    Widget content = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: cornerRadius,
            cornerSmoothing: 0.6,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shadows: [
          BoxShadow(
            color: (glowColor ?? colors.first).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: AppTheme.font(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return BouncingTap(
      onTap: onPressed,
      child: content,
    );
  }
}

/// A specialized Liquid Drink Capsule Button with aquatic wave glow.
class LiquidDrinkButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final String? sublabel;
  final Widget? icon;
  final bool isPrimary;

  const LiquidDrinkButton({
    super.key,
    required this.onTap,
    required this.label,
    this.sublabel,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isPrimary
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.05),
            ],
          );

    return BouncingTap(
      onTap: onTap,
      scaleDown: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 0.6,
            ),
            side: BorderSide(
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          gradient: gradient,
          shadows: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: -1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isPrimary ? Colors.white : Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isPrimary ? Colors.white70 : Colors.white38,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
