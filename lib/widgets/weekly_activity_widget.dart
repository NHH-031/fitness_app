import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';

class WeeklyActivityWidget extends StatefulWidget {
  const WeeklyActivityWidget({super.key});

  @override
  State<WeeklyActivityWidget> createState() => WeeklyActivityWidgetState();
}

class WeeklyActivityWidgetState extends State<WeeklyActivityWidget> {
  int _weeklyMinutes = 0;
  Set<int> _activeDays = {}; // 1 = Mon, ..., 7 = Sun
  static const int _whoGoalMinutes = 150; // WHO recommended 150 mins/week

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    final minutes = await StorageService.getWeeklyActiveMinutes();
    final days = await StorageService.getWeeklyWorkoutDays();
    if (mounted) {
      setState(() {
        _weeklyMinutes = minutes;
        _activeDays = days;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percent = (_weeklyMinutes / _whoGoalMinutes).clamp(0.0, 1.0);
    final dayLabels = LocaleService.isVietnamese
        ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
        : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00C6FF).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C6FF).withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF00C6FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('weekly_activity_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocaleService.tr('who_goal_title'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percent >= 1.0
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: percent >= 1.0 ? Colors.green : Colors.white12,
                  ),
                ),
                child: Text(
                  percent >= 1.0
                      ? LocaleService.tr('target_reached_badge')
                      : '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    color: percent >= 1.0 ? Colors.greenAccent : const Color(0xFF00C6FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Stats & Circular Progress Ring
          Row(
            children: [
              CircularPercentIndicator(
                radius: 46.0,
                lineWidth: 8.0,
                percent: percent,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.white12,
                progressColor: const Color(0xFF00C6FF),
                animation: true,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_weeklyMinutes',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      LocaleService.tr('mins_short'),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('active_mins_ratio', args: {
                        'current': '$_weeklyMinutes',
                        'goal': '$_whoGoalMinutes',
                      }),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weeklyMinutes >= _whoGoalMinutes
                          ? LocaleService.tr('weekly_goal_exceeded')
                          : LocaleService.tr('weekly_goal_remaining', args: {
                              'mins': '${_whoGoalMinutes - _weeklyMinutes}',
                            }),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 7-Day Activity Heatmap
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.tr('heatmap_workout_title'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final weekday = index + 1; // 1 = Mon ... 7 = Sun
                  final isLogged = _activeDays.contains(weekday);
                  final isToday = DateTime.now().weekday == weekday;

                  return Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isLogged
                              ? const Color(0xFF00C6FF)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday
                                ? Colors.white
                                : (isLogged
                                    ? const Color(0xFF00C6FF)
                                    : Colors.white12),
                            width: isToday ? 2.0 : 1.0,
                          ),
                          boxShadow: isLogged
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00C6FF).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isLogged ? Icons.check_rounded : Icons.fitness_center_rounded,
                          color: isLogged ? Colors.black : Colors.white24,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayLabels[index],
                        style: TextStyle(
                          color: isToday
                              ? Colors.white
                              : (isLogged ? const Color(0xFF00C6FF) : Colors.grey),
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
