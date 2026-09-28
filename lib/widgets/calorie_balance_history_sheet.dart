import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_formatters.dart';

class CalorieBalanceHistorySheet extends StatefulWidget {
  final Function(DateTime)? onDateSelected;

  const CalorieBalanceHistorySheet({
    super.key,
    this.onDateSelected,
  });

  static void show(BuildContext context, {Function(DateTime)? onDateSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CalorieBalanceHistorySheet(onDateSelected: onDateSelected),
    );
  }

  @override
  State<CalorieBalanceHistorySheet> createState() =>
      _CalorieBalanceHistorySheetState();
}

class _CalorieBalanceHistorySheetState
    extends State<CalorieBalanceHistorySheet> {
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
    int totalIn = 0;
    int totalOut = 0;
    for (final s in _summaries) {
      totalIn += s.caloriesIn;
      totalOut += s.caloriesOut;
    }
    final int avgIn = _summaries.isNotEmpty ? (totalIn / _summaries.length).round() : 0;
    final int avgOut = _summaries.isNotEmpty ? (totalOut / _summaries.length).round() : 0;
    final int avgNet = avgIn - avgOut;

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
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
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
                        LocaleService.tr('history_calorie_title'),
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

          // Summary Avg Banner
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
                    label: isVi ? 'TB NẠP' : 'AVG IN',
                    value: '$avgIn',
                    unit: 'kcal',
                    color: const Color(0xFF00F0FF),
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  _buildStatPill(
                    label: isVi ? 'TB TIÊU HAO' : 'AVG OUT',
                    value: '$avgOut',
                    unit: 'kcal',
                    color: Colors.orange,
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  _buildStatPill(
                    label: isVi ? 'TB CÂN BẰNG' : 'AVG NET',
                    value: (avgNet > 0 ? '+$avgNet' : '$avgNet'),
                    unit: 'kcal',
                    color: avgNet <= 0 ? const Color(0xFF00FFA3) : Colors.orangeAccent,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                    ),
                  )
                : _summaries.isEmpty
                    ? Center(
                        child: Text(
                          LocaleService.tr('history_empty'),
                          style: const TextStyle(color: AppTheme.textSecondaryColor),
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
                          final isDeficit = item.netBalance <= 0;
                          final absNet = item.netBalance.abs();
                          final inCal = item.caloriesIn;
                          final outCal = item.caloriesOut;

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
                                  color: isDeficit
                                      ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                                      : Colors.orange.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row Date + Status Badge
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
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (isDeficit
                                                  ? const Color(0xFF00FFA3)
                                                  : Colors.orange)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: (isDeficit
                                                    ? const Color(0xFF00FFA3)
                                                    : Colors.orange)
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          isDeficit
                                              ? LocaleService.tr('deficit_label',
                                                  args: {'amount': absNet.toString()})
                                              : LocaleService.tr('surplus_label',
                                                  args: {'amount': absNet.toString()}),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isDeficit
                                                ? const Color(0xFF00FFA3)
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Row Cal In & Cal Out metrics
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.restaurant_rounded,
                                              size: 13,
                                              color: Color(0xFF00F0FF),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              LocaleService.tr('calories_in'),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$inCal kcal',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF00F0FF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department_rounded,
                                              size: 13,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              LocaleService.tr('calories_out'),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$outCal kcal',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Dual ratio bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: SizedBox(
                                      height: 5,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: (inCal > 0 ? inCal : 1),
                                            child: Container(
                                              color: const Color(0xFF00F0FF),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            flex: (outCal > 0 ? outCal : 1),
                                            child: Container(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
