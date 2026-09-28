import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../screens/main_screen.dart';
import 'app_ui_components.dart';

class CaloriesOutBreakdownSheet extends StatefulWidget {
  final int currentSteps;
  final DateTime? date;

  const CaloriesOutBreakdownSheet({
    super.key,
    this.currentSteps = 0,
    this.date,
  });

  static void show(
    BuildContext context, {
    int currentSteps = 0,
    DateTime? date,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => CaloriesOutBreakdownSheet(
        currentSteps: currentSteps,
        date: date,
      ),
    );
  }

  @override
  State<CaloriesOutBreakdownSheet> createState() =>
      _CaloriesOutBreakdownSheetState();
}

class _CaloriesOutBreakdownSheetState extends State<CaloriesOutBreakdownSheet> {
  UserProfile? _userProfile;
  List<Map<String, dynamic>> _todayWorkouts = [];
  int _bmrAccumulated = 0;
  int _stepsBurn = 0;
  int _workoutsBurn = 0;
  int _totalBurned = 0;
  double _fractionOfDay = 0.5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    StorageService.dataUpdateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    StorageService.dataUpdateNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final targetDate = widget.date ?? DateTime.now();
    final now = DateTime.now();
    final bool isToday = targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    final double fraction = isToday
        ? ((now.hour * 60 + now.minute) / 1440.0).clamp(0.05, 1.0)
        : 1.0;
    final profile = await StorageService.getUserProfile();
    final double bmr = profile.bmr;
    final int bmrAcc = (bmr * fraction).round();

    int effectiveSteps = widget.currentSteps;
    if (!isToday) {
      effectiveSteps = await StorageService.getStepsByDate(targetDate);
    }
    final int sBurn = (effectiveSteps * 0.04).round();
    final int wBurn = await StorageService.getWorkoutCaloriesByDate(targetDate);
    final workouts = await StorageService.getWorkoutLogsByDate(targetDate);

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _fractionOfDay = fraction;
        _bmrAccumulated = bmrAcc;
        _stepsBurn = sBurn;
        _workoutsBurn = wBurn;
        _totalBurned = bmrAcc + sBurn + wBurn;
        _todayWorkouts = workouts;
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? timestampStr) {
    if (timestampStr == null) return '--:--';
    final time = DateTime.tryParse(timestampStr);
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _confirmDeleteWorkout(Map<String, dynamic> workout) async {
    final title = workout['title']?.toString() ?? 'Bài tập';
    final timestamp = workout['timestamp']?.toString() ?? '';
    final calories = workout['calories']?.toString() ?? '0';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocaleService.isVietnamese ? 'Xóa bài tập?' : 'Delete workout?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          LocaleService.isVietnamese
              ? 'Bạn có chắc chắn muốn xóa bài tập "$title" ($calories kcal) khỏi lịch sử hôm nay?'
              : 'Are you sure you want to remove "$title" ($calories kcal) from today\'s workout log?',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              LocaleService.isVietnamese ? 'Hủy' : 'Cancel',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              LocaleService.isVietnamese ? 'Xóa' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && timestamp.isNotEmpty) {
      await StorageService.deleteWorkoutLog(timestamp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleService.isVietnamese
                ? 'Đã xóa bài tập "$title"'
                : 'Removed workout "$title"',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E1E2C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToWorkoutTab() {
    Navigator.of(context).pop();
    MainScreen.switchTab(1); // Tab 1 is WorkoutScreen
  }

  @override
  Widget build(BuildContext context) {
    final int percentOfDay = (_fractionOfDay * 100).round();
    final double fullBmr = _userProfile?.bmr ?? 1600;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF12121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            const BottomSheetDragHandle(),

            // Top Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
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
                          LocaleService.isVietnamese
                              ? 'CHI TIẾT TIÊU HAO CALO'
                              : 'CALORIE BURN BREAKDOWN',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocaleService.isVietnamese
                              ? 'Phân rã khoa học: BMR + Bước chân + Bài tập'
                              : 'Real-time calculation: BMR + Steps + Workouts',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Total Burned Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.18),
                      Colors.deepOrange.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleService.isVietnamese
                              ? 'TỔNG NĂNG LƯỢNG ĐÃ TIÊU HAO'
                              : 'TOTAL ENERGY BURNED TODAY',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white60,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_totalBurned',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'kcal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Start workout quick button
                    InkWell(
                      onTap: _navigateToWorkoutTab,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fitness_center_rounded,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              LocaleService.isVietnamese ? 'Tập luyện' : 'Workout',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        // Pillar 1: BMR
                        _buildExpenditureCard(
                          icon: Icons.monitor_heart_rounded,
                          iconColor: const Color(0xFFFF4081),
                          badgeText: 'BMR • $percentOfDay% NGÀY',
                          title: LocaleService.isVietnamese
                              ? 'Trao đổi chất cơ bản (BMR)'
                              : 'Basal Metabolic Rate (BMR)',
                          calories: _bmrAccumulated,
                          description: LocaleService.isVietnamese
                              ? 'Năng lượng tế bào duy trì sự sống (tim, phổi, não bộ, thân nhiệt) từ 00:00 đến nay. Tổng 24h là ${fullBmr.round()} kcal.'
                              : 'Cellular energy maintaining life functions prorated to current time of day. 24h baseline is ${fullBmr.round()} kcal.',
                          footerText: LocaleService.isVietnamese
                              ? 'Công thức Mifflin-St Jeor: ${_userProfile?.gender == 'female' ? 'Nữ' : 'Nam'}, ${_userProfile?.weight}kg, ${_userProfile?.height}cm'
                              : 'Mifflin-St Jeor formula based on personal biometrics',
                        ),

                        const SizedBox(height: 12),

                        // Pillar 2: Steps
                        _buildExpenditureCard(
                          icon: Icons.directions_walk_rounded,
                          iconColor: const Color(0xFF00F0FF),
                          badgeText: 'NEAT • BƯỚC CHÂN',
                          title: LocaleService.isVietnamese
                              ? 'Vận động bước chân'
                              : 'Walking & Daily Steps',
                          calories: _stepsBurn,
                          description: LocaleService.isVietnamese
                              ? 'Đã đi ${widget.currentSteps} bước hôm nay. Tiêu chuẩn y học thể thao tính 0.04 kcal mỗi bước di chuyển.'
                              : 'Completed ${widget.currentSteps} steps today calculated at 0.04 kcal per step.',
                          footerText: widget.currentSteps > 0
                              ? '${widget.currentSteps} bước × 0.04 = $_stepsBurn kcal'
                              : (LocaleService.isVietnamese
                                  ? 'Cầm điện thoại di chuyển để cảm biến đếm bước tự động'
                                  : 'Walk with your phone to automatically track steps'),
                        ),

                        const SizedBox(height: 12),

                        // Pillar 3: Workouts History
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A26),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center_rounded,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        LocaleService.isVietnamese
                                            ? 'Bài tập đã hoàn thành'
                                            : 'Completed Workouts',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+$_workoutsBurn kcal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              if (_todayWorkouts.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        LocaleService.isVietnamese
                                            ? 'Chưa có buổi tập nào hôm nay'
                                            : 'No workout session completed yet today',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        LocaleService.isVietnamese
                                            ? 'Tập 10-20 phút với AI Coach để kích hoạt quá trình đốt mỡ mạnh mẽ!'
                                            : 'Complete a quick routine with AI Coach to boost your fat burn!',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: _navigateToWorkoutTab,
                                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                        label: Text(
                                          LocaleService.isVietnamese
                                              ? 'Bắt đầu bài tập ngay'
                                              : 'Start Workout',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _todayWorkouts.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final w = _todayWorkouts[idx];
                                    final title = w['title']?.toString() ?? 'Bài tập';
                                    final dur = w['duration']?.toString() ?? '10';
                                    final cal = w['calories']?.toString() ?? '70';
                                    final timeStr = _formatTime(w['timestamp']?.toString());

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.05),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.sports_gymnastics_rounded,
                                              color: Colors.orange,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '$timeStr • $dur ${LocaleService.isVietnamese ? 'phút' : 'mins'}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '+$cal kcal',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _confirmDeleteWorkout(w),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.white38,
                                              size: 18,
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.only(left: 4),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
            ),

            // Bottom Full Switch Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _navigateToWorkoutTab,
                  icon: const Icon(Icons.fitness_center_rounded, size: 18),
                  label: Text(
                    LocaleService.isVietnamese
                        ? 'ĐẾN TRANG HOẠT ĐỘNG & BÀI TẬP'
                        : 'GO TO WORKOUTS & ACTIVITY',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenditureCard({
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required String title,
    required int calories,
    required String description,
    required String footerText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$calories kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              footerText,
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
