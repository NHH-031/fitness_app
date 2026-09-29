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
  final bool? initialIsMale;
  final ValueChanged<bool>? onGenderChanged;

  const MuscleAnatomyMapWidget({
    super.key,
    this.onMuscleSelected,
    this.initialSelectedMuscle,
    this.initialIsMale,
    this.onGenderChanged,
  });

  @override
  State<MuscleAnatomyMapWidget> createState() => _MuscleAnatomyMapWidgetState();
}

class _MuscleAnatomyMapWidgetState extends State<MuscleAnatomyMapWidget> {
  bool _isFrontView = true;
  late bool _isMale;
  late String _selectedMuscleId;

  // ==========================================
  // 1. MALE MUSCLE GROUPS (GIẢI PHẪU NAM GIỚI)
  // ==========================================
  static const List<MuscleGroupInfo> allMaleMuscles = [
    // --- MẶT TRƯỚC (ANTERIOR) NAM ---
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

    // --- MẶT SAU (POSTERIOR) NAM ---
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

  // ==========================================
  // 2. FEMALE MUSCLE GROUPS (GIẢI PHẪU NỮ GIỚI)
  // ==========================================
  static const List<MuscleGroupInfo> allFemaleMuscles = [
    // --- MẶT TRƯỚC (ANTERIOR) NỮ ---
    MuscleGroupInfo(
      id: 'shoulders',
      nameVi: 'Cơ Vai',
      nameEn: 'Deltoids',
      category: 'shoulders',
      isFront: true,
      side: MuscleSide.left,
      relativePos: Offset(0.28, 0.23),
      primaryExercises: ['Dumbbell Lateral Raise', 'Dumbbell Shoulder Press', 'Face Pulls'],
      description: 'Tạo bờ vai thon gọn, thanh thoát và chuẩn phom khi diện áo sát nách hay váy đầm.',
    ),
    MuscleGroupInfo(
      id: 'biceps',
      nameVi: 'Tay Trước',
      nameEn: 'Biceps Brachii',
      category: 'arms',
      isFront: true,
      side: MuscleSide.left,
      relativePos: Offset(0.22, 0.38),
      primaryExercises: ['Dumbbell Curl', 'Hammer Curl', 'Resistance Band Curl'],
      description: 'Làm săn chắc bắp tay trước, loại bỏ mỡ thừa cánh tay giúp tay thon dài.',
    ),
    MuscleGroupInfo(
      id: 'calves_front',
      nameVi: 'Bắp Chân',
      nameEn: 'Calves & Tibialis',
      category: 'legs',
      isFront: true,
      side: MuscleSide.left,
      relativePos: Offset(0.36, 0.84),
      primaryExercises: ['Standing Calf Raise', 'Jump Rope', 'Ankle Mobility Drills'],
      description: 'Tăng độ dẻo dai cổ chân, định hình bắp chân thon nuột khi đi giày cao gót.',
    ),
    MuscleGroupInfo(
      id: 'chest',
      nameVi: 'Cơ Ngực',
      nameEn: 'Pectoralis Major',
      category: 'chest',
      isFront: true,
      side: MuscleSide.right,
      relativePos: Offset(0.60, 0.25),
      primaryExercises: ['Incline Dumbbell Press', 'Push-ups (Knee/Standard)', 'Dumbbell Fly'],
      description: 'Nâng đỡ thềm ngực tự nhiên, tạo sự săn chắc và cải thiện dáng ngực chống chảy xệ.',
    ),
    MuscleGroupInfo(
      id: 'abs',
      nameVi: 'Cơ Bụng',
      nameEn: 'Core & 11-Line Abs',
      category: 'core',
      isFront: true,
      side: MuscleSide.right,
      relativePos: Offset(0.52, 0.40),
      primaryExercises: ['Plank', 'Dead Bug', 'Hollow Body Hold', 'Bicycle Crunch'],
      description: 'Kiến tạo cơ bụng số 11 săn chắc, phẳng lỳ và siết chặt vòng eo đồng hồ cát.',
    ),
    MuscleGroupInfo(
      id: 'quads',
      nameVi: 'Đùi Trước',
      nameEn: 'Quadriceps Femoris',
      category: 'legs',
      isFront: true,
      side: MuscleSide.right,
      relativePos: Offset(0.62, 0.64),
      primaryExercises: ['Goblet Squat', 'Walking Lunges', 'Step-ups', 'Leg Press'],
      description: 'Đốt mỡ đùi hiệu quả, làm săn chắc cơ đùi trước thon gọn mà không lo bị thô.',
    ),

    // --- MẶT SAU (POSTERIOR) NỮ ---
    MuscleGroupInfo(
      id: 'traps',
      nameVi: 'Cầu Vai',
      nameEn: 'Trapezius & Upper Back',
      category: 'back',
      isFront: false,
      side: MuscleSide.left,
      relativePos: Offset(0.35, 0.20),
      primaryExercises: ['Face Pull', 'Band Pull-Apart', 'Dumbbell Shrug'],
      description: 'Mở rộng lồng ngực, khắc phục tật gù lưng và tạo đường nét xương quai xanh thanh tú.',
    ),
    MuscleGroupInfo(
      id: 'triceps',
      nameVi: 'Tay Sau',
      nameEn: 'Triceps Brachii',
      category: 'arms',
      isFront: false,
      side: MuscleSide.left,
      relativePos: Offset(0.22, 0.35),
      primaryExercises: ['Triceps Kickback', 'Overhead Dumbbell Extension', 'Bench Dips'],
      description: 'Đánh bay mỡ thừa bắp tay sau ("cánh dơi"), giúp cánh tay thon gọn săn chắc.',
    ),
    MuscleGroupInfo(
      id: 'hamstrings',
      nameVi: 'Đùi Sau',
      nameEn: 'Hamstrings',
      category: 'legs',
      isFront: false,
      side: MuscleSide.left,
      relativePos: Offset(0.38, 0.68),
      primaryExercises: ['Romanian Deadlift (RDL)', 'Lying Leg Curl', 'Glute-Ham Raise'],
      description: 'Nâng cao nếp gấp mông dưới, tạo sự tách biệt rõ ràng giữa đùi sau và vòng 3.',
    ),
    MuscleGroupInfo(
      id: 'lats',
      nameVi: 'Lưng Xô',
      nameEn: 'Latissimus Dorsi',
      category: 'back',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.68, 0.36),
      primaryExercises: ['Lat Pulldown', 'Seated Cable Row', 'One-Arm Dumbbell Row'],
      description: 'Tạo đường thắt lưng cánh bướm thon gọn, tôn eo nhỏ hơn và dáng chuẩn chữ S.',
    ),
    MuscleGroupInfo(
      id: 'lower_back',
      nameVi: 'Lưng Dưới',
      nameEn: 'Erector Spinae',
      category: 'back',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.54, 0.46),
      primaryExercises: ['Bird Dog', 'Hyperextensions', 'Glute Bridge Hold'],
      description: 'Bảo vệ cột sống, giảm đau thắt lưng khi ngồi nhiều và duy trì tư thế thẳng.',
    ),
    MuscleGroupInfo(
      id: 'glutes',
      nameVi: 'Cơ Mông',
      nameEn: 'Gluteus Maximus & Medius',
      category: 'legs',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.62, 0.56),
      primaryExercises: ['Barbell Hip Thrust', 'Bulgarian Split Squat', 'Cable Kickback', 'Sumo Squat'],
      description: 'Tâm điểm phái đẹp: xây dựng vòng 3 quả đào căng tròn, nâng mông cao và săn chắc.',
    ),
    MuscleGroupInfo(
      id: 'calves_back',
      nameVi: 'Bắp Chân',
      nameEn: 'Gastrocnemius & Soleus',
      category: 'legs',
      isFront: false,
      side: MuscleSide.right,
      relativePos: Offset(0.64, 0.84),
      primaryExercises: ['Standing Calf Raise', 'Jump Rope', 'Stretching'],
      description: 'Giúp đôi chân thon dài nuột nà, định hình bắp chân gọn gàng thể thao.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isMale = widget.initialIsMale ?? true;
    _selectedMuscleId = widget.initialSelectedMuscle ?? 'chest';
  }

  @override
  void didUpdateWidget(covariant MuscleAnatomyMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIsMale != null && widget.initialIsMale != oldWidget.initialIsMale) {
      setState(() {
        _isMale = widget.initialIsMale!;
      });
    }
  }

  Color get _themeColor => _isMale ? const Color(0xFF00F0FF) : const Color(0xFFFF2E93);
  Color get _themeColorSecondary => _isMale ? const Color(0xFF0077B6) : const Color(0xFFFF52A8);

  List<MuscleGroupInfo> get _allCurrentGenderMuscles =>
      _isMale ? allMaleMuscles : allFemaleMuscles;

  List<MuscleGroupInfo> get _currentMuscles =>
      _allCurrentGenderMuscles.where((m) => m.isFront == _isFrontView).toList();

  List<MuscleGroupInfo> get _leftMuscles =>
      _currentMuscles.where((m) => m.side == MuscleSide.left).toList();

  List<MuscleGroupInfo> get _rightMuscles =>
      _currentMuscles.where((m) => m.side == MuscleSide.right).toList();

  MuscleGroupInfo get _selectedMuscle {
    return _allCurrentGenderMuscles.firstWhere(
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

  void _toggleGender(bool isMale) {
    if (_isMale == isMale) return;
    AppHaptics.light();
    setState(() {
      _isMale = isMale;
    });
    widget.onGenderChanged?.call(isMale);
  }

  @override
  Widget build(BuildContext context) {
    final currentSelected = _selectedMuscle;
    final activeColor = _themeColor;

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
          // Row 1: Title + Gender Segmented Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedBodyPartMuscle,
                      color: activeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bản Đồ Giải Phẫu',
                    style: AppTheme.font(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Gender Segmented Switch (Nam ♂ / Nữ ♀)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildGenderButton(
                      'Nam ♂',
                      _isMale,
                      const Color(0xFF00F0FF),
                      () => _toggleGender(true),
                    ),
                    _buildGenderButton(
                      'Nữ ♀',
                      !_isMale,
                      const Color(0xFFFF2E93),
                      () => _toggleGender(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Model Subtitle Badge + View Segmented Switch (Mặt trước / Mặt sau)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: activeColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isMale ? Icons.fitness_center_rounded : Icons.flare_rounded,
                      size: 12,
                      color: activeColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isMale ? 'Mô hình Nam giới' : 'Mô hình Nữ giới',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
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
                        _selectedMuscleId = _isMale ? 'lats' : 'glutes';
                      });
                      widget.onMuscleSelected?.call(_isMale ? 'lats' : 'glutes');
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
                          isMale: _isMale,
                          themeColor: activeColor,
                          selectedMuscleId: _selectedMuscleId,
                          muscles: _currentMuscles,
                          bodyLeft: bodyLeft,
                          bodyWidth: bodyCanvasWidth,
                          sideWidth: sideWidth,
                          containerHeight: containerHeight,
                        ),
                      ),
                    ),

                    // Central Sculpted Body Canvas (Interactive)
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
                            isMale: _isMale,
                            themeColor: activeColor,
                            themeColorSecondary: _themeColorSecondary,
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
                          activeColor: activeColor,
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
                          activeColor: activeColor,
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
                      color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        m.nameVi,
                        style: TextStyle(
                          color: isSelected
                              ? (_isMale ? Colors.black : Colors.white)
                              : Colors.white70,
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
              color: const Color(0xFF161B2B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: activeColor.withValues(alpha: 0.35)),
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
                              color: activeColor,
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
                              : (currentSelected.category == 'legs'
                                  ? 'Cơ đùi, Cơ mông, Khớp gối & hông'
                                  : 'Cơ lõi, Cơ lưng, Cẳng tay'),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, color: activeColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Hướng dẫn chuẩn',
                              style: TextStyle(
                                color: activeColor,
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
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.north_east_rounded, size: 12, color: activeColor),
                          const SizedBox(width: 4),
                          Text(
                            exercise,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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

  Widget _buildGenderButton(
    String text,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? (activeColor == const Color(0xFF00F0FF) ? Colors.black : Colors.white)
                : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? _themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _themeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? (_isMale ? Colors.black : Colors.white)
                : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
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
    required Color activeColor,
  }) {
    final textColor = isSelected ? (_isMale ? Colors.black : Colors.white) : Colors.white;

    return GestureDetector(
      onTap: () => _selectMuscle(muscle.id),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : const Color(0xFF161C2C).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : activeColor.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.5),
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
                      color: isSelected ? (_isMale ? Colors.black : Colors.white) : activeColor,
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
                      color: textColor,
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
                      color: isSelected ? (_isMale ? Colors.black : Colors.white) : activeColor,
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
                color: isSelected
                    ? (_isMale ? Colors.black87 : Colors.white.withValues(alpha: 0.85))
                    : Colors.white38,
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws leader lines connecting side callout buttons with muscle focal points
class _AnatomyLeaderLinesPainter extends CustomPainter {
  final bool isFront;
  final bool isMale;
  final Color themeColor;
  final String selectedMuscleId;
  final List<MuscleGroupInfo> muscles;
  final double bodyLeft;
  final double bodyWidth;
  final double sideWidth;
  final double containerHeight;

  _AnatomyLeaderLinesPainter({
    required this.isFront,
    required this.isMale,
    required this.themeColor,
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
      ..color = isSelected ? themeColor : themeColor.withValues(alpha: 0.18)
      ..strokeWidth = isSelected ? 1.6 : 0.9
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = isSelected ? themeColor : themeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final midX = start.dx + (target.dx - start.dx) * 0.45;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(midX, start.dy)
      ..lineTo(target.dx, target.dy);

    canvas.drawPath(path, linePaint);

    // Indicator dot at the target hotspot on the muscle
    canvas.drawCircle(target, isSelected ? 3.5 : 2.0, dotPaint);

    if (isSelected) {
      final glowPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.35)
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
        oldDelegate.isMale != isMale ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.bodyLeft != bodyLeft;
  }
}

/// Sculpted athletic human anatomy painter with real muscle contours and futuristic neon glow
class _AnatomySilhouettePainter extends CustomPainter {
  final bool isFront;
  final bool isMale;
  final Color themeColor;
  final Color themeColorSecondary;
  final String selectedMuscleId;

  _AnatomySilhouettePainter({
    required this.isFront,
    required this.isMale,
    required this.themeColor,
    required this.themeColorSecondary,
    required this.selectedMuscleId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 140.0;
    final sy = size.height / 280.0;

    canvas.save();
    canvas.scale(sx, sy);

    // Paints
    final baseOutlinePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final baseFillPaint = Paint()
      ..color = const Color(0xFF081322).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final subtleFillPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Outer Glow / Highlight Paints for selected muscle
    final activeFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [themeColor, themeColorSecondary],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, 140, 280))
      ..style = PaintingStyle.fill;

    final activeStrokePaint = Paint()
      ..color = themeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (isMale) {
      _paintMaleBody(canvas, baseFillPaint, subtleFillPaint, baseOutlinePaint);
      if (isFront) {
        _paintMaleFrontMuscles(canvas, activeFillPaint, activeStrokePaint, baseOutlinePaint);
      } else {
        _paintMaleBackMuscles(canvas, activeFillPaint, activeStrokePaint, baseOutlinePaint);
      }
    } else {
      _paintFemaleBody(canvas, baseFillPaint, subtleFillPaint, baseOutlinePaint);
      if (isFront) {
        _paintFemaleFrontMuscles(canvas, activeFillPaint, activeStrokePaint, baseOutlinePaint);
      } else {
        _paintFemaleBackMuscles(canvas, activeFillPaint, activeStrokePaint, baseOutlinePaint);
      }
    }

    canvas.restore();
  }

  // ==========================================
  // MALE ANATOMY SILHOUETTE & MUSCLE RENDERING
  // ==========================================
  void _paintMaleBody(Canvas canvas, Paint baseFill, Paint subtleFill, Paint outline) {
    const centerX = 70.0;
    final bodySilhouette = Path();
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

    canvas.drawPath(bodySilhouette, baseFill);
    canvas.drawPath(bodySilhouette, subtleFill);
    canvas.drawPath(bodySilhouette, outline);
  }

  void _paintMaleFrontMuscles(
    Canvas canvas,
    Paint activeFill,
    Paint activeStroke,
    Paint passiveStroke,
  ) {
    // Shoulders
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
    _renderMusclePair(canvas, leftDeltoid, rightDeltoid, selectedMuscleId == 'shoulders', activeFill, activeStroke, passiveStroke);

    // Chest
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
    _renderMusclePair(canvas, leftChest, rightChest, selectedMuscleId == 'chest', activeFill, activeStroke, passiveStroke);

    // Biceps
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
    _renderMusclePair(canvas, leftBicep, rightBicep, selectedMuscleId == 'biceps', activeFill, activeStroke, passiveStroke);

    // Abs
    final absPath = Path();
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

    // Quads
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
    _renderMusclePair(canvas, leftQuad, rightQuad, selectedMuscleId == 'quads', activeFill, activeStroke, passiveStroke);

    // Calves Front
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
    _renderMusclePair(canvas, leftCalf, rightCalf, selectedMuscleId == 'calves_front', activeFill, activeStroke, passiveStroke);
  }

  void _paintMaleBackMuscles(
    Canvas canvas,
    Paint activeFill,
    Paint activeStroke,
    Paint passiveStroke,
  ) {
    // Traps
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

    // Lats
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
    _renderMusclePair(canvas, leftLat, rightLat, selectedMuscleId == 'lats', activeFill, activeStroke, passiveStroke);

    // Triceps
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
    _renderMusclePair(canvas, leftTricep, rightTricep, selectedMuscleId == 'triceps', activeFill, activeStroke, passiveStroke);

    // Lower Back
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

    // Glutes
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
    _renderMusclePair(canvas, leftGlute, rightGlute, selectedMuscleId == 'glutes', activeFill, activeStroke, passiveStroke);

    // Hamstrings
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
    _renderMusclePair(canvas, leftHam, rightHam, selectedMuscleId == 'hamstrings', activeFill, activeStroke, passiveStroke);

    // Calves Back
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
    _renderMusclePair(canvas, leftCalfBack, rightCalfBack, selectedMuscleId == 'calves_back', activeFill, activeStroke, passiveStroke);
  }

  // ============================================
  // FEMALE ANATOMY SILHOUETTE & MUSCLE RENDERING
  // ============================================
  void _paintFemaleBody(Canvas canvas, Paint baseFill, Paint subtleFill, Paint outline) {
    const centerX = 70.0;
    final body = Path();
    // Head & Slender Neck
    body.addOval(Rect.fromCenter(center: const Offset(centerX, 23), width: 24, height: 30));
    body.moveTo(63, 36);
    body.lineTo(50, 50); // Slender shoulder slope
    body.lineTo(38, 66); // Delicate deltoid curve
    body.lineTo(33, 106); // Upper arm to elbow
    body.lineTo(29, 144); // Wrist outer
    body.lineTo(36, 144); // Wrist inner
    body.lineTo(41, 108); // Forearm inner
    body.lineTo(50, 88); // Armpit
    
    // Hourglass Bust & High Narrow Waist
    body.quadraticBezierTo(46, 98, 50, 108); // Feminine chest curvature
    body.quadraticBezierTo(56, 118, 55, 124); // Narrow waist
    body.quadraticBezierTo(43, 142, 38, 162); // Feminine wide curved hip flare
    
    // Toned Athletic Legs
    body.quadraticBezierTo(41, 186, 47, 212); // Outer quad taper
    body.lineTo(48, 212); // Knee outer
    body.quadraticBezierTo(43, 236, 52, 274); // Slender calf curve
    body.lineTo(59, 274); // Ankle base
    body.quadraticBezierTo(56, 240, 56, 212); // Inner calf curve
    body.lineTo(56, 212); // Knee inner
    body.quadraticBezierTo(65, 175, 70, 154); // Inner thigh to groin
    
    // Mirrored Right Side
    body.quadraticBezierTo(75, 175, 84, 212);
    body.lineTo(84, 212);
    body.quadraticBezierTo(84, 240, 81, 274);
    body.lineTo(88, 274);
    body.quadraticBezierTo(97, 236, 92, 212);
    body.lineTo(93, 212);
    body.quadraticBezierTo(99, 186, 102, 162);
    body.quadraticBezierTo(97, 142, 85, 124);
    body.quadraticBezierTo(84, 118, 90, 108);
    body.quadraticBezierTo(94, 98, 90, 88);
    body.lineTo(99, 108);
    body.lineTo(104, 144);
    body.lineTo(111, 144);
    body.lineTo(107, 106);
    body.lineTo(102, 66);
    body.lineTo(90, 50);
    body.lineTo(77, 36);
    body.close();

    canvas.drawPath(body, baseFill);
    canvas.drawPath(body, subtleFill);
    canvas.drawPath(body, outline);
  }

  void _paintFemaleFrontMuscles(
    Canvas canvas,
    Paint activeFill,
    Paint activeStroke,
    Paint passiveStroke,
  ) {
    // Shoulders (Deltoids Nữ)
    final leftDeltoid = Path()
      ..moveTo(50, 50)
      ..quadraticBezierTo(36, 62, 40, 76)
      ..quadraticBezierTo(46, 72, 52, 62)
      ..close();
    final rightDeltoid = Path()
      ..moveTo(90, 50)
      ..quadraticBezierTo(104, 62, 100, 76)
      ..quadraticBezierTo(94, 72, 88, 62)
      ..close();
    _renderMusclePair(canvas, leftDeltoid, rightDeltoid, selectedMuscleId == 'shoulders', activeFill, activeStroke, passiveStroke);

    // Bust / Pectorals Nữ (Đường cong thể thao săn chắc)
    final leftChest = Path()
      ..moveTo(68, 56)
      ..lineTo(53, 58)
      ..quadraticBezierTo(46, 72, 49, 84)
      ..quadraticBezierTo(58, 92, 68, 87)
      ..close();
    final rightChest = Path()
      ..moveTo(72, 56)
      ..lineTo(87, 58)
      ..quadraticBezierTo(94, 72, 91, 84)
      ..quadraticBezierTo(82, 92, 72, 87)
      ..close();
    _renderMusclePair(canvas, leftChest, rightChest, selectedMuscleId == 'chest', activeFill, activeStroke, passiveStroke);

    // Biceps Nữ
    final leftBicep = Path()
      ..moveTo(38, 74)
      ..quadraticBezierTo(32, 88, 35, 106)
      ..lineTo(41, 104)
      ..quadraticBezierTo(44, 88, 46, 76)
      ..close();
    final rightBicep = Path()
      ..moveTo(102, 74)
      ..quadraticBezierTo(108, 88, 105, 106)
      ..lineTo(99, 104)
      ..quadraticBezierTo(96, 88, 94, 76)
      ..close();
    _renderMusclePair(canvas, leftBicep, rightBicep, selectedMuscleId == 'biceps', activeFill, activeStroke, passiveStroke);

    // Core & Cơ Bụng Số 11 Nữ
    final absPath = Path();
    // Central groove
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(69, 92, 2, 42), const Radius.circular(1)));
    // Left & right 11-line grooves
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(62, 96, 4, 15), const Radius.circular(2)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(74, 96, 4, 15), const Radius.circular(2)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(63, 115, 3.5, 16), const Radius.circular(2)));
    absPath.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(73.5, 115, 3.5, 16), const Radius.circular(2)));
    final isAbs = selectedMuscleId == 'abs';
    if (isAbs) {
      final glowPlate = Path()
        ..moveTo(60, 92)
        ..lineTo(80, 92)
        ..lineTo(76, 134)
        ..lineTo(64, 134)
        ..close();
      canvas.drawPath(glowPlate, Paint()..color = themeColor.withValues(alpha: 0.18));
      canvas.drawPath(absPath, activeFill);
      canvas.drawPath(absPath, activeStroke);
    } else {
      canvas.drawPath(absPath, passiveStroke);
    }

    // Quads Nữ
    final leftQuad = Path()
      ..moveTo(55, 140)
      ..quadraticBezierTo(39, 165, 44, 192)
      ..quadraticBezierTo(48, 208, 52, 208)
      ..quadraticBezierTo(59, 185, 66, 156)
      ..close();
    final rightQuad = Path()
      ..moveTo(85, 140)
      ..quadraticBezierTo(101, 165, 96, 192)
      ..quadraticBezierTo(92, 208, 88, 208)
      ..quadraticBezierTo(81, 185, 74, 156)
      ..close();
    _renderMusclePair(canvas, leftQuad, rightQuad, selectedMuscleId == 'quads', activeFill, activeStroke, passiveStroke);

    // Calves Front Nữ
    final leftCalf = Path()
      ..moveTo(51, 212)
      ..quadraticBezierTo(44, 234, 48, 254)
      ..lineTo(55, 272)
      ..quadraticBezierTo(57, 245, 55, 212)
      ..close();
    final rightCalf = Path()
      ..moveTo(89, 212)
      ..quadraticBezierTo(96, 234, 92, 254)
      ..lineTo(85, 272)
      ..quadraticBezierTo(83, 245, 85, 212)
      ..close();
    _renderMusclePair(canvas, leftCalf, rightCalf, selectedMuscleId == 'calves_front', activeFill, activeStroke, passiveStroke);
  }

  void _paintFemaleBackMuscles(
    Canvas canvas,
    Paint activeFill,
    Paint activeStroke,
    Paint passiveStroke,
  ) {
    // Trapezius Nữ
    final traps = Path()
      ..moveTo(70, 36)
      ..lineTo(52, 50)
      ..lineTo(62, 80)
      ..lineTo(70, 86)
      ..lineTo(78, 80)
      ..lineTo(88, 50)
      ..close();
    final isTraps = selectedMuscleId == 'traps';
    if (isTraps) {
      canvas.drawPath(traps, activeFill);
      canvas.drawPath(traps, activeStroke);
    } else {
      canvas.drawPath(traps, passiveStroke);
    }

    // Lats Nữ (Lưng Xô Cánh Bướm)
    final leftLat = Path()
      ..moveTo(50, 74)
      ..quadraticBezierTo(42, 92, 48, 116)
      ..quadraticBezierTo(56, 122, 68, 116)
      ..lineTo(68, 86)
      ..close();
    final rightLat = Path()
      ..moveTo(90, 74)
      ..quadraticBezierTo(98, 92, 92, 116)
      ..quadraticBezierTo(84, 122, 72, 116)
      ..lineTo(72, 86)
      ..close();
    _renderMusclePair(canvas, leftLat, rightLat, selectedMuscleId == 'lats', activeFill, activeStroke, passiveStroke);

    // Triceps Nữ (Tay Sau)
    final leftTricep = Path()
      ..moveTo(37, 66)
      ..quadraticBezierTo(30, 84, 32, 106)
      ..lineTo(39, 104)
      ..quadraticBezierTo(42, 86, 45, 74)
      ..close();
    final rightTricep = Path()
      ..moveTo(103, 66)
      ..quadraticBezierTo(110, 84, 108, 106)
      ..lineTo(101, 104)
      ..quadraticBezierTo(98, 86, 95, 74)
      ..close();
    _renderMusclePair(canvas, leftTricep, rightTricep, selectedMuscleId == 'triceps', activeFill, activeStroke, passiveStroke);

    // Lower Back Nữ
    final lowerBack = Path();
    lowerBack.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(60, 116, 7.5, 22), const Radius.circular(3)));
    lowerBack.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72.5, 116, 7.5, 22), const Radius.circular(3)));
    final isLowerBack = selectedMuscleId == 'lower_back';
    if (isLowerBack) {
      canvas.drawPath(lowerBack, activeFill);
      canvas.drawPath(lowerBack, activeStroke);
    } else {
      canvas.drawPath(lowerBack, passiveStroke);
    }

    // Glutes Nữ (Tâm điểm vòng 3 quả đào nở nang, cong tròn hoàn mỹ)
    final leftGlute = Path()
      ..moveTo(48, 138)
      ..quadraticBezierTo(35, 160, 48, 178)
      ..quadraticBezierTo(62, 182, 69, 172)
      ..lineTo(69, 138)
      ..close();
    final rightGlute = Path()
      ..moveTo(92, 138)
      ..quadraticBezierTo(105, 160, 92, 178)
      ..quadraticBezierTo(78, 182, 71, 172)
      ..lineTo(71, 138)
      ..close();
    _renderMusclePair(canvas, leftGlute, rightGlute, selectedMuscleId == 'glutes', activeFill, activeStroke, passiveStroke);

    // Hamstrings Nữ (Đùi Sau)
    final leftHam = Path()
      ..moveTo(47, 180)
      ..quadraticBezierTo(42, 196, 47, 212)
      ..lineTo(54, 212)
      ..quadraticBezierTo(60, 196, 64, 180)
      ..close();
    final rightHam = Path()
      ..moveTo(93, 180)
      ..quadraticBezierTo(98, 196, 93, 212)
      ..lineTo(86, 212)
      ..quadraticBezierTo(80, 196, 76, 180)
      ..close();
    _renderMusclePair(canvas, leftHam, rightHam, selectedMuscleId == 'hamstrings', activeFill, activeStroke, passiveStroke);

    // Calves Back Nữ (Bắp Chân Sau Thon Dài)
    final leftCalfBack = Path()
      ..moveTo(51, 212)
      ..quadraticBezierTo(43, 236, 48, 254)
      ..lineTo(55, 272)
      ..quadraticBezierTo(58, 245, 56, 212)
      ..close();
    final rightCalfBack = Path()
      ..moveTo(89, 212)
      ..quadraticBezierTo(97, 236, 92, 254)
      ..lineTo(85, 272)
      ..quadraticBezierTo(82, 245, 84, 212)
      ..close();
    _renderMusclePair(canvas, leftCalfBack, rightCalfBack, selectedMuscleId == 'calves_back', activeFill, activeStroke, passiveStroke);
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
    return oldDelegate.isFront != isFront ||
        oldDelegate.isMale != isMale ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.selectedMuscleId != selectedMuscleId;
  }
}
