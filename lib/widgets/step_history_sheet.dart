import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_formatters.dart';
import '../utils/app_haptics.dart';
import 'app_ui_components.dart';

class StepHistorySheet extends StatefulWidget {
  final int goalSteps;
  final Function(DateTime)? onDateSelected;

  const StepHistorySheet({
    super.key,
    this.goalSteps = 10000,
    this.onDateSelected,
  });

  static void show(
    BuildContext context, {
    int goalSteps = 10000,
    Function(DateTime)? onDateSelected,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StepHistorySheet(
        goalSteps: goalSteps,
        onDateSelected: onDateSelected,
      ),
    );
  }

  @override
  State<StepHistorySheet> createState() => _StepHistorySheetState();
}

class _StepHistorySheetState extends State<StepHistorySheet> {
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
    int totalSteps = 0;
    int goalReachedDays = 0;
    for (final s in _summaries) {
      totalSteps += s.steps;
      if (s.steps >= widget.goalSteps) {
        goalReachedDays++;
      }
    }
    final int avgSteps =
        _summaries.isNotEmpty ? (totalSteps / _summaries.length).round() : 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF141824),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF00F0FF), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const BottomSheetDragHandle(),
          const SizedBox(height: 4),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: Color(0xFF00F0FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('history_steps_title'),
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
                    value: AppFormatters.formatNumber(avgSteps),
                    unit: isVi ? 'bước' : 'steps',
                    color: const Color(0xFF00F0FF),
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  _buildStatPill(
                    label: isVi ? 'ĐẠT MỤC TIÊU' : 'GOAL MET',
                    value: '$goalReachedDays/${_summaries.length}',
                    unit: isVi ? 'ngày' : 'days',
                    color: const Color(0xFF00FFA3),
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  _buildStatPill(
                    label: isVi ? 'TỔNG CỘNG' : 'TOTAL',
                    value: AppFormatters.formatNumber(totalSteps),
                    unit: isVi ? 'bước' : 'steps',
                    color: const Color(0xFFFFB300),
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
                          AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
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
                          final isGoalMet = item.steps >= widget.goalSteps;
                          final double progress = widget.goalSteps > 0
                              ? (item.steps / widget.goalSteps).clamp(0.0, 1.0)
                              : 0.0;
                          final int activeMins = (item.steps / 100).round();

                          return InkWell(
                            onTap: () {
                              AppHaptics.selection();
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
                                  color: isGoalMet
                                      ? const Color(0xFF00FFA3)
                                          .withValues(alpha: 0.3)
                                      : const Color(0xFF00F0FF)
                                          .withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date & Steps Number
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
                                      Row(
                                        children: [
                                          Text(
                                            AppFormatters.formatNumber(item.steps),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: isGoalMet
                                                  ? const Color(0xFF00FFA3)
                                                  : Colors.white,
                                            ),
                                          ),
                                          Text(
                                            ' / ${widget.goalSteps}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                          if (isGoalMet) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 14,
                                              color: Color(0xFF00FFA3),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isGoalMet
                                            ? const Color(0xFF00FFA3)
                                            : const Color(0xFF00F0FF),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Distance, Kcal, Mins metrics
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.place_rounded,
                                              size: 13,
                                              color: Color(0xFF00F0FF)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item.distanceKm.toStringAsFixed(2)} km',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.local_fire_department_rounded,
                                              size: 13,
                                              color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item.stepCalories} kcal',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_rounded,
                                              size: 13,
                                              color: Color(0xFF00FFA3)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$activeMins ${isVi ? 'phút' : 'mins'}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
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
