import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();

  static ConfettiOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<ConfettiOverlayState>();
  }
}

class ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
        if (_isPlaying) {
          setState(() {
            for (final p in _particles) {
              p.update();
            }
          });
        }
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isPlaying = false;
            _particles.clear();
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void blast({int count = 65}) {
    _particles.clear();
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFF00F0FF), // Neon Cyan
      const Color(0xFFFF007A), // Hot Pink
      const Color(0xFF00FF88), // Emerald Green
      const Color(0xFFFF7A00), // Orange
      const Color(0xFFB026FF), // Neon Purple
    ];

    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi * 0.85;
      final speed = 8.0 + _random.nextDouble() * 14.0;
      _particles.add(
        _ConfettiParticle(
          x: 0.5,
          y: 0.35,
          vx: cos(angle) * speed * 0.005,
          vy: sin(angle) * speed * 0.008,
          color: colors[_random.nextInt(colors.length)],
          size: 6.0 + _random.nextDouble() * 6.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.25,
          isCircle: _random.nextBool(),
        ),
      );
    }

    _isPlaying = true;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isPlaying)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x; // normalized 0..1
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.00035; // gravity
    vx *= 0.985; // drag
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
