import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';
import 'exercise_guide_sheet.dart';

class MuscleGroupInfo {
  final String id;
  final String nameVi;
  final String nameEn;
  final String category; // 'chest', 'back', 'legs', 'arms', 'shoulders', 'core'
  final bool isFront;
  final Offset relativePos; // (x, y) from 0.0 to 1.0 on body silhouette
  final List<String> primaryExercises;
  final String description;

  const MuscleGroupInfo({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.category,
    required this.isFront,
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
  String? _selectedMuscleId;

  static const List<MuscleGroupInfo> allMuscles = [
    // --- MẶT TRƯỚC (ANTERIOR) ---
    MuscleGroupInfo(
      id: 'chest',
      nameVi: 'Cơ Ngực',
      nameEn: 'Pectoralis Major',
      category: 'chest',
      isFront: true,
      relativePos: Offset(0.50, 0.28),
      primaryExercises: ['Bench Press', 'Incline Dumbbell Press', 'Push-ups', 'Cable Fly'],
      description: 'Nhóm cơ đẩy chính của thân trên, tạo độ dày và nét cắt cho khuôn ngực.',
    ),
    MuscleGroupInfo(
      id: 'shoulders',
      nameVi: 'Cơ Vai',
      nameEn: 'Deltoids',
      category: 'shoulders',
      isFront: true,
      relativePos: Offset(0.32, 0.24),
      primaryExercises: ['Overhead Shoulder Press', 'Lateral Raises', 'Face Pulls'],
      description: 'Tạo hình thể chữ V (V-taper) vạm vỡ, nâng cao độ ổn định cho khớp vai.',
    ),
    MuscleGroupInfo(
      id: 'biceps',
      nameVi: 'Tay Trước',
      nameEn: 'Biceps Brachii',
      category: 'arms',
      isFront: true,
      relativePos: Offset(0.27, 0.36),
      primaryExercises: ['Barbell Bicep Curl', 'Hammer Curl', 'Preacher Curl'],
      description: 'Chịu trách nhiệm gập khuỷu tay và xoay cẳng tay.',
    ),
    MuscleGroupInfo(
      id: 'abs',
      nameVi: 'Cơ Bụng & Lõi',
      nameEn: 'Rectus Abdominis / Core',
      category: 'core',
      isFront: true,
      relativePos: Offset(0.50, 0.42),
      primaryExercises: ['Plank', 'Hanging Leg Raise', 'Ab Rollout', 'Cable Crunch'],
      description: 'Trục ổn định toàn bộ cơ thể, bảo vệ cột sống thắt lưng khi nâng tạ nặng.',
    ),
    MuscleGroupInfo(
      id: 'quads',
      nameVi: 'Đùi Trước',
      nameEn: 'Quadriceps Femoris',
      category: 'legs',
      isFront: true,
      relativePos: Offset(0.44, 0.62),
      primaryExercises: ['Barbell Squat', 'Leg Press', 'Bulgarian Split Squat', 'Leg Extension'],
      description: 'Nhóm cơ lớn và mạnh nhất chi dưới, duỗi khớp gối khi đứng dậy và nhảy.',
    ),
    MuscleGroupInfo(
      id: 'calves_front',
      nameVi: 'Bắp Chân',
      nameEn: 'Calves (Tibialis & Gastrocnemius)',
      category: 'legs',
      isFront: true,
      relativePos: Offset(0.43, 0.82),
      primaryExercises: ['Standing Calf Raise', 'Seated Calf Raise'],
      description: 'Hỗ trợ lực đẩy khi chạy nhảy và độ ổn định của khớp cổ chân.',
    ),

    // --- MẶT SAU (POSTERIOR) ---
    MuscleGroupInfo(
      id: 'traps',
      nameVi: 'Cầu Vai & Lưng Trên',
      nameEn: 'Trapezius & Upper Back',
      category: 'back',
      isFront: false,
      relativePos: Offset(0.50, 0.22),
      primaryExercises: ['Barbell Shrug', 'Face Pull', 'Rear Delt Fly'],
      description: 'Cố định và xoay bả vai, tạo vẻ uy lực cho vùng cổ lưng.',
    ),
    MuscleGroupInfo(
      id: 'lats',
      nameVi: 'Lưng Xô',
      nameEn: 'Latissimus Dorsi',
      category: 'back',
      isFront: false,
      relativePos: Offset(0.40, 0.32),
      primaryExercises: ['Pull-ups / Chin-ups', 'Lat Pulldown', 'Barbell Row', 'T-Bar Row'],
      description: 'Mở rộng chiều rộng lưng xô chữ V, kéo cánh tay về phía thân.',
    ),
    MuscleGroupInfo(
      id: 'triceps',
      nameVi: 'Tay Sau',
      nameEn: 'Triceps Brachii',
      category: 'arms',
      isFront: false,
      relativePos: Offset(0.25, 0.35),
      primaryExercises: ['Triceps Rope Pushdown', 'Skull Crusher', 'Dips'],
      description: 'Chiếm tới 60% kích thước bắp tay, duỗi khớp cùi chỏ.',
    ),
    MuscleGroupInfo(
      id: 'lower_back',
      nameVi: 'Lưng Dưới',
      nameEn: 'Erector Spinae',
      category: 'back',
      isFront: false,
      relativePos: Offset(0.50, 0.44),
      primaryExercises: ['Deadlift', 'Hyperextensions', 'Good Mornings'],
      description: 'Giữ thẳng cột sống, là cầu nối truyền lực giữa thân dưới và thân trên.',
    ),
    MuscleGroupInfo(
      id: 'glutes',
      nameVi: 'Cơ Mông',
      nameEn: 'Gluteus Maximus',
      category: 'legs',
      isFront: false,
      relativePos: Offset(0.48, 0.52),
      primaryExercises: ['Hip Thrust', 'Romanian Deadlift', 'Deep Squat'],
      description: 'Tạo sức mạnh bùng nổ khi chạy nước rút và duỗi khớp hông.',
    ),
    MuscleGroupInfo(
      id: 'hamstrings',
      nameVi: 'Đùi Sau',
      nameEn: 'Hamstrings',
      category: 'legs',
      isFront: false,
      relativePos: Offset(0.45, 0.65),
      primaryExercises: ['Romanian Deadlift', 'Lying Leg Curl', 'Nordic Curl'],
      description: 'Gập gối và duỗi hông, cân bằng lực kéo với đùi trước tránh chấn thương gối.',
    ),
    MuscleGroupInfo(
      id: 'calves_back',
      nameVi: 'Bắp Chân Sau',
      nameEn: 'Gastrocnemius & Soleus',
      category: 'legs',
      isFront: false,
      relativePos: Offset(0.44, 0.82),
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

  MuscleGroupInfo? get _selectedMuscle {
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131724),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Front / Back Toggle
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

          // Interactive Anatomy Map Visualizer
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stylized Silhouette Canvas
                CustomPaint(
                  size: const Size(200, 240),
                  painter: _AnatomySilhouettePainter(
                    isFront: _isFrontView,
                    selectedMuscleId: _selectedMuscleId,
                  ),
                ),

                // Interactive Muscle Tap Targets
                ..._currentMuscles.map((muscle) {
                  final isSelected = muscle.id == _selectedMuscleId;
                  final top = muscle.relativePos.dy * 240 - 16;
                  final left = (100 + (muscle.relativePos.dx - 0.5) * 160) - 16;

                  return Positioned(
                    top: top.clamp(0.0, 208.0),
                    left: left.clamp(10.0, 160.0),
                    child: GestureDetector(
                      onTap: () => _selectMuscle(muscle.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00F0FF)
                              : const Color(0xFF1E2638).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white : const Color(0xFF00F0FF).withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.black : const Color(0xFF00F0FF),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              muscle.nameVi,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Selected Muscle Details Card
          if (currentSelected != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSelected.nameVi,
                            style: AppTheme.font(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00F0FF),
                            ),
                          ),
                          Text(
                            currentSelected.nameEn,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.white54,
                            ),
                          ),
                        ],
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
                            children: [
                              Icon(Icons.menu_book, color: Color(0xFF00F0FF), size: 14),
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
                  const SizedBox(height: 8),
                  Text(
                    currentSelected.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bài tập hàng đầu kích hoạt nhóm cơ:',
                    style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: currentSelected.primaryExercises.map((ex) {
                      return InkWell(
                        onTap: () {
                          ExerciseGuideSheet.show(
                            context,
                            exerciseTitle: ex,
                            targetMuscle: currentSelected.nameVi,
                            secondaryMuscles: 'Cơ bổ trợ & Khớp chuyển động',
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fitness_center, size: 12, color: Color(0xFFFF9E00)),
                              const SizedBox(width: 4),
                              Text(
                                ex,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
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

class _AnatomySilhouettePainter extends CustomPainter {
  final bool isFront;
  final String? selectedMuscleId;

  _AnatomySilhouettePainter({
    required this.isFront,
    this.selectedMuscleId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, 20), width: 32, height: 40),
      outlinePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, 20), width: 32, height: 40),
      glowPaint,
    );

    // Torso Path
    final torso = Path();
    torso.moveTo(centerX - 35, 45); // Left shoulder
    torso.lineTo(centerX + 35, 45); // Right shoulder
    torso.lineTo(centerX + 26, 115); // Waist right
    torso.lineTo(centerX + 30, 130); // Hips right
    torso.lineTo(centerX - 30, 130); // Hips left
    torso.lineTo(centerX - 26, 115); // Waist left
    torso.close();
    canvas.drawPath(torso, outlinePaint);
    canvas.drawPath(torso, glowPaint);

    // Left Arm
    final leftArm = Path();
    leftArm.moveTo(centerX - 35, 45);
    leftArm.lineTo(centerX - 55, 95);
    leftArm.lineTo(centerX - 60, 140);
    canvas.drawPath(leftArm, outlinePaint);

    // Right Arm
    final rightArm = Path();
    rightArm.moveTo(centerX + 35, 45);
    rightArm.lineTo(centerX + 55, 95);
    rightArm.lineTo(centerX + 60, 140);
    canvas.drawPath(rightArm, outlinePaint);

    // Left Leg
    final leftLeg = Path();
    leftLeg.moveTo(centerX - 18, 130);
    leftLeg.lineTo(centerX - 22, 185);
    leftLeg.lineTo(centerX - 20, 235);
    canvas.drawPath(leftLeg, outlinePaint);

    // Right Leg
    final rightLeg = Path();
    rightLeg.moveTo(centerX + 18, 130);
    rightLeg.lineTo(centerX + 22, 185);
    rightLeg.lineTo(centerX + 20, 235);
    canvas.drawPath(rightLeg, outlinePaint);

    // Muscle accentuating lines
    final accentPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.15)
      ..strokeWidth = 1;

    // Chest / Back line
    canvas.drawLine(Offset(centerX - 25, 75), Offset(centerX + 25, 75), accentPaint);
    // Center spine / sternum
    canvas.drawLine(Offset(centerX, 45), Offset(centerX, 125), accentPaint);
  }

  @override
  bool shouldRepaint(covariant _AnatomySilhouettePainter oldDelegate) {
    return oldDelegate.isFront != isFront || oldDelegate.selectedMuscleId != selectedMuscleId;
  }
}
