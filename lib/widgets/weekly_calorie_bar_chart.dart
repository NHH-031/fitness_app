import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';

class WeeklyCalorieBarChart extends StatefulWidget {
  const WeeklyCalorieBarChart({super.key});

  @override
  State<WeeklyCalorieBarChart> createState() => _WeeklyCalorieBarChartState();
}

class _WeeklyCalorieBarChartState extends State<WeeklyCalorieBarChart> {
  bool _isLoading = true;
  List<_DayCalorieData> _weekData = [];
  int _avgIn = 0;
  int _avgOut = 0;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    final now = DateTime.now();
    final List<_DayCalorieData> list = [];
    int sumIn = 0;
    int sumOut = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final summary = await StorageService.getDailySummary(date);
      final isToday = i == 0;

      final weekdayVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][date.weekday - 1];
      final weekdayEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

      list.add(_DayCalorieData(
        date: date,
        dayLabel: LocaleService.isVietnamese ? weekdayVi : weekdayEn,
        caloriesIn: summary.caloriesIn,
        caloriesOut: summary.caloriesOut,
        isToday: isToday,
      ));

      sumIn += summary.caloriesIn;
      sumOut += summary.caloriesOut;
    }

    if (mounted) {
      setState(() {
        _weekData = list;
        _avgIn = (sumIn / 7).round();
        _avgOut = (sumOut / 7).round();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;
    final netAvg = _avgIn - _avgOut;
    final isNetDeficit = netAvg < 0;

    if (_isLoading) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
        ),
      );
    }

    // Determine max Y for scale
    double maxY = 2500;
    for (final d in _weekData) {
      maxY = max(maxY, max(d.caloriesIn.toDouble(), d.caloriesOut.toDouble()));
    }
    maxY = (maxY * 1.15).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend & Summary Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildLegendItem(const Color(0xFF00F0FF), isVi ? 'Nạp vào' : 'Intake'),
                const SizedBox(width: 14),
                _buildLegendItem(Colors.orange, isVi ? 'Tiêu hao' : 'Burned'),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isNetDeficit ? const Color(0xFF00FF88) : Colors.orange)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isNetDeficit ? const Color(0xFF00FF88) : Colors.orange)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                isNetDeficit
                    ? (isVi ? 'Thâm hụt TB -${netAvg.abs()} kcal/ngày' : 'Avg Deficit -${netAvg.abs()} kcal/d')
                    : (isVi ? 'Thặng dư TB +$netAvg kcal/ngày' : 'Avg Surplus +$netAvg kcal/d'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isNetDeficit ? const Color(0xFF00FF88) : Colors.orange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bar Chart
        SizedBox(
          height: 210,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E283E),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIntake = rodIndex == 0;
                    final day = _weekData[groupIndex];
                    return BarTooltipItem(
                      '${day.dayLabel}\n${isIntake ? (isVi ? 'Nạp: ' : 'In: ') : (isVi ? 'Tiêu: ' : 'Out: ')}${rod.toY.round()} kcal',
                      TextStyle(
                        color: isIntake ? const Color(0xFF00F0FF) : Colors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: (maxY / 4).roundToDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '${(value / 1000).toStringAsFixed(1)}k',
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
                      if (idx < 0 || idx >= _weekData.length) return const SizedBox.shrink();
                      final item = _weekData[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          item.dayLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: item.isToday ? FontWeight.w900 : FontWeight.w600,
                            color: item.isToday ? const Color(0xFF00F0FF) : Colors.white60,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 4).roundToDouble(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.06),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(_weekData.length, (index) {
                final d = _weekData[index];
                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    // Calo Nạp vào (Cyan)
                    BarChartRodData(
                      toY: d.caloriesIn.toDouble(),
                      color: const Color(0xFF00F0FF),
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    // Calo Tiêu hao (Orange)
                    BarChartRodData(
                      toY: d.caloriesOut.toDouble(),
                      color: Colors.orange,
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Quick Daily Average Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '${isVi ? "Nạp TB: " : "Avg In: "}$_avgIn kcal',
                style: const TextStyle(fontSize: 11, color: Color(0xFF00F0FF), fontWeight: FontWeight.w700),
              ),
              Container(width: 1, height: 12, color: Colors.white12),
              Text(
                '${isVi ? "Tiêu TB: " : "Avg Out: "}$_avgOut kcal',
                style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DayCalorieData {
  final DateTime date;
  final String dayLabel;
  final int caloriesIn;
  final int caloriesOut;
  final bool isToday;

  _DayCalorieData({
    required this.date,
    required this.dayLabel,
    required this.caloriesIn,
    required this.caloriesOut,
    required this.isToday,
  });
}
