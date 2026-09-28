import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_formatters.dart';
import 'health_score_widget.dart';

class HealthScoreHistorySheet extends StatefulWidget {
  final Function(DateTime)? onDateSelected;

  const HealthScoreHistorySheet({
    super.key,
    this.onDateSelected,
  });

  static void show(BuildContext context, {Function(DateTime)? onDateSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HealthScoreHistorySheet(onDateSelected: onDateSelected),
    );
  }

  @override
  State<HealthScoreHistorySheet> createState() =>
      _HealthScoreHistorySheetState();
}

class _HealthScoreHistorySheetState extends State<HealthScoreHistorySheet> {
  List<DailyActivitySummary> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService.getDailySummariesList(days: 14);
    if (mounted) {
      setState(() {
        _summaries = list;
        _isLoading = false;
      });
    }
  }

  String _formatDateTitle(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      final diff = today.difference(target).inDays;

      if (diff == 0) {
        return LocaleService.tr(
          'date_nav_today',
          args: {'date': AppFormatters.formatDayMonth(date)},
        ).replaceAll(RegExp(r'[<>]'), '').trim();
      } else if (diff == 1) {
        return LocaleService.tr(
          'date_nav_yesterday',
          args: {'date': AppFormatters.formatDayMonth(date)},
        ).replaceAll(RegExp(r'[<>]'), '').trim();
      } else {
        final weekdayVi = [
          'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'
        ][date.weekday - 1];
        final weekdayEn = [
          'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
        ][date.weekday - 1];
        final w = LocaleService.isVietnamese ? weekdayVi : weekdayEn;
        return '$w, ${AppFormatters.formatDateFull(date)}';
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;
    int totalScore = 0;
    int peakScore = 0;
    int goodDays = 0;
    for (final s in _summaries) {
      totalScore += s.healthScore;
      if (s.healthScore > peakScore) peakScore = s.healthScore;
      if (s.healthScore >= 75) goodDays++;
    }
    final int avgScore =
        _summaries.isNotEmpty ? (totalScore / _summaries.length).round() : 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF141824),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF00FFA3), width: 1.5),
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
                    color: const Color(0xFF00FFA3).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF00FFA3),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('history_health_score_title'),
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

          // Summary Stats Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill(
                    label: isVi ? 'TRUNG BÌNH' : 'AVERAGE',
                    value: '$avgScore',
                    unit: '/100',
                    color: HealthScoreCalculator.getScoreColor(avgScore),
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  _buildStatPill(
                    label: isVi ? 'ĐỈNH CAO' : 'PEAK',
                    value: '$peakScore',
                    unit: '/100',
                    color: const Color(0xFF00FFA3),
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  _buildStatPill(
                    label: isVi ? 'NGÀY TỐT' : 'GOOD DAYS',
                    value: '$goodDays/${_summaries.length}',
                    unit: isVi ? 'ngày' : 'days',
                    color: const Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // List of days
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00FFA3)),
                    ),
                  )
                : _summaries.isEmpty
                    ? Center(
                        child: Text(
                          LocaleService.tr('history_empty'),
                          style: const TextStyle(
                              color: AppTheme.textSecondaryColor),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0,
                        ),
                        itemCount: _summaries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _summaries[index];
                          final scoreColor =
                              HealthScoreCalculator.getScoreColor(item.healthScore);

                          return InkWell(
                            onTap: () {
                              final d = DateTime.tryParse(item.date);
                              if (d != null && widget.onDateSelected != null) {
                                widget.onDateSelected!(d);
                                Navigator.pop(context);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: scoreColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date & Score Badge
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDateTitle(item.date),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scoreColor.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: scoreColor.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${item.healthScore}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: scoreColor,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.healthStatus,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: scoreColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Multi-pillar summary badges
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      _buildMetricTag(
                                        icon: Icons.directions_walk_rounded,
                                        label: '${AppFormatters.formatNumber(item.steps)} b',
                                        color: const Color(0xFF00F0FF),
                                      ),
                                      _buildMetricTag(
                                        icon: Icons.restaurant_rounded,
                                        label: '${item.caloriesIn} kcal',
                                        color: const Color(0xFFFFB300),
                                      ),
                                      _buildMetricTag(
                                        icon: Icons.fitness_center_rounded,
                                        label: '${item.workoutMinutes}p',
                                        color: const Color(0xFFFF4B4B),
                                      ),
                                      _buildMetricTag(
                                        icon: Icons.water_drop_rounded,
                                        label: '${item.waterCups} cốc',
                                        color: const Color(0xFF00C6FF),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
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

  Widget _buildStatPill({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondaryColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
