import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';
import 'exercise_guide_sheet.dart';

enum MuscleSide { left, right }

class MuscleGroupInfo {
  final String id;
  final String nameVi;
  final String nameEn;
  final String category; // 'chest', 'back', 'legs', 'arms', 'shoulders', 'core'
  final bool isFront;
  final MuscleSide side; // left or right callout column
  final Offset relativePos; // (x, y) normalized anchor on 140x280 body canvas
  final List<String> primaryExercises;
  final String description;

  const MuscleGroupInfo({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.category,
    required this.isFront,
    required this.side,
    required this.relativePos,
    required this.primaryExercises,
    required this.description,
  });
}

class MuscleAnatomyMapWidget extends StatefulWidget {
  final Function(String muscleId)? onMuscleSelected;
  final String? initialSelectedMuscle;

  const MuscleAnatomyMapWidget({
    super.key,
    this.onMuscleSelected,
    this.initialSelectedMuscle,
  });

  @override
  State<MuscleAnatomyMapWidget> createState() => _MuscleAnatomyMapWidgetState();
}

class _MuscleAnatomyMapWidgetState extends State<MuscleAnatomyMapWidget> {
  bool _isFrontView = true;
  late String _selectedMuscleId;

  static const List<MuscleGroupInfo> allMuscles = [
    // --- MẶT TRƯỚC (ANTERIOR) ---
    MuscleGroupInfo(
      id: 'shoulders',
      nameVi: 'Cơ Vai',
      nameEn: 'Deltoids',
      category: 'shoulders',
      isFront: true,
      side: MuscleSide.left,
      relativePos: Offset(0.28, 0.23),
      primaryExercises: ['Overhead Shoulder Press', 'Lateral Raises', 'Face Pulls'],
      description: 'Tạo hình thể chữ V (V-taper) vạm vỡ, nâng cao độ ổn định cho khớp vai.',
    ),
    MuscleGroupInfo(
      id: 'biceps',
      nameVi: 'Tay Trước',
      nameEn: 'Biceps Brachii',
      category: 'arms',
      isFront: true,
      side: MuscleSide.left,
      relativePos: Offset(0.22, 0.38),
      primaryExercises: ['Barbell Bicep Curl', 'Hammer Curl', 'Preacher Curl'],
      description: 'Chịu trách nhiệm gập khuỷu tay và xoay cẳng tay, tạo độ phồng cho bắp tay.',
    ),
    MuscleGroupInfo(
      id: 'calves_front',
      nameVi: 'Bắp Chân',
      nameEn: 'Calves & Tibialis',
      category: 'legs',
      isFront: true,
      side: MuscleSide.left,
      relativePos: Offset(0.36, 0.84),
      primaryExercises: ['Standing Calf Raise', 'Seated Calf Raise'],
      description: 'Hỗ trợ lực đẩy khi chạy nhảy và độ ổn định của khớp cổ chân.',
    ),
    MuscleGroupInfo(
      id: 'chest',
      nameVi: 'Cơ Ngực',
      nameEn: 'Pectoralis Major',
      category: 'chest',
      isFront: true,
      side: MuscleSide.right,
      relativePos: Offset(0.60, 0.25),
      primaryExercises: ['Bench Press', 'Incline Dumbbell Press', 'Push-ups', 'Cable Fly'],
      description: 'Nhóm cơ đẩy chính của thân trên, tạo độ dày và nét cắt cho khuôn ngực.',
    ),
    MuscleGroupInfo(
      id: 'abs',
      nameVi: 'Cơ Bụng',
      nameEn: 'Rectus Abdominis / Core',
      category: 'core',
      isFront: true,
      side: MuscleSide.right,
      relativePos: Offset(0.52, 0.40),
      primaryExercises: ['Plank', 'Hanging Leg Raise', 'Ab Rollout', 'Cable Crunch'],
      description: 'Trục ổn định toàn bộ cơ thể, bảo vệ cột sống thắt lưng khi nâng tạ nặng.',
    ),
    MuscleGroupInfo(
      id: 'quads',
      nameVi: 'Đùi Trước',
      nameEn: 'Quadriceps Femoris',
      category: 'legs',
      isFront: true,
      side: MuscleSide.right,
      relativePos: Offset(0.62, 0.64),
      primaryExercises: ['Barbell Squat', 'Leg Press', 'Bulgarian Split Squat', 'Leg Extension'],
      description: 'Nhóm cơ lớn và mạnh nhất chi dưới, duỗi khớp gối khi đứng dậy và nhảy.',
    ),

    // --- MẶT SAU (POSTERIOR) ---
    MuscleGroupInfo(
      id: 'traps',
      nameVi: 'Cầu Vai',
      nameEn: 'Trapezius & Upper Back',
      category: 'back',
      isFront: false,
      side: MuscleSide.left,
      relativePos: Offset(0.35, 0.20),
      primaryExercises: ['Barbell Shrug', 'Face Pull', 'Rear Delt Fly'],
      description: 'Cố định và xoay bả vai, tạo vẻ uy lực cho vùng cổ lưng.',
    ),
    MuscleGroupInfo(
      id: 'triceps',
      nameVi: 'Tay Sau',
      nameEn: 'Triceps Brachii',
      category: 'arms',
      isFront: false,
      side: MuscleSide.left,
      relativePos: Offset(0.22, 0.35),
      primaryExercises: ['Triceps Rope Pushdown', 'Skull Crusher', 'Dips'],
      description: 'Chiếm tới 60% kích thước bắp tay, duỗi khớp cùi chỏ.',
    ),
    MuscleGroupInfo(
      id: 'hamstrings',
      nameVi: 'Đùi Sau',
      nameEn: 'Hamstrings',
      category: 'legs',
      isFront: false,
      side: MuscleSide.left,
      relativePos: Offset(0.38, 0.68),
      primaryExercises: ['Romanian Deadlift', 'Lying Leg Curl', 'Nordic Curl'],
      description: 'Gập gối và duỗi hông, cân bằng lực kéo với đùi trước tránh chấn thương gối.',
    ),
    MuscleGroupInfo(
      id: 'lats',
      nameVi: 'Lưng Xô',
      nameEn: 'Latissimus Dorsi',
      category: 'back',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.68, 0.36),
      primaryExercises: ['Pull-ups / Chin-ups', 'Lat Pulldown', 'Barbell Row', 'T-Bar Row'],
      description: 'Mở rộng chiều rộng lưng xô chữ V, kéo cánh tay về phía thân.',
    ),
    MuscleGroupInfo(
      id: 'lower_back',
      nameVi: 'Lưng Dưới',
      nameEn: 'Erector Spinae',
      category: 'back',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.54, 0.46),
      primaryExercises: ['Deadlift', 'Hyperextensions', 'Good Mornings'],
      description: 'Giữ thẳng cột sống, là cầu nối truyền lực giữa thân dưới và thân trên.',
    ),
    MuscleGroupInfo(
      id: 'glutes',
      nameVi: 'Cơ Mông',
      nameEn: 'Gluteus Maximus',
      category: 'legs',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.62, 0.56),
      primaryExercises: ['Hip Thrust', 'Romanian Deadlift', 'Deep Squat'],
      description: 'Tạo sức mạnh bùng nổ khi chạy nước rút và duỗi khớp hông.',
    ),
    MuscleGroupInfo(
      id: 'calves_back',
      nameVi: 'Bắp Chân',
      nameEn: 'Gastrocnemius & Soleus',
      category: 'legs',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.64, 0.84),
      primaryExercises: ['Standing Calf Raise', 'Donkey Calf Raise'],
      description: 'Nhóm cơ gập lòng bàn chân, chịu toàn bộ tải trọng cơ thể khi vận động.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMuscleId = widget.initialSelectedMuscle ?? 'chest';
  }

  List<MuscleGroupInfo> get _currentMuscles =>
      allMuscles.where((m) => m.isFront == _isFrontView).toList();

  List<MuscleGroupInfo> get _leftMuscles =>
      _currentMuscles.where((m) => m.side == MuscleSide.left).toList();

  List<MuscleGroupInfo> get _rightMuscles =>
      _currentMuscles.where((m) => m.side == MuscleSide.right).toList();

  MuscleGroupInfo get _selectedMuscle {
    return allMuscles.firstWhere(
      (m) => m.id == _selectedMuscleId,
      orElse: () => _currentMuscles.first,
    );
  }

  void _selectMuscle(String id) {
    AppHaptics.selection();
    setState(() {
      _selectedMuscleId = id;
    });
    widget.onMuscleSelected?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final currentSelected = _selectedMuscle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131724),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with View Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedBodyPartMuscle,
                        color: Color(0xFF00F0FF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bản Đồ Giải Phẫu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Front / Back View Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildToggleButton('Mặt trước', _isFrontView, () {
                      AppHaptics.light();
                      setState(() {
                        _isFrontView = true;
                        _selectedMuscleId = 'chest';
                      });
                      widget.onMuscleSelected?.call('chest');
                    }),
                    _buildToggleButton('Mặt sau', !_isFrontView, () {
                      AppHaptics.light();
                      setState(() {
                        _isFrontView = false;
                        _selectedMuscleId = 'lats';
                      });
                      widget.onMuscleSelected?.call('lats');
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Anatomy Layout (Side Callouts + Sculpted Central Holographic Body)
          LayoutBuilder(
            builder: (context, constraints) {
              const double containerHeight = 290;
              const double bodyCanvasWidth = 126;
              final double sideWidth = ((constraints.maxWidth - bodyCanvasWidth) / 2).clamp(95.0, 140.0);
              final double bodyLeft = (constraints.maxWidth - bodyCanvasWidth) / 2;

              return SizedBox(
                height: containerHeight,
                width: constraints.maxWidth,
                child: Stack(
                  children: [
                    // Background leader lines connecting callouts to body hotspots
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AnatomyLeaderLinesPainter(
                          isFront: _isFrontView,
                          selectedMuscleId: _selectedMuscleId,
                          muscles: _currentMuscles,
                          bodyLeft: bodyLeft,
                          bodyWidth: bodyCanvasWidth,
                          sideWidth: sideWidth,
                          containerHeight: containerHeight,
                        ),
                      ),
                    ),

                    // Central Sculpted Athletic Body Canvas (Interactive)
                    Positioned(
                      left: bodyLeft,
                      top: 0,
                      width: bodyCanvasWidth,
                      height: containerHeight,
                      child: GestureDetector(
                        onTapDown: (details) {
                          _handleBodyCanvasTap(details.localPosition, bodyCanvasWidth, containerHeight);
                        },
                        child: CustomPaint(
                          size: const Size(bodyCanvasWidth, containerHeight),
                          painter: _AnatomySilhouettePainter(
                            isFront: _isFrontView,
                            selectedMuscleId: _selectedMuscleId,
                          ),
                        ),
                      ),
                    ),

                    // Left Column Callout Chips (No Overlap)
                    ...List.generate(_leftMuscles.length, (index) {
                      final muscle = _leftMuscles[index];
                      final isSelected = muscle.id == _selectedMuscleId;
                      final double topPos = _getLeftCalloutTop(index, _leftMuscles.length, containerHeight);

                      return Positioned(
                        left: 0,
                        top: topPos,
                        width: sideWidth - 6,
                        child: _buildSideCallout(
                          muscle: muscle,
                          isSelected: isSelected,
                          isLeft: true,
                        ),
                      );
                    }),

                    // Right Column Callout Chips (No Overlap)
                    ...List.generate(_rightMuscles.length, (index) {
                      final muscle = _rightMuscles[index];
                      final isSelected = muscle.id == _selectedMuscleId;
                      final double topPos = _getRightCalloutTop(index, _rightMuscles.length, containerHeight);

                      return Positioned(
                        right: 0,
                        top: topPos,
                        width: sideWidth - 6,
                        child: _buildSideCallout(
                          muscle: muscle,
                          isSelected: isSelected,
                          isLeft: false,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Horizontal Quick Muscle Chips Selector
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _currentMuscles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final m = _currentMuscles[index];
                final isSelected = m.id == _selectedMuscleId;
                return GestureDetector(
                  onTap: () => _selectMuscle(m.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00F0FF) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        m.nameVi,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Selected Muscle Detailed Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF161F30), Color(0xFF121622)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSelected.nameVi,
                            style: AppTheme.font(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00F0FF),
                            ),
                          ),
                          Text(
                            currentSelected.nameEn,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ExerciseGuideSheet.show(
                          context,
                          exerciseTitle: currentSelected.primaryExercises.first,
                          targetMuscle: currentSelected.nameVi,
                          secondaryMuscles: currentSelected.category == 'chest'
                              ? 'Tay sau (Triceps), Vai trước (Anterior Deltoid)'
                              : 'Cơ lõi, Cơ lưng, Cẳng tay',
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, color: Color(0xFF00F0FF), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Hướng dẫn chuẩn',
                              style: TextStyle(
                                color: Color(0xFF00F0FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  currentSelected.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Bài tập hàng đầu kích hoạt nhóm cơ:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentSelected.primaryExercises.map((exercise) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fitness_center_rounded, color: Color(0xFFFFB800), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            exercise,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getLeftCalloutTop(int index, int total, double height) {
    if (total <= 3) {
      const positions = [22.0, 108.0, 198.0];
      return positions[index % positions.length];
    }
    final gap = (height - 50) / (total - 1);
    return 15.0 + index * gap;
  }

  double _getRightCalloutTop(int index, int total, double height) {
    if (total == 3) {
      const positions = [32.0, 118.0, 195.0];
      return positions[index % positions.length];
    } else if (total == 4) {
      const positions = [18.0, 84.0, 150.0, 218.0];
      return positions[index % positions.length];
    }
    final gap = (height - 50) / (total - 1);
    return 15.0 + index * gap;
  }

  void _handleBodyCanvasTap(Offset localPos, double canvasWidth, double canvasHeight) {
    final normX = localPos.dx / canvasWidth;
    final normY = localPos.dy / canvasHeight;

    MuscleGroupInfo? closest;
    double minDistance = double.infinity;

    for (final m in _currentMuscles) {
      final dx = m.relativePos.dx - normX;
      final dy = m.relativePos.dy - normY;
      final dist = dx * dx + dy * dy;
      if (dist < minDistance) {
        minDistance = dist;
        closest = m;
      }
    }

    if (closest != null && minDistance < 0.08) {
      _selectMuscle(closest.id);
    }
  }

  Widget _buildSideCallout({
    required MuscleGroupInfo muscle,
    required bool isSelected,
    required bool isLeft,
  }) {
    return GestureDetector(
      onTap: () => _selectMuscle(muscle.id),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF)
              : const Color(0xFF161C2C).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF00F0FF).withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLeft) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.black : const Color(0xFF00F0FF),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    muscle.nameVi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (!isLeft) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.black : const Color(0xFF00F0FF),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 1),
            Text(
              muscle.nameEn.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white60,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Draws leader lines connecting side callout buttons with muscle focal points
class _AnatomyLeaderLinesPainter extends CustomPainter {
  final bool isFront;
  final String selectedMuscleId;
  final List<MuscleGroupInfo> muscles;
  final double bodyLeft;
  final double bodyWidth;
  final double sideWidth;
  final double containerHeight;

  _AnatomyLeaderLinesPainter({
    required this.isFront,
    required this.selectedMuscleId,
    required this.muscles,
    required this.bodyLeft,
    required this.bodyWidth,
    required this.sideWidth,
    required this.containerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftMuscles = muscles.where((m) => m.side == MuscleSide.left).toList();
    final rightMuscles = muscles.where((m) => m.side == MuscleSide.right).toList();

    // Draw left leader lines
    for (int i = 0; i < leftMuscles.length; i++) {
      final m = leftMuscles[i];
      final isSelected = m.id == selectedMuscleId;
      final topPos = _getLeftCalloutTop(i, leftMuscles.length, containerHeight);
      final startY = topPos + 18.0;
      final startX = sideWidth - 6;

      final targetX = bodyLeft + m.relativePos.dx * bodyWidth;
      final targetY = m.relativePos.dy * containerHeight;

      _drawLeaderLine(canvas, Offset(startX, startY), Offset(targetX, targetY), isSelected);
    }

    // Draw right leader lines
    for (int i = 0; i < rightMuscles.length; i++) {
      final m = rightMuscles[i];
      final isSelected = m.id == selectedMuscleId;
      final topPos = _getRightCalloutTop(i, rightMuscles.length, containerHeight);
      final startY = topPos + 18.0;
      final startX = size.width - sideWidth + 6;

      final targetX = bodyLeft + m.relativePos.dx * bodyWidth;
      final targetY = m.relativePos.dy * containerHeight;

      _drawLeaderLine(canvas, Offset(startX, startY), Offset(targetX, targetY), isSelected);
    }
  }

  void _drawLeaderLine(Canvas canvas, Offset start, Offset target, bool isSelected) {
    final linePaint = Paint()
      ..color = isSelected ? const Color(0xFF00F0FF) : const Color(0xFF00F0FF).withValues(alpha: 0.18)
      ..strokeWidth = isSelected ? 1.6 : 0.9
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = isSelected ? const Color(0xFF00F0FF) : const Color(0xFF00F0FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final midX = start.dx + (target.dx - start.dx) * 0.45;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(midX, start.dy)
      ..lineTo(target.dx, target.dy);

    canvas.drawPath(path, linePaint);

    // Glowing indicator dot at the target hotspot on the muscle
    canvas.drawCircle(target, isSelected ? 3.5 : 2.0, dotPaint);

    if (isSelected) {
      final glowPaint = Paint()
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(target, 6.0, glowPaint);
    }
  }

  double _getLeftCalloutTop(int index, int total, double height) {
    if (total <= 3) {
      const positions = [22.0, 108.0, 198.0];
      return positions[index % positions.length];
    }
    final gap = (height - 50) / (total - 1);
    return 15.0 + index * gap;
  }

  double _getRightCalloutTop(int index, int total, double height) {
    if (total == 3) {
      const positions = [32.0, 118.0, 195.0];
      return positions[index % positions.length];
    } else if (total == 4) {
      const positions = [18.0, 84.0, 150.0, 218.0];
      return positions[index % positions.length];
    }
    final gap = (height - 50) / (total - 1);
    return 15.0 + index * gap;
  }

  @override
  bool shouldRepaint(covariant _AnatomyLeaderLinesPainter oldDelegate) {
    return oldDelegate.selectedMuscleId != selectedMuscleId ||
        oldDelegate.isFront != isFront ||
        oldDelegate.bodyLeft != bodyLeft;
  }
}

/// Sculpted athletic human anatomy painter with real muscle contours and futuristic neon glow
class _AnatomySilhouettePainter extends CustomPainter {
  final bool isFront;
  final String selectedMuscleId;

  _AnatomySilhouettePainter({
    required this.isFront,
    required this.selectedMuscleId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 140.0;
    final sy = size.height / 280.0;

    canvas.save();
    canvas.scale(sx, sy);

    const centerX = 70.0;

    // Paints
    final baseOutlinePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final baseFillPaint = Paint()
      ..color = const Color(0xFF081322).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final subtleFillPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Outer Glow / Highlight Paints for selected muscle
    final activeFillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00F0FF), Color(0xFF0077B6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, 140, 280))
      ..style = PaintingStyle.fill;

    final activeStrokePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 1. Draw Overall Anatomical Athletic Silhouette Background
    final bodySilhouette = Path();
    // Head & Neck
    bodySilhouette.addOval(Rect.fromCenter(center: const Offset(centerX, 24), width: 28, height: 34));
    bodySilhouette.moveTo(61, 38);
    bodySilhouette.lineTo(44, 52); // Left shoulder slope
    bodySilhouette.lineTo(30, 68); // Left deltoid bulge
    bodySilhouette.lineTo(26, 110); // Left elbow
    bodySilhouette.lineTo(22, 145); // Left wrist
    bodySilhouette.lineTo(30, 145);
    bodySilhouette.lineTo(36, 112); // Inner arm
    bodySilhouette.lineTo(48, 88); // Armpit
    bodySilhouette.lineTo(54, 126); // Waist V-taper
    bodySilhouette.lineTo(50, 144); // Hip
    bodySilhouette.lineTo(40, 185); // Outer quad bulge
    bodySilhouette.lineTo(48, 212); // Knee outer
    bodySilhouette.lineTo(44, 240); // Calf bulge outer
    bodySilhouette.lineTo(54, 274); // Ankle outer
    bodySilhouette.lineTo(62, 274); // Ankle inner
    bodySilhouette.lineTo(58, 240); // Calf inner
    bodySilhouette.lineTo(56, 212); // Knee inner
    bodySilhouette.lineTo(68, 155); // Groin
    bodySilhouette.lineTo(84, 212); // Right Knee inner
    bodySilhouette.lineTo(82, 240); // Right Calf inner
    bodySilhouette.lineTo(78, 274); // Right Ankle inner
    bodySilhouette.lineTo(86, 274); // Right Ankle outer
    bodySilhouette.lineTo(96, 240); // Right Calf outer
    bodySilhouette.lineTo(92, 212); // Right Knee outer
    bodySilhouette.lineTo(100, 185); // Right Outer quad
    bodySilhouette.lineTo(90, 144); // Right Hip
    bodySilhouette.lineTo(86, 126); // Right Waist
    bodySilhouette.lineTo(92, 88); // Right Armpit
    bodySilhouette.lineTo(104, 112); // Right Inner arm
    bodySilhouette.lineTo(110, 145);
    bodySilhouette.lineTo(118, 145); // Right wrist
    bodySilhouette.lineTo(114, 110); // Right elbow
    bodySilhouette.lineTo(110, 68); // Right deltoid
    bodySilhouette.lineTo(96, 52); // Right shoulder
    bodySilhouette.lineTo(79, 38); // Right Neck
    bodySilhouette.close();

    canvas.drawPath(bodySilhouette, baseFillPaint);
    canvas.drawPath(bodySilhouette, subtleFillPaint);
    canvas.drawPath(bodySilhouette, baseOutlinePaint);

    if (isFront) {
      _paintFrontMuscles(canvas, activeFillPaint, activeStrokePaint, baseOutlinePaint);
    } else {
      _paintBackMuscles(canvas, activeFillPaint, activeStrokePaint, baseOutlinePaint);
    }

    canvas.restore();
  }

  void _paintFrontMuscles(
    Canvas canvas,
    Paint activeFill,
    Paint activeStroke,
    Paint passiveStroke,
  ) {
    // A. Shoulders (Deltoids)
    final leftDeltoid = Path()
      ..moveTo(44, 52)
      ..quadraticBezierTo(28, 64, 34, 84)
      ..quadraticBezierTo(42, 80, 48, 66)
      ..close();

    final rightDeltoid = Path()
      ..moveTo(96, 52)
      ..quadraticBezierTo(112, 64, 106, 84)
      ..quadraticBezierTo(98, 80, 92, 66)
      ..close();

    final isShoulders = selectedMuscleId == 'shoulders';
    _renderMusclePair(canvas, leftDeltoid, rightDeltoid, isShoulders, activeFill, activeStroke, passiveStroke);

    // B. Chest (Pectoralis Major)
    final leftChest = Path()
      ..moveTo(68, 56)
      ..lineTo(48, 56)
      ..quadraticBezierTo(44, 72, 48, 82)
      ..quadraticBezierTo(60, 88, 68, 86)
      ..close();

    final rightChest = Path()
      ..moveTo(72, 56)
      ..lineTo(92, 56)
      ..quadraticBezierTo(96, 72, 92, 82)
      ..quadraticBezierTo(80, 88, 72, 86)
      ..close();

    final isChest = selectedMuscleId == 'chest';
    _renderMusclePair(canvas, leftChest, rightChest, isChest, activeFill, activeStroke, passiveStroke);

    // C. Biceps (Arms)
    final leftBicep = Path()
      ..moveTo(34, 82)
      ..quadraticBezierTo(26, 96, 30, 112)
      ..lineTo(38, 108)
      ..quadraticBezierTo(42, 92, 46, 84)
      ..close();

    final rightBicep = Path()
      ..moveTo(106, 82)
      ..quadraticBezierTo(114, 96, 110, 112)
      ..lineTo(102, 108)
      ..quadraticBezierTo(98, 92, 94, 84)
      ..close();

    final isBiceps = selectedMuscleId == 'biceps';
    _renderMusclePair(canvas, leftBicep, rightBicep, isBiceps, activeFill, activeStroke, passiveStroke);

    // D. Abs & Core
    final absPath = Path();
    // Upper, Mid, Lower Abs grid
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(58, 92, 10, 13), const Radius.circular(3)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 92, 10, 13), const Radius.circular(3)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(58, 108, 10, 13), const Radius.circular(3)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 108, 10, 13), const Radius.circular(3)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(60, 124, 9, 14), const Radius.circular(3)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(71, 124, 9, 14), const Radius.circular(3)));

    final isAbs = selectedMuscleId == 'abs';
    if (isAbs) {
      canvas.drawPath(absPath, activeFill);
      canvas.drawPath(absPath, activeStroke);
    } else {
      canvas.drawPath(absPath, passiveStroke);
    }

    // E. Quadriceps (Thighs)
    final leftQuad = Path()
      ..moveTo(52, 145)
      ..quadraticBezierTo(38, 172, 42, 196)
      ..quadraticBezierTo(50, 210, 54, 210)
      ..quadraticBezierTo(60, 185, 66, 156)
      ..close();

    final rightQuad = Path()
      ..moveTo(88, 145)
      ..quadraticBezierTo(102, 172, 98, 196)
      ..quadraticBezierTo(90, 210, 86, 210)
      ..quadraticBezierTo(80, 185, 74, 156)
      ..close();

    final isQuads = selectedMuscleId == 'quads';
    _renderMusclePair(canvas, leftQuad, rightQuad, isQuads, activeFill, activeStroke, passiveStroke);

    // F. Calves Front
    final leftCalf = Path()
      ..moveTo(53, 214)
      ..quadraticBezierTo(44, 236, 48, 256)
      ..lineTo(56, 272)
      ..quadraticBezierTo(59, 245, 57, 214)
      ..close();

    final rightCalf = Path()
      ..moveTo(87, 214)
      ..quadraticBezierTo(96, 236, 92, 256)
      ..lineTo(84, 272)
      ..quadraticBezierTo(81, 245, 83, 214)
      ..close();

    final isCalves = selectedMuscleId == 'calves_front';
    _renderMusclePair(canvas, leftCalf, rightCalf, isCalves, activeFill, activeStroke, passiveStroke);
  }

  void _paintBackMuscles(
    Canvas canvas,
    Paint activeFill,
    Paint activeStroke,
    Paint passiveStroke,
  ) {
    // A. Trapezius & Upper Back (Diamond Shape)
    final traps = Path()
      ..moveTo(70, 36)
      ..lineTo(48, 54)
      ..lineTo(60, 88)
      ..lineTo(70, 96)
      ..lineTo(80, 88)
      ..lineTo(92, 54)
      ..close();

    final isTraps = selectedMuscleId == 'traps';
    if (isTraps) {
      canvas.drawPath(traps, activeFill);
      canvas.drawPath(traps, activeStroke);
    } else {
      canvas.drawPath(traps, passiveStroke);
    }

    // B. Latissimus Dorsi (Lats Wings)
    final leftLat = Path()
      ..moveTo(48, 76)
      ..quadraticBezierTo(38, 96, 46, 122)
      ..quadraticBezierTo(58, 128, 68, 120)
      ..lineTo(68, 90)
      ..close();

    final rightLat = Path()
      ..moveTo(92, 76)
      ..quadraticBezierTo(102, 96, 94, 122)
      ..quadraticBezierTo(82, 128, 72, 120)
      ..lineTo(72, 90)
      ..close();

    final isLats = selectedMuscleId == 'lats';
    _renderMusclePair(canvas, leftLat, rightLat, isLats, activeFill, activeStroke, passiveStroke);

    // C. Triceps (Back Arm)
    final leftTricep = Path()
      ..moveTo(34, 68)
      ..quadraticBezierTo(26, 86, 28, 110)
      ..lineTo(36, 108)
      ..quadraticBezierTo(40, 88, 44, 76)
      ..close();

    final rightTricep = Path()
      ..moveTo(106, 68)
      ..quadraticBezierTo(114, 86, 112, 110)
      ..lineTo(104, 108)
      ..quadraticBezierTo(100, 88, 96, 76)
      ..close();

    final isTriceps = selectedMuscleId == 'triceps';
    _renderMusclePair(canvas, leftTricep, rightTricep, isTriceps, activeFill, activeStroke, passiveStroke);

    // D. Lower Back (Erector Spinae)
    final lowerBack = Path();
    lowerBack.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(58, 120, 10, 22), const Radius.circular(3)));
    lowerBack.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 120, 10, 22), const Radius.circular(3)));

    final isLowerBack = selectedMuscleId == 'lower_back';
    if (isLowerBack) {
      canvas.drawPath(lowerBack, activeFill);
      canvas.drawPath(lowerBack, activeStroke);
    } else {
      canvas.drawPath(lowerBack, passiveStroke);
    }

    // E. Glutes (Cơ Mông)
    final leftGlute = Path()
      ..moveTo(50, 144)
      ..quadraticBezierTo(40, 168, 52, 178)
      ..quadraticBezierTo(64, 180, 69, 172)
      ..lineTo(69, 144)
      ..close();

    final rightGlute = Path()
      ..moveTo(90, 144)
      ..quadraticBezierTo(100, 168, 88, 178)
      ..quadraticBezierTo(76, 180, 71, 172)
      ..lineTo(71, 144)
      ..close();

    final isGlutes = selectedMuscleId == 'glutes';
    _renderMusclePair(canvas, leftGlute, rightGlute, isGlutes, activeFill, activeStroke, passiveStroke);

    // F. Hamstrings (Đùi Sau)
    final leftHam = Path()
      ..moveTo(48, 180)
      ..quadraticBezierTo(42, 196, 48, 212)
      ..lineTo(56, 212)
      ..quadraticBezierTo(62, 196, 66, 180)
      ..close();

    final rightHam = Path()
      ..moveTo(92, 180)
      ..quadraticBezierTo(98, 196, 92, 212)
      ..lineTo(84, 212)
      ..quadraticBezierTo(78, 196, 74, 180)
      ..close();

    final isHamstrings = selectedMuscleId == 'hamstrings';
    _renderMusclePair(canvas, leftHam, rightHam, isHamstrings, activeFill, activeStroke, passiveStroke);

    // G. Calves Back (Bắp Chân Sau - Diamond Heads)
    final leftCalfBack = Path()
      ..moveTo(52, 214)
      ..quadraticBezierTo(42, 238, 48, 256)
      ..lineTo(56, 272)
      ..quadraticBezierTo(60, 245, 58, 214)
      ..close();

    final rightCalfBack = Path()
      ..moveTo(88, 214)
      ..quadraticBezierTo(98, 238, 92, 256)
      ..lineTo(84, 272)
      ..quadraticBezierTo(80, 245, 82, 214)
      ..close();

    final isCalvesBack = selectedMuscleId == 'calves_back';
    _renderMusclePair(canvas, leftCalfBack, rightCalfBack, isCalvesBack, activeFill, activeStroke, passiveStroke);
  }

  void _renderMusclePair(
    Canvas canvas,
    Path leftPath,
    Path rightPath,
    bool isSelected,
    Paint activeFill,
    Paint activeStroke,
    Paint passiveStroke,
  ) {
    if (isSelected) {
      canvas.drawPath(leftPath, activeFill);
      canvas.drawPath(rightPath, activeFill);
      canvas.drawPath(leftPath, activeStroke);
      canvas.drawPath(rightPath, activeStroke);
    } else {
      canvas.drawPath(leftPath, passiveStroke);
      canvas.drawPath(rightPath, passiveStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomySilhouettePainter oldDelegate) {
    return oldDelegate.isFront != isFront || oldDelegate.selectedMuscleId != selectedMuscleId;
  }
}
