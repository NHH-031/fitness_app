import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../services/locale_service.dart';
import '../widgets/macro_donut_chart_widget.dart';
import '../widgets/meal_category_card_widget.dart';
import '../widgets/hydration_wave_widget.dart';
import '../widgets/ai_nutritionist_chat_dialog.dart';
import 'ai_chat_history_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {

  String _formatDate() {
    final now = DateTime.now();
    if (LocaleService.isVietnamese) {
      final weekdays = [
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ Nhật'
      ];
      final dayName = weekdays[now.weekday - 1];
      return '$dayName, ${now.day} thg ${now.month}';
    } else {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final dayName = weekdays[now.weekday - 1];
      final monthName = months[now.month - 1];
      return '$dayName, $monthName ${now.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with AI Advisor shortcut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00F0FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDate().toUpperCase(),
                                style: AppTheme.font(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00F0FF),
                                  letterSpacing: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleService.tr('nutrition_hub_title'),
                          style: AppTheme.font(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chat AI History Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiChatHistoryScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        color: Color(0xFF00F0FF),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chat AI Button
                  GestureDetector(
                    onTap: () => AiNutritionistChatDialog.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0072FF), Color(0xFF00F0FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedAiSparkles,
                            color: Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            LocaleService.tr('ai_advisor_btn'),
                            style: AppTheme.font(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Macro Donut Chart & Goal Selector
              const MacroDonutChartWidget(),
              const SizedBox(height: 24),

              // Section Title: Meal Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleService.tr('daily_meals_title'),
                    style: AppTheme.font(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    LocaleService.tr('meal_categories_count'),
                    style: AppTheme.font(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4 Meal Categories
              MealCategoryCardWidget(
                mealType: 'Breakfast',
                title: LocaleService.tr('meal_breakfast'),
                hugeIcon: HugeIcons.strokeRoundedEggFried,
                iconColor: const Color(0xFFFF9E00),
                emoji: '🍳',
                timeRange: '05:00 - 10:59',
                budgetCalories: 500,
              ),
              MealCategoryCardWidget(
                mealType: 'Lunch',
                title: LocaleService.tr('meal_lunch'),
                hugeIcon: HugeIcons.strokeRoundedRiceBowl01,
                iconColor: const Color(0xFF34C759),
                emoji: '🍚',
                timeRange: '11:00 - 15:59',
                budgetCalories: 700,
              ),
              MealCategoryCardWidget(
                mealType: 'Dinner',
                title: LocaleService.tr('meal_dinner'),
                hugeIcon: HugeIcons.strokeRoundedSpoonAndFork,
                iconColor: const Color(0xFFAF52DE),
                emoji: '🍽️',
                timeRange: '17:00 - 21:59',
                budgetCalories: 600,
              ),
              MealCategoryCardWidget(
                mealType: 'Snack',
                title: LocaleService.tr('meal_snack'),
                hugeIcon: HugeIcons.strokeRoundedApple01,
                iconColor: const Color(0xFF00F0FF),
                emoji: '🍎',
                timeRange: LocaleService.tr('snack_time_range'),
                budgetCalories: 250,
              ),
              const SizedBox(height: 16),

              // Hydration Wave & Micronutrients Widget
              const HydrationWaveWidget(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
