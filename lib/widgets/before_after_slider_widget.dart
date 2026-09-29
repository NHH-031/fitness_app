import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_haptics.dart';

class BeforeAfterSliderWidget extends StatefulWidget {
  final String beforeImagePath;
  final String afterImagePath;
  final String beforeLabel;
  final String afterLabel;
  final double height;

  const BeforeAfterSliderWidget({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.beforeLabel = 'Trước (Before)',
    this.afterLabel = 'Sau (After)',
    this.height = 320,
  });

  @override
  State<BeforeAfterSliderWidget> createState() => _BeforeAfterSliderWidgetState();
}

class _BeforeAfterSliderWidgetState extends State<BeforeAfterSliderWidget> {
  double _sliderPosition = 0.5; // 0.0 to 1.0

  Widget _buildImage(String path, {required bool isBefore}) {
    if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.height,
      );
    }

    // High-tech fallback silhouette when user hasn't set photo yet
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBefore
              ? [const Color(0xFF1E2638), const Color(0xFF131724)]
              : [const Color(0xFF0F2B38), const Color(0xFF00384D)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBefore ? Icons.fitness_center_rounded : Icons.bolt_rounded,
              color: isBefore ? Colors.white30 : const Color(0xFF00F0FF),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              isBefore ? 'Ảnh khởi đầu' : 'Ảnh tiến trình vóc dáng',
              style: TextStyle(
                color: isBefore ? Colors.white60 : const Color(0xFF00F0FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                // 1. "After" layer (Bottom full)
                Positioned.fill(
                  child: _buildImage(widget.afterImagePath, isBefore: false),
                ),

                // 2. "Before" layer (Top clipped by slider)
                Positioned.fill(
                  child: ClipRect(
                    clipper: _HorizontalSplitClipper(_sliderPosition),
                    child: _buildImage(widget.beforeImagePath, isBefore: true),
                  ),
                ),

                // 3. Floating Badges
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      widget.beforeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00F0FF)),
                    ),
                    child: Text(
                      widget.afterLabel,
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                // 4. Center Divider Line with Handle
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: (width * _sliderPosition) - 1.5,
                  child: Container(
                    width: 3,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00F0FF),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00F0FF),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Draggable Handle Circle
                Positioned(
                  top: (widget.height / 2) - 20,
                  left: (width * _sliderPosition) - 20,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _sliderPosition = ((details.localPosition.dx + (width * _sliderPosition) - 20) / width)
                            .clamp(0.05, 0.95);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Full-Width Drag Detector
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _sliderPosition = (details.localPosition.dx / width).clamp(0.05, 0.95);
                      });
                    },
                    onHorizontalDragStart: (_) => AppHaptics.light(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  final double splitFactor;

  _HorizontalSplitClipper(this.splitFactor);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * splitFactor, size.height);
  }

  @override
  bool shouldReclip(covariant _HorizontalSplitClipper oldClipper) {
    return oldClipper.splitFactor != splitFactor;
  }
}
