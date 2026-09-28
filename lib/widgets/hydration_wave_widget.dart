import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';

class HydrationWaveWidget extends StatefulWidget {
  final VoidCallback? onWaterUpdated;

  const HydrationWaveWidget({super.key, this.onWaterUpdated});

  @override
  State<HydrationWaveWidget> createState() => _HydrationWaveWidgetState();
}

class _HydrationWaveWidgetState extends State<HydrationWaveWidget>
    with SingleTickerProviderStateMixin {
  int _waterVolumeMl = 0;
  final int _targetVolumeMl = 2500;
  late AnimationController _waveController;
  List<FoodLogEntry> _todayFoods = [];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadData();
    StorageService.waterUpdateNotifier.addListener(_loadData);
    StorageService.foodUpdateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    StorageService.waterUpdateNotifier.removeListener(_loadData);
    StorageService.foodUpdateNotifier.removeListener(_loadData);
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ml = await StorageService.getTodayWaterVolume();
    final foods = await StorageService.getTodayFoodLogs();
    if (mounted) {
      setState(() {
        _waterVolumeMl = ml;
        _todayFoods = foods;
      });
    }
  }

  Future<void> _addWater(int ml) async {
    await StorageService.addWaterVolume(ml);
    await _loadData();
    widget.onWaterUpdated?.call();
  }

  Future<void> _removeWater(int ml) async {
    await StorageService.removeWaterVolume(ml);
    await _loadData();
    widget.onWaterUpdated?.call();
  }

  bool get _hasFiberOrVeggies {
    final keywords = [
      'rau', 'salad', 'cải', 'spinach', 'broccoli', 'vegetable', 'fruit',
      'táo', 'chuối', 'cam', 'quinoa', 'oat', 'avocado', 'bơ', 'trái cây',
      'berry', 'carrot', 'cà rốt', 'dưa', 'greens'
    ];
    for (final food in _todayFoods) {
      final nameLower = food.name.toLowerCase();
      for (final kw in keywords) {
        if (nameLower.contains(kw)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_waterVolumeMl / _targetVolumeMl).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C6FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00C6FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF00C6FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('hydration_micronutrients_title'),
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        LocaleService.tr('hydration_target_daily', args: {'target': '$_targetVolumeMl'}),
                        style: AppTheme.font(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '$_waterVolumeMl ml',
                style: AppTheme.font(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF00C6FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Wave Visualization Box
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1B2230),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Animated Wave
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 100),
                        painter: _WavePainter(
                          progress: progress,
                          wavePhase: _waveController.value * 2 * math.pi,
                        ),
                      );
                    },
                  ),
                  // Centered Info
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.opacity_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocaleService.tr('hydration_percent_reached', args: {'percent': '$percent'}),
                          style: AppTheme.font(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($_waterVolumeMl/$_targetVolumeMl ml)',
                          style: AppTheme.font(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Hydration Buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickAddButton('+250ml', 250),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAddButton('+500ml', 500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAddButton('+1,000ml', 1000),
              ),
              const SizedBox(width: 8),
              // Minus 250ml button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _waterVolumeMl > 0 ? () => _removeWater(250) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Micronutrients & Fiber Check Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hasFiberOrVeggies
                  ? const Color(0xFF0F2E22)
                  : const Color(0xFF2E2412),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasFiberOrVeggies
                    ? Colors.greenAccent.withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _hasFiberOrVeggies ? '🥦' : '💡',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasFiberOrVeggies
                            ? LocaleService.tr('fiber_on_track_title')
                            : LocaleService.tr('fiber_boost_title'),
                        style: AppTheme.font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _hasFiberOrVeggies
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasFiberOrVeggies
                            ? LocaleService.tr('fiber_on_track_sub')
                            : LocaleService.tr('fiber_boost_sub'),
                        style: AppTheme.font(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(String label, int ml) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addWater(ml),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF00C6FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF00C6FF).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: AppTheme.font(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00C6FF),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  _WavePainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final baseHeight = size.height * (1.0 - progress);
    const waveAmplitude = 4.0;

    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);

    for (double x = 0; x <= size.width; x += 1) {
      final y = baseHeight +
          math.sin((x / size.width * 2 * math.pi) + wavePhase) * waveAmplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.wavePhase != wavePhase;
  }
}
