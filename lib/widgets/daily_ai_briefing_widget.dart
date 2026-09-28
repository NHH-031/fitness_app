import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:figma_squircle/figma_squircle.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_formatters.dart';
import 'app_ui_components.dart';

class DailyAiBriefingWidget extends StatefulWidget {
  final DateTime selectedDate;

  const DailyAiBriefingWidget({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DailyAiBriefingWidget> createState() => _DailyAiBriefingWidgetState();
}

class _DailyAiBriefingWidgetState extends State<DailyAiBriefingWidget>
    with SingleTickerProviderStateMixin {
  DailyAiBriefing? _briefing;
  bool _isLoading = false;
  bool _isExpanded = true;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadBriefing();
  }

  @override
  void didUpdateWidget(covariant DailyAiBriefingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month ||
        oldWidget.selectedDate.day != widget.selectedDate.day) {
      _loadBriefing();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadBriefing({bool forceRefresh = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    if (forceRefresh) {
      _rotationController.repeat();
    }

    try {
      final briefing = await StorageService.getOrGenerateDailyAiBriefing(
        forDate: widget.selectedDate,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _briefing = briefing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading daily AI briefing: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _rotationController.isAnimating) {
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: const Color(0xFF131A2A),
        shape: SmoothRectangleBorder(
          borderRadius: const SmoothBorderRadius.all(
            SmoothRadius(cornerRadius: 22, cornerSmoothing: 0.6),
          ),
          side: BorderSide(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        shadows: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF131A2A),
                const Color(0xFF16233B).withValues(alpha: 0.95),
                const Color(0xFF0D1524),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                child: Row(
                  children: [
                    // Glowing AI PT Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F0FF), Color(0xFF7000FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAiSparkles,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleService.tr('daily_briefing_title'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Color(0xFF00F0FF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  LocaleService.tr('daily_briefing_tag'),
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF00F0FF),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  LocaleService.tr('daily_briefing_yesterday_review'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Refresh Button
                    BouncingTap(
                      onTap: _isLoading ? null : () => _loadBriefing(forceRefresh: true),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: RotationTransition(
                          turns: _rotationController,
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedReload,
                            color: Color(0xFF00F0FF),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Expand/Collapse Toggle
                    BouncingTap(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: HugeIcon(
                          icon: _isExpanded
                              ? HugeIcons.strokeRoundedArrowUp01
                              : HugeIcons.strokeRoundedArrowDown01,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),

              // Briefing Body
              if (_isLoading && _briefing == null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          LocaleService.tr('daily_briefing_generating'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_briefing != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Motivational Headline
                      Text(
                        _briefing!.headline,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Coach Personalized Message (Coach Persona)
                      Text(
                        _briefing!.message,
                        style: TextStyle(
                          fontSize: 12.8,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (_isExpanded) ...[
                        const SizedBox(height: 14),

                        // Yesterday's 4 Quick Stat Pills (Steps, Calorie Deficit/Surplus, Water, Health Score)
                        _buildYesterdayStatChips(context, _briefing!, isVi),

                        if (_briefing!.actionableTip.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          // Actionable Tip Pill
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🎯', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocaleService.tr('daily_briefing_action_tip'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: Color(0xFF00F0FF),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _briefing!.actionableTip,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYesterdayStatChips(
      BuildContext context, DailyAiBriefing briefing, bool isVi) {
    final balance = briefing.calorieBalance;
    final isDeficit = balance < 0;
    final balanceColor = isDeficit
        ? const Color(0xFF00FF88)
        : (balance > 0 ? Colors.orangeAccent : Colors.white70);

    return Row(
      children: [
        // 1. Steps
        Expanded(
          child: _buildChip(
            emoji: '👟',
            label: isVi ? 'Bước' : 'Steps',
            value: AppFormatters.formatNumber(briefing.steps),
            color: const Color(0xFF00F0FF),
          ),
        ),
        const SizedBox(width: 6),

        // 2. Calorie Balance
        Expanded(
          child: _buildChip(
            emoji: '⚖️',
            label: isVi ? 'Cân bằng' : 'Balance',
            value: balance == 0 ? '0 kcal' : '${isDeficit ? '-' : '+'}${briefing.calorieBalance.abs()}',
            color: balanceColor,
          ),
        ),
        const SizedBox(width: 6),

        // 3. Water
        Expanded(
          child: _buildChip(
            emoji: '💧',
            label: isVi ? 'Nước' : 'Water',
            value: '${briefing.waterCups}/8',
            color: const Color(0xFF38B6FF),
          ),
        ),
        const SizedBox(width: 6),

        // 4. Health Score
        Expanded(
          child: _buildChip(
            emoji: '🛡️',
            label: isVi ? 'Điểm SK' : 'Score',
            value: '${briefing.healthScore}',
            color: briefing.healthScore >= 75
                ? const Color(0xFF00FF88)
                : (briefing.healthScore >= 50 ? Colors.amber : Colors.orangeAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 0.9,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
