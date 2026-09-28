import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import 'calories_in_history_sheet.dart';
import 'calories_out_breakdown_sheet.dart';
import 'calorie_balance_history_sheet.dart';
import 'app_ui_components.dart';

class CalorieBalanceHeroWidget extends StatefulWidget {
  final int currentSteps;
  final DateTime? selectedDate;

  const CalorieBalanceHeroWidget({
    super.key,
    this.currentSteps = 0,
    this.selectedDate,
  });

  @override
  State<CalorieBalanceHeroWidget> createState() => _CalorieBalanceHeroWidgetState();
}

class _CalorieBalanceHeroWidgetState extends State<CalorieBalanceHeroWidget> {
  int _caloriesIn = 0;
  int _caloriesOut = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshBalance();
    StorageService.dataUpdateNotifier.addListener(_refreshBalance);
  }

  @override
  void didUpdateWidget(covariant CalorieBalanceHeroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSteps != widget.currentSteps ||
        oldWidget.selectedDate != widget.selectedDate) {
      _refreshBalance();
    }
  }

  @override
  void dispose() {
    StorageService.dataUpdateNotifier.removeListener(_refreshBalance);
    super.dispose();
  }

  Future<void> _refreshBalance() async {
    final targetDate = widget.selectedDate ?? DateTime.now();
    final now = DateTime.now();
    final bool isToday = targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    final cin = await StorageService.getTotalCaloriesInByDate(targetDate);
    final cout = await StorageService.calculateCaloriesBurnedByDate(
      date: targetDate,
      steps: isToday ? widget.currentSteps : null,
    );

    if (mounted) {
      setState(() {
        _caloriesIn = cin;
        _caloriesOut = cout;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final int net = _caloriesIn - _caloriesOut;
    final bool isDeficit = net <= 0;
    final int absNet = net.abs();
    final glowThemeColor = isDeficit ? const Color(0xFF00F0FF) : Colors.orange;

    return SquircleCard(
      cornerRadius: 26,
      borderColor: glowThemeColor.withValues(alpha: 0.35),
      glowColor: glowThemeColor,
      glowRadius: 22,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: ShapeDecoration(
                  color: glowThemeColor.withValues(alpha: 0.15),
                  shape: const SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                    ),
                  ),
                ),
                child: HugeIcon(
                  icon: isDeficit ? HugeIcons.strokeRoundedBalanceScale : HugeIcons.strokeRoundedFire,
                  color: glowThemeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('energy_balance_title'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr('energy_balance_subtitle'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: ShapeDecoration(
                  color: glowThemeColor.withValues(alpha: 0.14),
                  shape: SmoothRectangleBorder(
                    borderRadius: const SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 12, cornerSmoothing: 0.6),
                    ),
                    side: BorderSide(
                      color: glowThemeColor.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  isDeficit
                      ? LocaleService.tr('status_deficit', args: {'amount': absNet.toString()})
                      : LocaleService.tr('status_surplus', args: {'amount': absNet.toString()}),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: glowThemeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // History Pill Button
              BouncingTap(
                onTap: () => CalorieBalanceHistorySheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: SmoothRectangleBorder(
                      borderRadius: const SmoothBorderRadius.all(
                        SmoothRadius(cornerRadius: 12, cornerSmoothing: 0.6),
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedHistory, size: 12, color: Color(0xFF00F0FF)),
                      const SizedBox(width: 3),
                      Text(
                        LocaleService.tr('history_btn'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Two Interactive Split Blocks: IN vs OUT with BouncingTap
          Row(
            children: [
              // In block (Clickable -> Opens CaloriesInHistorySheet)
              Expanded(
                child: BouncingTap(
                  onTap: () => CaloriesInHistorySheet.show(
                    context,
                    date: widget.selectedDate,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.05),
                      shape: SmoothRectangleBorder(
                        borderRadius: const SmoothBorderRadius.all(
                          SmoothRadius(cornerRadius: 18, cornerSmoothing: 0.6),
                        ),
                        side: BorderSide(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const HugeIcon(icon: HugeIcons.strokeRoundedRestaurant, size: 14, color: Color(0xFF00F0FF)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                LocaleService.tr('calories_in'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              size: 12,
                              color: Color(0xFF00F0FF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_caloriesIn',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocaleService.tr('from_ai_food'),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppTheme.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Out block (Clickable -> Opens CaloriesOutBreakdownSheet)
              Expanded(
                child: BouncingTap(
                  onTap: () => CaloriesOutBreakdownSheet.show(
                    context,
                    currentSteps: widget.currentSteps,
                    date: widget.selectedDate,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      shape: SmoothRectangleBorder(
                        borderRadius: const SmoothBorderRadius.all(
                          SmoothRadius(cornerRadius: 18, cornerSmoothing: 0.6),
                        ),
                        side: BorderSide(
                          color: Colors.orange.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const HugeIcon(icon: HugeIcons.strokeRoundedFire, size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                LocaleService.tr('calories_out'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              size: 12,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_caloriesOut',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocaleService.tr('from_bmr_steps'),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppTheme.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dual Visual Progress Ratio Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (_caloriesIn > 0 ? _caloriesIn : 1),
                    child: Container(color: const Color(0xFF00F0FF)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (_caloriesOut > 0 ? _caloriesOut : 1),
                    child: Container(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Advice / Interpretation note
          Text(
            isDeficit
                ? LocaleService.tr('tip_deficit', args: {'amount': absNet.toString()})
                : LocaleService.tr('tip_surplus', args: {'amount': absNet.toString()}),
            style: const TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
