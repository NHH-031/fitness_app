import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_formatters.dart';

class ChartHistorySheet extends StatefulWidget {
  final Function(DateTime)? onDateSelected;

  const ChartHistorySheet({
    super.key,
    this.onDateSelected,
  });

  static void show(BuildContext context, {Function(DateTime)? onDateSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChartHistorySheet(onDateSelected: onDateSelected),
    );
  }

  @override
  State<ChartHistorySheet> createState() => _ChartHistorySheetState();
}

class _ChartHistorySheetState extends State<ChartHistorySheet> {
  List<DailyActivitySummary> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService.getDailySummariesList(days: 7);
    if (mounted) {
      setState(() {
        _summaries = list.reversed.toList(); // chronological order for chart
        _isLoading = false;
      });
    }
  }

  String _formatWeekday(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final weekdayVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][date.weekday - 1];
      final weekdayEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
      return LocaleService.isVietnamese ? weekdayVi : weekdayEn;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    int maxVal = 2500;
    for (final s in _summaries) {
      if (s.caloriesIn > maxVal) maxVal = s.caloriesIn;
      if (s.caloriesOut > maxVal) maxVal = s.caloriesOut;
    }
    final double maxY = ((maxVal + 499) ~/ 500) * 500.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF141824),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.orange, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('history_chart_title'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _summaries.length <= 1
                            ? LocaleService.tr('history_today_only')
                            : LocaleService.tr(
                                'history_actual_days',
                                args: {'count': _summaries.length.toString()},
                              ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFF00F0FF), LocaleService.tr('calories_in')),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.orange, LocaleService.tr('calories_out')),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Chart Section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : _summaries.isEmpty
                    ? Center(
                        child: Text(
                          LocaleService.tr('history_empty'),
                          style: const TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            // FlChart BarChart
                            Container(
                              height: 220,
                              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: BarChart(
                                BarChartData(
                                  maxY: maxY,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final isCyan = rodIndex == 0;
                                        final label = isCyan ? 'In' : 'Out';
                                        return BarTooltipItem(
                                          '$label: ${rod.toY.round()} kcal',
                                          TextStyle(
                                            color: isCyan ? const Color(0xFF00F0FF) : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 38,
                                        interval: maxY > 3000 ? 1500 : 1000,
                                        getTitlesWidget: (val, meta) {
                                          if (val == 0) return const SizedBox.shrink();
                                          return Text(
                                            '${(val / 1000).toStringAsFixed(1)}k',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondaryColor,
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          final idx = val.toInt();
                                          if (idx >= 0 && idx < _summaries.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 6.0),
                                              child: Text(
                                                _formatWeekday(_summaries[idx].date),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(_summaries.length, (idx) {
                                    final s = _summaries[idx];
                                    return BarChartGroupData(
                                      x: idx,
                                      barRods: [
                                        BarChartRodData(
                                          toY: max(0.0, s.caloriesIn.toDouble()),
                                          color: const Color(0xFF00F0FF),
                                          width: 9,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        BarChartRodData(
                                          toY: max(0.0, s.caloriesOut.toDouble()),
                                          color: Colors.orange,
                                          width: 9,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // List of 7 days
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _summaries.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                // show newest first in the list
                                final item = _summaries[_summaries.length - 1 - index];
                                final isDeficit = item.netBalance <= 0;
                                final absNet = item.netBalance.abs();
                                final date = DateTime.tryParse(item.date);
                                final dateFormatted = date != null
                                    ? AppFormatters.formatDateFull(date)
                                    : item.date;

                                return InkWell(
                                  onTap: () {
                                    if (date != null && widget.onDateSelected != null) {
                                      widget.onDateSelected!(date);
                                      Navigator.pop(context);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDeficit
                                            ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                                            : Colors.orange.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          dateFormatted,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'In: ${item.caloriesIn}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00F0FF),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Out: ${item.caloriesOut}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isDeficit ? const Color(0xFF00FFA3) : Colors.orange)
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            absNet == 0
                                                ? '0'
                                                : (isDeficit ? '-$absNet' : '+$absNet'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isDeficit ? const Color(0xFF00FFA3) : Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
