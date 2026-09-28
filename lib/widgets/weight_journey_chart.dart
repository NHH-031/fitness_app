import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import 'app_ui_components.dart';

class WeightJourneyChart extends StatefulWidget {
  const WeightJourneyChart({super.key});

  @override
  State<WeightJourneyChart> createState() => _WeightJourneyChartState();
}

class _WeightJourneyChartState extends State<WeightJourneyChart> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _weightLogs = [];
  double _currentWeight = 70.0;
  double _targetWeight = 68.0;
  double _startWeight = 70.0;
  int _cumulativeDeficit = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    StorageService.profileUpdateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    StorageService.profileUpdateNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile = await StorageService.getUserProfile();
    final logs = await StorageService.getWeightLogs();

    // Tính tổng thâm hụt calo tích lũy trong 14 ngày gần nhất
    int cumulativeDeficit = 0;
    final now = DateTime.now();
    for (int i = 0; i < 14; i++) {
      final summary = await StorageService.getDailySummary(now.subtract(Duration(days: i)));
      final deficit = summary.caloriesOut - summary.caloriesIn;
      if (deficit > 0) {
        cumulativeDeficit += deficit;
      }
    }

    if (mounted) {
      setState(() {
        _currentWeight = profile.weight;
        _targetWeight = profile.targetWeight;
        _weightLogs = logs;
        _startWeight = logs.isNotEmpty ? (logs.first['weight'] as num).toDouble() : profile.weight;
        _cumulativeDeficit = cumulativeDeficit;
        _isLoading = false;
      });
    }
  }

  void _showLogWeightDialog() {
    AppHaptics.medium();
    double tempWeight = _currentWeight;
    final isVi = LocaleService.isVietnamese;
    final controller = TextEditingController(text: tempWeight.toStringAsFixed(1));

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(22),
                decoration: ShapeDecoration(
                  color: const Color(0xFF131A2A),
                  shape: SmoothRectangleBorder(
                    borderRadius: const SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 24, cornerSmoothing: 0.6),
                    ),
                    side: BorderSide(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedBodyWeight,
                                  color: Color(0xFF00FF88),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isVi ? 'Ghi nhận cân nặng' : 'Log New Weight',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: const Icon(Icons.close, color: Colors.white54, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stepper & Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BouncingTap(
                            onTap: () {
                              AppHaptics.light();
                              setDialogState(() {
                                tempWeight = max(30.0, tempWeight - 0.5);
                                controller.text = tempWeight.toStringAsFixed(1);
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.remove, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00FF88)),
                            ),
                            child: TextField(
                              controller: controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                suffixText: 'kg',
                                suffixStyle: TextStyle(fontSize: 14, color: Colors.white60),
                              ),
                              onChanged: (val) {
                                final d = double.tryParse(val);
                                if (d != null && d > 20 && d < 300) {
                                  tempWeight = d;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          BouncingTap(
                            onTap: () {
                              AppHaptics.light();
                              setDialogState(() {
                                tempWeight = min(250.0, tempWeight + 0.5);
                                controller.text = tempWeight.toStringAsFixed(1);
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Submit Button
                      BouncingTap(
                        onTap: () async {
                          AppHaptics.success();
                          await StorageService.logWeight(tempWeight);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          _loadData();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: ShapeDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00FF88), Color(0xFF00C974)],
                            ),
                            shape: const SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius.all(
                                SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isVi ? 'LƯU CÂN NẶNG' : 'SAVE WEIGHT',
                              style: const TextStyle(
                                fontSize: 13,
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;
    if (_isLoading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF00FF88))),
      );
    }

    // Prepare line spots
    final List<FlSpot> spots = [];
    double minY = _currentWeight;
    double maxY = _currentWeight;

    for (int i = 0; i < _weightLogs.length; i++) {
      final w = (_weightLogs[i]['weight'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), w));
      minY = min(minY, w);
      maxY = max(maxY, w);
    }

    minY = (minY - 2).floorToDouble();
    maxY = (maxY + 2).ceilToDouble();

    // Estimated fat loss in kg based on cumulative deficit (7700 kcal ≈ 1 kg)
    final double estFatLossKg = (_cumulativeDeficit / 7700.0);
    final double weightChange = _currentWeight - _startWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Log Weight button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$_currentWeight kg',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (weightChange <= 0 ? const Color(0xFF00FF88) : Colors.orange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${weightChange <= 0 ? "" : "+"}${weightChange.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: weightChange <= 0 ? const Color(0xFF00FF88) : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isVi ? "Mục tiêu: " : "Target: "}$_targetWeight kg',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            BouncingTap(
              onTap: _showLogWeightDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: Color(0xFF00FF88)),
                    const SizedBox(width: 4),
                    Text(
                      isVi ? 'Ghi Cân Nặng' : 'Log Weight',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00FF88),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Line Chart
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E283E),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.spotIndex;
                      final date = idx < _weightLogs.length ? _weightLogs[idx]['date'] : '';
                      return LineTooltipItem(
                        '$date\n${spot.y} kg',
                        const TextStyle(
                          color: Color(0xFF00FF88),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: 1.0,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}kg',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _weightLogs.length) return const SizedBox.shrink();
                      final dateStr = _weightLogs[idx]['date'].toString();
                      final parts = dateStr.split('-');
                      final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : dateStr;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1.0,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF00FF88),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF00FF88),
                      strokeWidth: 2,
                      strokeColor: Colors.black,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF00FF88).withValues(alpha: 0.25),
                        const Color(0xFF00FF88).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Deficit Correlation Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF88).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00FF88).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isVi
                      ? 'Thâm hụt tích lũy $_cumulativeDeficit kcal tương đương giảm ~${estFatLossKg.toStringAsFixed(2)} kg mỡ thuần!'
                      : 'Cumulative deficit of $_cumulativeDeficit kcal ≈ ~${estFatLossKg.toStringAsFixed(2)} kg pure fat burned!',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
