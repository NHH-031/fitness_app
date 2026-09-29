import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Danh sách các loại bài tập được mô phỏng động học giải phẫu chi tiết
enum AnatomyExerciseType {
  squat,
  hipThrust,
  rdl,
  lunge,
  calfRaise,
  pushUp,
  diamondPushUp,
  benchPress,
  shoulderPress,
  tricepsExtension,
  pullUp,
  bentOverRow,
  bicepCurl,
  lateralRaise,
  plank,
  crunch,
  jumpingJack,
  burpee,
  mountainClimber,
  donkeyKick,
  yoga,
  general,
}

/// Góc nhìn hiển thị động học tối ưu cho bài tập
enum KinematicViewMode {
  side,
  front,
}

/// Cấu trúc lưu trữ tọa độ các khớp và mốc giải phẫu
class AnatomyKinematicJoints {
  final Offset head;
  final Offset neck;
  final Offset shoulderNear;
  final Offset shoulderFar;
  final Offset elbowNear;
  final Offset elbowFar;
  final Offset wristNear;
  final Offset wristFar;
  final Offset chest;
  final Offset midSpine;
  final Offset hipNear;
  final Offset hipFar;
  final Offset kneeNear;
  final Offset kneeFar;
  final Offset ankleNear;
  final Offset ankleFar;
  final Offset footNear;
  final Offset footFar;
  final KinematicViewMode viewMode;
  final bool hasDumbbells;
  final Offset? dumbbellNear;
  final Offset? dumbbellFar;
  final bool hasPullUpBar;
  final double? pullUpBarY;
  final bool hasBench;
  final Rect? benchRect;

  const AnatomyKinematicJoints({
    required this.head,
    required this.neck,
    required this.shoulderNear,
    required this.shoulderFar,
    required this.elbowNear,
    required this.elbowFar,
    required this.wristNear,
    required this.wristFar,
    required this.chest,
    required this.midSpine,
    required this.hipNear,
    required this.hipFar,
    required this.kneeNear,
    required this.kneeFar,
    required this.ankleNear,
    required this.ankleFar,
    required this.footNear,
    required this.footFar,
    required this.viewMode,
    this.hasDumbbells = false,
    this.dumbbellNear,
    this.dumbbellFar,
    this.hasPullUpBar = false,
    this.pullUpBarY,
    this.hasBench = false,
    this.benchRect,
  });
}

/// Khối tính toán động học và vẽ mô hình giải phẫu chuyển động 60 FPS
class AnatomyKinematicPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0 (chu kỳ chuyển động lặp)
  final String exerciseTitle;
  final bool isMale;
  final Color? customThemeColor;

  AnatomyKinematicPainter({
    required this.progress,
    required this.exerciseTitle,
    this.isMale = true,
    this.customThemeColor,
  });

  Color get themeColor =>
      customThemeColor ?? (isMale ? const Color(0xFF00F0FF) : const Color(0xFFFF2E93));
  Color get themeColorSecondary =>
      isMale ? const Color(0xFF0077B6) : const Color(0xFFFF52A8);

  static AnatomyExerciseType resolveExerciseType(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('floor press') || lower.contains('bench press') || lower.contains('đẩy ngực')) {
      return AnatomyExerciseType.benchPress;
    } else if (lower.contains('shoulder press') || lower.contains('đẩy vai')) {
      return AnatomyExerciseType.shoulderPress;
    } else if (lower.contains('triceps') || lower.contains('sau đầu') || lower.contains('tay sau')) {
      return AnatomyExerciseType.tricepsExtension;
    } else if (lower.contains('lateral') || lower.contains('dang tạ') || lower.contains('vai thon')) {
      return AnatomyExerciseType.lateralRaise;
    } else if (lower.contains('curl') || lower.contains('cuốn tạ') || lower.contains('tay trước') || lower.contains('thon bắp tay')) {
      return AnatomyExerciseType.bicepCurl;
    } else if (lower.contains('row') || lower.contains('kéo tạ') || lower.contains('thon lưng') || lower.contains('lưng xô')) {
      return AnatomyExerciseType.bentOverRow;
    } else if (lower.contains('rdl') || lower.contains('deadlift')) {
      return AnatomyExerciseType.rdl;
    } else if (lower.contains('hip thrust') || (lower.contains('cầu mông') && lower.contains('tạ'))) {
      return AnatomyExerciseType.hipThrust;
    } else if (lower.contains('diamond') || lower.contains('kim cương')) {
      return AnatomyExerciseType.diamondPushUp;
    } else if (lower.contains('pull') || lower.contains('xà đơn')) {
      return AnatomyExerciseType.pullUp;
    } else if (lower.contains('hít đất') || lower.contains('push')) {
      return AnatomyExerciseType.pushUp;
    } else if (lower.contains('burpee')) {
      return AnatomyExerciseType.burpee;
    } else if (lower.contains('mountain') || lower.contains('leo núi')) {
      return AnatomyExerciseType.mountainClimber;
    } else if (lower.contains('cầu mông') || lower.contains('bridge')) {
      return AnatomyExerciseType.hipThrust;
    } else if (lower.contains('đá mông') || lower.contains('donkey')) {
      return AnatomyExerciseType.donkeyKick;
    } else if (lower.contains('chùng chân') || lower.contains('lunge')) {
      return AnatomyExerciseType.lunge;
    } else if (lower.contains('jumping') || lower.contains('nhảy')) {
      return AnatomyExerciseType.jumpingJack;
    } else if (lower.contains('gập bụng') || lower.contains('crunch') || lower.contains('russian') || lower.contains('vặn') || lower.contains('bicycle') || lower.contains('đạp xe')) {
      return AnatomyExerciseType.crunch;
    } else if (lower.contains('plank')) {
      return AnatomyExerciseType.plank;
    } else if (lower.contains('calf') || lower.contains('bắp chân') || lower.contains('nhón')) {
      return AnatomyExerciseType.calfRaise;
    } else if (lower.contains('squat')) {
      return AnatomyExerciseType.squat;
    } else if (lower.contains('yoga') || lower.contains('stretch') || lower.contains('giãn')) {
      return AnatomyExerciseType.yoga;
    }
    return AnatomyExerciseType.general;
  }

  static KinematicViewMode getViewMode(AnatomyExerciseType type) {
    switch (type) {
      case AnatomyExerciseType.shoulderPress:
      case AnatomyExerciseType.bicepCurl:
      case AnatomyExerciseType.lateralRaise:
      case AnatomyExerciseType.pullUp:
      case AnatomyExerciseType.jumpingJack:
      case AnatomyExerciseType.calfRaise:
        return KinematicViewMode.front;
      case AnatomyExerciseType.squat:
      case AnatomyExerciseType.hipThrust:
      case AnatomyExerciseType.rdl:
      case AnatomyExerciseType.lunge:
      case AnatomyExerciseType.pushUp:
      case AnatomyExerciseType.diamondPushUp:
      case AnatomyExerciseType.benchPress:
      case AnatomyExerciseType.tricepsExtension:
      case AnatomyExerciseType.bentOverRow:
      case AnatomyExerciseType.plank:
      case AnatomyExerciseType.crunch:
      case AnatomyExerciseType.burpee:
      case AnatomyExerciseType.mountainClimber:
      case AnatomyExerciseType.donkeyKick:
      case AnatomyExerciseType.yoga:
      case AnatomyExerciseType.general:
        return KinematicViewMode.side;
    }
  }

  /// Trả về nhóm cơ mục tiêu chính
  static String getPrimaryMuscleId(AnatomyExerciseType type) {
    switch (type) {
      case AnatomyExerciseType.squat:
      case AnatomyExerciseType.lunge:
        return 'quads';
      case AnatomyExerciseType.hipThrust:
      case AnatomyExerciseType.donkeyKick:
        return 'glutes';
      case AnatomyExerciseType.rdl:
        return 'hamstrings';
      case AnatomyExerciseType.calfRaise:
        return 'calves_front';
      case AnatomyExerciseType.pushUp:
      case AnatomyExerciseType.diamondPushUp:
      case AnatomyExerciseType.benchPress:
        return 'chest';
      case AnatomyExerciseType.shoulderPress:
      case AnatomyExerciseType.lateralRaise:
        return 'shoulders';
      case AnatomyExerciseType.tricepsExtension:
        return 'triceps';
      case AnatomyExerciseType.pullUp:
      case AnatomyExerciseType.bentOverRow:
        return 'lats';
      case AnatomyExerciseType.bicepCurl:
        return 'biceps';
      case AnatomyExerciseType.plank:
      case AnatomyExerciseType.crunch:
      case AnatomyExerciseType.mountainClimber:
        return 'abs';
      case AnatomyExerciseType.jumpingJack:
        return 'calves_front';
      case AnatomyExerciseType.burpee:
        return 'quads';
      case AnatomyExerciseType.yoga:
        return 'lower_back';
      case AnatomyExerciseType.general:
        return 'quads';
    }
  }

  /// Chuyển đổi tiến trình chu kỳ lặp (0.0 -> 1.0) sang pha động học biomechanical mượt mà:
  /// - Giai đoạn 1 (0.00 -> 0.08): Chuẩn bị / Khóa khớp tư thế ban đầu (Ready stance, phase = 0.0)
  /// - Giai đoạn 2 (0.08 -> 0.46): Hạ tạ / Xuống tấn (Eccentric, cubic ease-in-out mượt mà, phase = 0.0 -> 1.0)
  /// - Giai đoạn 3 (0.46 -> 0.58): Giữ tĩnh quan sát đỉnh co cơ (Peak Isometric hold, phase = 1.0)
  /// - Giai đoạn 4 (0.58 -> 0.90): Đẩy lên / Co cơ phát lực (Concentric, cubic ease mượt mà, phase = 1.0 -> 0.0)
  /// - Giai đoạn 5 (0.90 -> 1.00): Khóa khớp & điều hòa nhịp thở (Lockout & reset breath, phase = 0.0)
  static double computeBiomechanicalPhase(double cycleT, AnatomyExerciseType type) {
    final t = cycleT.clamp(0.0, 1.0);

    // Đối với các bài tập nhịp điệu Cardio/Mobility luân phiên liên tục
    switch (type) {
      case AnatomyExerciseType.mountainClimber:
        // Đạp gối luân phiên liên tục dạng sóng sin điều hòa
        return 0.5 - 0.5 * math.cos(t * math.pi * 2);
      case AnatomyExerciseType.burpee:
        // Chuỗi 4 chuyển động tuần tự Burpee (0.0 -> 1.0)
        return t;
      case AnatomyExerciseType.jumpingJack:
        // Nhảy mở rộng và khép lại mượt mà
        return 0.5 - 0.5 * math.cos(t * math.pi * 2);
      case AnatomyExerciseType.plank:
        // Đẳng trường ổn định với nhịp thở vi mô
        return t;
      case AnatomyExerciseType.yoga:
      case AnatomyExerciseType.general:
        return 0.5 - 0.5 * math.cos(t * math.pi * 2);
      default:
        break;
    }

    // Các bài tập kháng lực có chu kỳ Repetition chuẩn 4 pha
    if (t < 0.08) {
      // 1. Starting ready pose
      return 0.0;
    } else if (t < 0.46) {
      // 2. Controlled eccentric descent (hạ xuống có kiểm soát)
      final u = (t - 0.08) / 0.38;
      // Hermite smoothstep cubic: 3u^2 - 2u^3
      return u * u * (3.0 - 2.0 * u);
    } else if (t < 0.58) {
      // 3. Peak isometric hold (giữ tĩnh để người dùng quan sát form chuẩn và cơ kích hoạt)
      return 1.0;
    } else if (t < 0.90) {
      // 4. Smooth concentric ascent (đẩy/kéo phát lực lên mượt mà)
      final v = (t - 0.58) / 0.32;
      return 1.0 - (v * v * (3.0 - 2.0 * v));
    } else {
      // 5. Lockout & reset stance
      return 0.0;
    }
  }

  /// Tính toán hệ số kích hoạt cơ bắp thời gian thực (0.0 -> 1.0)
  static double getMuscleActivation(double progress, AnatomyExerciseType type, String muscleId) {
    final primary = getPrimaryMuscleId(type);
    if (primary != muscleId) {
      // Cơ bổ trợ có hệ số nền nhẹ
      return 0.15;
    }

    switch (type) {
      case AnatomyExerciseType.squat:
        // Đỉnh co cơ khi đẩy từ đáy lên đỉnh
        return 0.35 + 0.65 * math.sin(progress * math.pi);
      case AnatomyExerciseType.hipThrust:
        // Đỉnh khi nâng hông lên cao nhất (progress = 1.0)
        return 0.25 + 0.75 * math.pow(progress, 1.8);
      case AnatomyExerciseType.rdl:
        // Đùi sau căng nhất ở đáy gập hông và siết ở đỉnh
        return 0.30 + 0.70 * progress;
      case AnatomyExerciseType.lunge:
        return 0.30 + 0.70 * math.sin(progress * math.pi);
      case AnatomyExerciseType.calfRaise:
        return 0.20 + 0.80 * math.pow(progress, 2.0);
      case AnatomyExerciseType.pushUp:
      case AnatomyExerciseType.diamondPushUp:
      case AnatomyExerciseType.benchPress:
        // Ngực co ép mạnh nhất khi đẩy tạ lên cao (progress = 1.0)
        return 0.25 + 0.75 * math.pow(progress, 1.5);
      case AnatomyExerciseType.shoulderPress:
      case AnatomyExerciseType.lateralRaise:
        return 0.25 + 0.75 * progress;
      case AnatomyExerciseType.tricepsExtension:
        return 0.25 + 0.75 * progress;
      case AnatomyExerciseType.pullUp:
      case AnatomyExerciseType.bentOverRow:
        return 0.30 + 0.70 * progress;
      case AnatomyExerciseType.bicepCurl:
        return 0.20 + 0.80 * progress;
      case AnatomyExerciseType.plank:
        // Co cứng đẳng trường (Isometric) với nhịp thở vi mô
        return 0.80 + 0.18 * math.sin(progress * math.pi * 2);
      case AnatomyExerciseType.crunch:
        return 0.25 + 0.75 * progress;
      case AnatomyExerciseType.mountainClimber:
      case AnatomyExerciseType.jumpingJack:
      case AnatomyExerciseType.burpee:
        return 0.40 + 0.60 * math.sin(progress * math.pi);
      case AnatomyExerciseType.donkeyKick:
        return 0.25 + 0.75 * progress;
      case AnatomyExerciseType.yoga:
      case AnatomyExerciseType.general:
        return 0.40 + 0.40 * math.sin(progress * math.pi);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final type = resolveExerciseType(exerciseTitle);
    final viewMode = getViewMode(type);
    final joints = _calculateKinematicRig(size, type, viewMode);

    // 1. Vẽ nền sàn ba chiều / Holographic Floor & Equipment
    _drawEnvironment(canvas, size, joints, type);

    // 1.5 Vẽ vệt quỹ đạo chuyển động mờ (Motion Trails / Trajectory Line)
    _drawMotionTrails(canvas, size, joints, type);

    // 2. Vẽ mô hình cơ bắp giải phẫu đa tầng
    if (viewMode == KinematicViewMode.side) {
      _paintSideAnatomy(canvas, size, joints, type);
    } else {
      _paintFrontAnatomy(canvas, size, joints, type);
    }

    // 3. Vẽ tạ đơn hoặc xà nếu có
    _drawEquipmentOverlay(canvas, size, joints);

    // 4. Vẽ bảng thông số kích hoạt cơ HUD
    _drawMuscleActivationHUD(canvas, size, type);
  }

  // ==========================================
  // 1. TÍNH TOÁN KHUNG XƯƠNG ĐỘNG HỌC (RIG)
  // ==========================================
  AnatomyKinematicJoints _calculateKinematicRig(
    Size size,
    AnatomyExerciseType type,
    KinematicViewMode viewMode,
  ) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final groundY = h * 0.79;
    final p = progress.clamp(0.0, 1.0);

    if (viewMode == KinematicViewMode.front) {
      switch (type) {
        case AnatomyExerciseType.shoulderPress:
          final shoulderY = h * 0.38;
          final hipY = h * 0.58;
          final sW = isMale ? 26.0 : 22.0;
          // Overhead press: elbows extend upward and hands press overhead
          final handY = (h * 0.33) - (h * 0.17) * p;
          final handXLeft = (cx - 28) + (14 * p);
          final handXRight = (cx + 28) - (14 * p);
          final elbowY = (h * 0.44) - (h * 0.17) * p;
          final elbowXLeft = (cx - 32) + (12 * p);
          final elbowXRight = (cx + 32) - (12 * p);

          return AnatomyKinematicJoints(
            head: Offset(cx, h * 0.22),
            neck: Offset(cx, h * 0.30),
            shoulderNear: Offset(cx - sW, shoulderY),
            shoulderFar: Offset(cx + sW, shoulderY),
            elbowNear: Offset(elbowXLeft, elbowY),
            elbowFar: Offset(elbowXRight, elbowY),
            wristNear: Offset(handXLeft, handY),
            wristFar: Offset(handXRight, handY),
            chest: Offset(cx, h * 0.40),
            midSpine: Offset(cx, h * 0.49),
            hipNear: Offset(cx - 16, hipY),
            hipFar: Offset(cx + 16, hipY),
            kneeNear: Offset(cx - 18, h * 0.70),
            kneeFar: Offset(cx + 18, h * 0.70),
            ankleNear: Offset(cx - 18, groundY),
            ankleFar: Offset(cx + 18, groundY),
            footNear: Offset(cx - 22, groundY),
            footFar: Offset(cx + 22, groundY),
            viewMode: KinematicViewMode.front,
            hasDumbbells: true,
            dumbbellNear: Offset(handXLeft, handY),
            dumbbellFar: Offset(handXRight, handY),
          );

        case AnatomyExerciseType.bicepCurl:
          final shoulderY = h * 0.38;
          final sW = isMale ? 26.0 : 22.0;
          final elbowY = h * 0.52;
          final elbowXLeft = cx - 20.0;
          final elbowXRight = cx + 20.0;
          // Forearms curl in circular arc around stable elbow joint
          const forearmLen = 20.0;
          final curlAngle = p * 2.45;
          final wristY = elbowY + forearmLen * math.cos(curlAngle);
          final wristXNear = elbowXLeft - 4.0 * math.sin(curlAngle);
          final wristXFar = elbowXRight + 4.0 * math.sin(curlAngle);

          return AnatomyKinematicJoints(
            head: Offset(cx, h * 0.22),
            neck: Offset(cx, h * 0.30),
            shoulderNear: Offset(cx - sW, shoulderY),
            shoulderFar: Offset(cx + sW, shoulderY),
            elbowNear: Offset(elbowXLeft, elbowY),
            elbowFar: Offset(elbowXRight, elbowY),
            wristNear: Offset(wristXNear, wristY),
            wristFar: Offset(wristXFar, wristY),
            chest: Offset(cx, h * 0.40),
            midSpine: Offset(cx, h * 0.49),
            hipNear: Offset(cx - 16, h * 0.58),
            hipFar: Offset(cx + 16, h * 0.58),
            kneeNear: Offset(cx - 16, h * 0.70),
            kneeFar: Offset(cx + 16, h * 0.70),
            ankleNear: Offset(cx - 16, groundY),
            ankleFar: Offset(cx + 16, groundY),
            footNear: Offset(cx - 20, groundY),
            footFar: Offset(cx + 20, groundY),
            viewMode: KinematicViewMode.front,
            hasDumbbells: true,
            dumbbellNear: Offset(wristXNear, wristY),
            dumbbellFar: Offset(wristXFar, wristY),
          );

        case AnatomyExerciseType.lateralRaise:
          final shoulderY = h * 0.38;
          final sW = isMale ? 26.0 : 22.0;
          const uArmLen = 18.0;
          const fArmLen = 17.0;
          // Pure circular shoulder abduction arc: 12 deg (at thigh) to 87 deg (parallel to floor)
          final alpha = 0.20 + (p * 1.32);
          final elbowXNear = (cx - sW) - (uArmLen * math.sin(alpha));
          final elbowXFar = (cx + sW) + (uArmLen * math.sin(alpha));
          final elbowY = shoulderY + (uArmLen * math.cos(alpha));
          // Soft 10 degree elbow bend
          final wristXNear = elbowXNear - (fArmLen * math.sin(alpha + 0.14));
          final wristXFar = elbowXFar + (fArmLen * math.sin(alpha + 0.14));
          final wristY = elbowY + (fArmLen * math.cos(alpha + 0.14));

          return AnatomyKinematicJoints(
            head: Offset(cx, h * 0.22),
            neck: Offset(cx, h * 0.30),
            shoulderNear: Offset(cx - sW, shoulderY),
            shoulderFar: Offset(cx + sW, shoulderY),
            elbowNear: Offset(elbowXNear, elbowY),
            elbowFar: Offset(elbowXFar, elbowY),
            wristNear: Offset(wristXNear, wristY),
            wristFar: Offset(wristXFar, wristY),
            chest: Offset(cx, h * 0.40),
            midSpine: Offset(cx, h * 0.49),
            hipNear: Offset(cx - 16, h * 0.58),
            hipFar: Offset(cx + 16, h * 0.58),
            kneeNear: Offset(cx - 16, h * 0.70),
            kneeFar: Offset(cx + 16, h * 0.70),
            ankleNear: Offset(cx - 16, groundY),
            ankleFar: Offset(cx + 16, groundY),
            footNear: Offset(cx - 20, groundY),
            footFar: Offset(cx + 20, groundY),
            viewMode: KinematicViewMode.front,
            hasDumbbells: true,
            dumbbellNear: Offset(wristXNear, wristY),
            dumbbellFar: Offset(wristXFar, wristY),
          );

        case AnatomyExerciseType.pullUp:
          final barY = h * 0.18;
          final sW = isMale ? 28.0 : 24.0;
          // p=0 full dead hang (chin below bar); p=1 chin above bar
          final pullY = (h * 0.20) * (1.0 - p);
          final bodyTop = barY + 14 + pullY;
          final elbowY = (barY + 18) + (bodyTop + 24 - (barY + 18)) * p;
          final elbowXNear = (cx - 36) + (8 * p);
          final elbowXFar = (cx + 36) - (8 * p);

          return AnatomyKinematicJoints(
            head: Offset(cx, bodyTop + 6),
            neck: Offset(cx, bodyTop + 20),
            shoulderNear: Offset(cx - sW, bodyTop + 26),
            shoulderFar: Offset(cx + sW, bodyTop + 26),
            elbowNear: Offset(elbowXNear, elbowY),
            elbowFar: Offset(elbowXFar, elbowY),
            wristNear: Offset(cx - 38, barY),
            wristFar: Offset(cx + 38, barY),
            chest: Offset(cx, bodyTop + 36),
            midSpine: Offset(cx, bodyTop + 54),
            hipNear: Offset(cx - 16, bodyTop + 72),
            hipFar: Offset(cx + 16, bodyTop + 72),
            kneeNear: Offset(cx - 16, bodyTop + 96),
            kneeFar: Offset(cx + 16, bodyTop + 96),
            ankleNear: Offset(cx - 14, bodyTop + 120),
            ankleFar: Offset(cx + 14, bodyTop + 120),
            footNear: Offset(cx - 14, bodyTop + 124),
            footFar: Offset(cx + 14, bodyTop + 124),
            viewMode: KinematicViewMode.front,
            hasPullUpBar: true,
            pullUpBarY: barY,
          );

        case AnatomyExerciseType.jumpingJack:
          final sW = isMale ? 25.0 : 21.0;
          // Circular 180 degree arm arc: 10 deg to 175 deg
          final armAngle = 0.20 + (p * 2.80);
          final handXNear = cx - (36.0 * math.sin(armAngle));
          final handXFar = cx + (36.0 * math.sin(armAngle));
          final handY = (h * 0.40) + (36.0 * math.cos(armAngle));
          // Legs jump open and close
          final footXNear = cx - 14.0 - (26.0 * p);
          final footXFar = cx + 14.0 + (26.0 * p);
          final kneeBend = 3.0 * math.sin(p * math.pi);

          return AnatomyKinematicJoints(
            head: Offset(cx, h * 0.20 - (4 * p)),
            neck: Offset(cx, h * 0.28 - (4 * p)),
            shoulderNear: Offset(cx - sW, h * 0.35 - (4 * p)),
            shoulderFar: Offset(cx + sW, h * 0.35 - (4 * p)),
            elbowNear: Offset((cx - sW) - (18.0 * math.sin(armAngle * 0.8)), (h * 0.35) + (18.0 * math.cos(armAngle * 0.8))),
            elbowFar: Offset((cx + sW) + (18.0 * math.sin(armAngle * 0.8)), (h * 0.35) + (18.0 * math.cos(armAngle * 0.8))),
            wristNear: Offset(handXNear, handY),
            wristFar: Offset(handXFar, handY),
            chest: Offset(cx, h * 0.39 - (4 * p)),
            midSpine: Offset(cx, h * 0.48 - (4 * p)),
            hipNear: Offset(cx - 15, h * 0.57 - (4 * p)),
            hipFar: Offset(cx + 15, h * 0.57 - (4 * p)),
            kneeNear: Offset(footXNear * 0.82, h * 0.69 + kneeBend),
            kneeFar: Offset(footXFar * 0.82, h * 0.69 + kneeBend),
            ankleNear: Offset(footXNear, groundY),
            ankleFar: Offset(footXFar, groundY),
            footNear: Offset(footXNear - 4, groundY),
            footFar: Offset(footXFar + 4, groundY),
            viewMode: KinematicViewMode.front,
          );

        case AnatomyExerciseType.calfRaise:
          final sW = isMale ? 25.0 : 21.0;
          final heelLift = p * 14.0;
          final bodyLift = heelLift * 0.88;

          return AnatomyKinematicJoints(
            head: Offset(cx, h * 0.22 - bodyLift),
            neck: Offset(cx, h * 0.30 - bodyLift),
            shoulderNear: Offset(cx - sW, h * 0.38 - bodyLift),
            shoulderFar: Offset(cx + sW, h * 0.38 - bodyLift),
            elbowNear: Offset(cx - 22, h * 0.50 - bodyLift),
            elbowFar: Offset(cx + 22, h * 0.50 - bodyLift),
            wristNear: Offset(cx - 20, h * 0.62 - bodyLift),
            wristFar: Offset(cx + 20, h * 0.62 - bodyLift),
            chest: Offset(cx, h * 0.40 - bodyLift),
            midSpine: Offset(cx, h * 0.49 - bodyLift),
            hipNear: Offset(cx - 16, h * 0.58 - bodyLift),
            hipFar: Offset(cx + 16, h * 0.58 - bodyLift),
            kneeNear: Offset(cx - 16, h * 0.70 - bodyLift),
            kneeFar: Offset(cx + 16, h * 0.70 - bodyLift),
            ankleNear: Offset(cx - 16, groundY - heelLift),
            ankleFar: Offset(cx + 16, groundY - heelLift),
            footNear: Offset(cx - 16, groundY),
            footFar: Offset(cx + 16, groundY),
            viewMode: KinematicViewMode.front,
          );

        default:
          break;
      }
    }

    // ==========================================
    // SIDE VIEW KINEMATIC RIGS
    // ==========================================
    switch (type) {
      case AnatomyExerciseType.squat:
        // Deep squat with constant bone lengths
        final ankleX = cx + 2.0;
        final ankleY = groundY;
        const shinLen = 28.0;
        const thighLen = 30.0;
        const torsoLen = 32.0;

        // Shin angle: 1.52 rad (~87 deg) standing to 1.10 rad (~63 deg) deep squat
        final shinAngle = 1.52 - (0.42 * p);
        final kneeX = ankleX + (shinLen * math.cos(shinAngle));
        final kneeY = ankleY - (shinLen * math.sin(shinAngle));

        // Thigh angle: 1.54 rad (~88 deg) to 0.10 rad (~6 deg parallel to floor)
        final thighAngle = 1.54 - (1.44 * p);
        final hipX = kneeX - (thighLen * math.cos(thighAngle));
        final hipY = kneeY - (thighLen * math.sin(thighAngle));

        // Torso angle: 1.50 rad (~86 deg) to 0.85 rad (~49 deg forward lean for balance)
        final torsoAngle = 1.50 - (0.65 * p);
        final shoulderX = hipX + (torsoLen * math.cos(torsoAngle));
        final shoulderY = hipY - (torsoLen * math.sin(torsoAngle));

        final neck = Offset(shoulderX + 2, shoulderY - 8);
        final head = Offset(neck.dx + 2, neck.dy - 10);
        final chest = Offset(shoulderX + 5, shoulderY + 12);
        final midSpine = Offset((shoulderX + hipX) * 0.5 + 2, (shoulderY + hipY) * 0.5);

        // Arms holding dumbbell in goblet position in front of chest
        final elbowNear = Offset(shoulderX + 12, shoulderY + 16);
        final wristNear = Offset(shoulderX + 18, shoulderY + 12);

        return AnatomyKinematicJoints(
          head: head,
          neck: neck,
          shoulderNear: Offset(shoulderX, shoulderY),
          shoulderFar: Offset(shoulderX + 5, shoulderY - 2),
          elbowNear: elbowNear,
          elbowFar: Offset(elbowNear.dx + 4, elbowNear.dy - 2),
          wristNear: wristNear,
          wristFar: Offset(wristNear.dx + 4, wristNear.dy - 2),
          chest: chest,
          midSpine: midSpine,
          hipNear: Offset(hipX, hipY),
          hipFar: Offset(hipX + 4, hipY - 2),
          kneeNear: Offset(kneeX, kneeY),
          kneeFar: Offset(kneeX + 4, kneeY - 2),
          ankleNear: Offset(ankleX, ankleY),
          ankleFar: Offset(ankleX + 4, ankleY),
          footNear: Offset(ankleX + 14, groundY),
          footFar: Offset(ankleX + 18, groundY),
          viewMode: KinematicViewMode.side,
          hasDumbbells: true,
          dumbbellNear: wristNear,
        );

      case AnatomyExerciseType.hipThrust:
        final benchX = cx - 36.0;
        final benchY = h * 0.60;
        final shoulderX = benchX + 6.0;
        final shoulderY = benchY - 4.0;
        final kneeX = cx + 22.0;
        final kneeY = benchY + 2.0;

        // Hip drives up: from near floor (groundY - 14) to tabletop flat (benchY - 4)
        final hipX = cx - 4.0;
        final hipY = (groundY - 14.0) - ((groundY - 10.0 - benchY) * p);

        return AnatomyKinematicJoints(
          head: Offset(shoulderX - 14, shoulderY - 8),
          neck: Offset(shoulderX - 6, shoulderY - 4),
          shoulderNear: Offset(shoulderX, shoulderY),
          shoulderFar: Offset(shoulderX + 4, shoulderY - 2),
          elbowNear: Offset(shoulderX - 4, shoulderY + 12),
          elbowFar: Offset(shoulderX, shoulderY + 10),
          wristNear: Offset(hipX - 2, hipY - 6),
          wristFar: Offset(hipX + 2, hipY - 6),
          chest: Offset(shoulderX + 12, shoulderY + 4),
          midSpine: Offset((shoulderX + hipX) * 0.5, (shoulderY + hipY) * 0.5),
          hipNear: Offset(hipX, hipY),
          hipFar: Offset(hipX + 4, hipY - 2),
          kneeNear: Offset(kneeX, kneeY),
          kneeFar: Offset(kneeX + 4, kneeY - 2),
          ankleNear: Offset(kneeX - 2, groundY),
          ankleFar: Offset(kneeX + 2, groundY),
          footNear: Offset(kneeX + 10, groundY),
          footFar: Offset(kneeX + 14, groundY),
          viewMode: KinematicViewMode.side,
          hasDumbbells: true,
          dumbbellNear: Offset(hipX, hipY - 4),
          hasBench: true,
          benchRect: Rect.fromLTWH(cx - 52, benchY, 26, groundY - benchY),
        );

      case AnatomyExerciseType.rdl:
        final ankleX = cx + 4.0;
        final kneeX = cx + 7.0;
        final kneeY = groundY - 26.0;

        // Hip hinges back horizontally
        final hipX = (cx - 2.0) - (24.0 * p);
        final hipY = (groundY - 54.0) + (6.0 * p);

        // Flat spine hinges forward: 1.48 rad (~85 deg) to 0.48 rad (~27 deg)
        final torsoAngle = 1.48 - (1.00 * p);
        final shoulderX = hipX + (32.0 * math.cos(torsoAngle));
        final shoulderY = hipY - (32.0 * math.sin(torsoAngle));

        // Dumbbells slide vertically right down the shins under gravity
        final handX = shoulderX + 2.0;
        final handY = (groundY - 22.0) - (22.0 * (1.0 - p));

        return AnatomyKinematicJoints(
          head: Offset(shoulderX + 8, shoulderY - 8),
          neck: Offset(shoulderX + 4, shoulderY - 2),
          shoulderNear: Offset(shoulderX, shoulderY),
          shoulderFar: Offset(shoulderX + 4, shoulderY - 2),
          elbowNear: Offset((shoulderX + handX) * 0.5, (shoulderY + handY) * 0.5),
          elbowFar: Offset((shoulderX + handX) * 0.5 + 4, (shoulderY + handY) * 0.5),
          wristNear: Offset(handX, handY),
          wristFar: Offset(handX + 4, handY),
          chest: Offset(shoulderX - 4, shoulderY + 8),
          midSpine: Offset((shoulderX + hipX) * 0.5, (shoulderY + hipY) * 0.5),
          hipNear: Offset(hipX, hipY),
          hipFar: Offset(hipX + 4, hipY - 2),
          kneeNear: Offset(kneeX, kneeY),
          kneeFar: Offset(kneeX + 4, kneeY),
          ankleNear: Offset(ankleX, groundY),
          ankleFar: Offset(ankleX + 4, groundY),
          footNear: Offset(ankleX + 14, groundY),
          footFar: Offset(ankleX + 18, groundY),
          viewMode: KinematicViewMode.side,
          hasDumbbells: true,
          dumbbellNear: Offset(handX, handY),
        );

      case AnatomyExerciseType.lunge:
        final frontKneeX = cx + 22.0;
        final frontKneeY = groundY - 24.0;
        final rearKneeX = cx - 22.0;
        final rearKneeY = (groundY - 22.0) + (16.0 * p);
        final hipY = (groundY - 38.0) + (14.0 * p);
        final torsoY = (groundY - 70.0) + (14.0 * p);

        return AnatomyKinematicJoints(
          head: Offset(cx + 4, torsoY - 18),
          neck: Offset(cx + 2, torsoY - 8),
          shoulderNear: Offset(cx, torsoY),
          shoulderFar: Offset(cx + 6, torsoY - 2),
          elbowNear: Offset(cx + 2, torsoY + 18),
          elbowFar: Offset(cx + 8, torsoY + 16),
          wristNear: Offset(cx + 4, torsoY + 36),
          wristFar: Offset(cx + 10, torsoY + 34),
          chest: Offset(cx + 6, torsoY + 12),
          midSpine: Offset(cx, (torsoY + hipY) * 0.5),
          hipNear: Offset(cx - 2, hipY),
          hipFar: Offset(cx + 4, hipY - 2),
          kneeNear: Offset(frontKneeX, frontKneeY),
          kneeFar: Offset(rearKneeX, rearKneeY),
          ankleNear: Offset(frontKneeX - 2, groundY),
          ankleFar: Offset(rearKneeX - 16, groundY - 4),
          footNear: Offset(frontKneeX + 10, groundY),
          footFar: Offset(rearKneeX - 8, groundY),
          viewMode: KinematicViewMode.side,
          hasDumbbells: true,
          dumbbellNear: Offset(cx + 4, torsoY + 36),
        );

      case AnatomyExerciseType.pushUp:
      case AnatomyExerciseType.diamondPushUp:
        final footX = cx - 44.0;
        final footY = groundY;
        final handX = cx + 26.0;
        final handY = groundY;

        // Perfect rigid athletic plank angle: 0.12 rad (~7 deg) to 0.38 rad (~22 deg)
        final bodyAngle = 0.12 + (0.26 * p);
        const bodyLen = 70.0;
        final shoulderX = footX + (bodyLen * math.cos(bodyAngle));
        final shoulderY = footY - (bodyLen * math.sin(bodyAngle));
        final hipX = footX + (38.0 * math.cos(bodyAngle));
        final hipY = footY - (38.0 * math.sin(bodyAngle));
        final kneeX = footX + (19.0 * math.cos(bodyAngle));
        final kneeY = footY - (19.0 * math.sin(bodyAngle));

        // Elbow hinges smoothly backwards at 45 degrees
        final elbowNear = Offset(
          shoulderX - 14.0 * (1.0 - p) + 4.0 * p,
          (shoulderY + handY) * 0.5 + 4.0 * (1.0 - p),
        );

        return AnatomyKinematicJoints(
          head: Offset(shoulderX + 14, shoulderY - 4),
          neck: Offset(shoulderX + 6, shoulderY - 2),
          shoulderNear: Offset(shoulderX, shoulderY),
          shoulderFar: Offset(shoulderX + 4, shoulderY - 2),
          elbowNear: elbowNear,
          elbowFar: Offset(elbowNear.dx + 4, elbowNear.dy - 2),
          wristNear: Offset(handX, handY),
          wristFar: Offset(handX + 4, handY),
          chest: Offset(shoulderX - 4, shoulderY + 4),
          midSpine: Offset((shoulderX + hipX) * 0.5, (shoulderY + hipY) * 0.5),
          hipNear: Offset(hipX, hipY),
          hipFar: Offset(hipX + 2, hipY - 2),
          kneeNear: Offset(kneeX, kneeY),
          kneeFar: Offset(kneeX + 2, kneeY),
          ankleNear: Offset(footX, footY),
          ankleFar: Offset(footX + 4, footY),
          footNear: Offset(footX - 4, footY),
          footFar: Offset(footX, footY),
          viewMode: KinematicViewMode.side,
        );

      case AnatomyExerciseType.benchPress:
        final benchY = h * 0.68;
        final bodyY = benchY - 4.0;
        final shoulderX = cx - 24.0;
        final hipX = cx + 12.0;
        final handX = shoulderX + 10.0;
        // Dumbbells press vertically from chest (benchY - 10) to lockout (benchY - 38)
        final handY = (bodyY - 10.0) - (28.0 * p);
        final elbowNear = Offset(shoulderX - 4.0 * (1.0 - p), (bodyY + handY) * 0.5 + 6.0 * (1.0 - p));

        return AnatomyKinematicJoints(
          head: Offset(shoulderX - 16, bodyY),
          neck: Offset(shoulderX - 6, bodyY),
          shoulderNear: Offset(shoulderX, bodyY),
          shoulderFar: Offset(shoulderX + 4, bodyY - 2),
          elbowNear: elbowNear,
          elbowFar: Offset(elbowNear.dx + 4, elbowNear.dy - 2),
          wristNear: Offset(handX, handY),
          wristFar: Offset(handX + 4, handY),
          chest: Offset(shoulderX + 8, bodyY - 4),
          midSpine: Offset((shoulderX + hipX) * 0.5, bodyY),
          hipNear: Offset(hipX, bodyY),
          hipFar: Offset(hipX + 2, bodyY - 2),
          kneeNear: Offset(hipX + 16, bodyY - 14),
          kneeFar: Offset(hipX + 18, bodyY - 16),
          ankleNear: Offset(hipX + 26, groundY),
          ankleFar: Offset(hipX + 28, groundY),
          footNear: Offset(hipX + 32, groundY),
          footFar: Offset(hipX + 34, groundY),
          viewMode: KinematicViewMode.side,
          hasDumbbells: true,
          dumbbellNear: Offset(handX, handY),
          hasBench: true,
          benchRect: Rect.fromLTWH(cx - 48, benchY, 56, groundY - benchY),
        );

      case AnatomyExerciseType.bentOverRow:
        final hipX = cx - 18.0;
        final hipY = h * 0.52;
        // Torso locked at 42 degree forward hinge
        final shoulderX = hipX + (32.0 * math.cos(0.72));
        final shoulderY = hipY - (32.0 * math.sin(0.72));
        // Arms pull dumbbells to ribcage
        final handX = shoulderX - (6.0 * p);
        final handY = (h * 0.68) - (20.0 * p);
        final elbowX = shoulderX - 2.0 - (12.0 * p);
        final elbowY = (h * 0.56) - (18.0 * p);

        return AnatomyKinematicJoints(
          head: Offset(shoulderX + 12, shoulderY - 8),
          neck: Offset(shoulderX + 6, shoulderY - 2),
          shoulderNear: Offset(shoulderX, shoulderY),
          shoulderFar: Offset(shoulderX + 4, shoulderY - 2),
          elbowNear: Offset(elbowX, elbowY),
          elbowFar: Offset(elbowX + 4, elbowY - 2),
          wristNear: Offset(handX, handY),
          wristFar: Offset(handX + 4, handY),
          chest: Offset(shoulderX - 4, shoulderY + 8),
          midSpine: Offset((shoulderX + hipX) * 0.5, (shoulderY + hipY) * 0.5),
          hipNear: Offset(hipX, hipY),
          hipFar: Offset(hipX + 4, hipY - 2),
          kneeNear: Offset(cx - 2, groundY - 26),
          kneeFar: Offset(cx + 2, groundY - 26),
          ankleNear: Offset(cx, groundY),
          ankleFar: Offset(cx + 4, groundY),
          footNear: Offset(cx + 12, groundY),
          footFar: Offset(cx + 16, groundY),
          viewMode: KinematicViewMode.side,
          hasDumbbells: true,
          dumbbellNear: Offset(handX, handY),
        );

      case AnatomyExerciseType.tricepsExtension:
        final shoulderY = h * 0.38;
        final elbowX = cx + 2.0;
        final elbowY = h * 0.20;
        // Forearm extends overhead from 90 deg behind head
        final forearmAngle = -1.57 + (1.57 * p); // -90 deg to 0 deg (pointing up)
        const forearmLen = 22.0;
        final handX = elbowX + (forearmLen * math.sin(forearmAngle));
        final handY = elbowY - (forearmLen * math.cos(forearmAngle));

        return AnatomyKinematicJoints(
          head: Offset(cx + 4, h * 0.22),
          neck: Offset(cx + 2, h * 0.30),
          shoulderNear: Offset(cx, shoulderY),
          shoulderFar: Offset(cx + 4, shoulderY - 2),
          elbowNear: Offset(elbowX, elbowY),
          elbowFar: Offset(elbowX + 4, elbowY - 2),
          wristNear: Offset(handX, handY),
          wristFar: Offset(handX + 4, handY),
          chest: Offset(cx + 6, h * 0.40),
          midSpine: Offset(cx, h * 0.49),
          hipNear: Offset(cx - 4, h * 0.58),
          hipFar: Offset(cx, h * 0.58),
          kneeNear: Offset(cx, h * 0.70),
          kneeFar: Offset(cx + 4, h * 0.70),
          ankleNear: Offset(cx, groundY),
          ankleFar: Offset(cx + 4, groundY),
          footNear: Offset(cx + 12, groundY),
          footFar: Offset(cx + 16, groundY),
          viewMode: KinematicViewMode.side,
          hasDumbbells: true,
          dumbbellNear: Offset(handX, handY),
        );

      case AnatomyExerciseType.plank:
        final breath = math.sin(p * math.pi * 2) * 1.5;
        final shoulderX = cx + 24.0;
        final shoulderY = (groundY - 26.0) + breath;
        final footX = cx - 42.0;
        final footY = groundY;
        final hipX = cx - 8.0;
        final hipY = shoulderY + 4.0;

        return AnatomyKinematicJoints(
          head: Offset(shoulderX + 14, shoulderY - 2),
          neck: Offset(shoulderX + 6, shoulderY - 1),
          shoulderNear: Offset(shoulderX, shoulderY),
          shoulderFar: Offset(shoulderX + 4, shoulderY - 2),
          elbowNear: Offset(shoulderX, groundY),
          elbowFar: Offset(shoulderX + 4, groundY),
          wristNear: Offset(shoulderX + 16, groundY),
          wristFar: Offset(shoulderX + 20, groundY),
          chest: Offset(shoulderX - 4, shoulderY + 6),
          midSpine: Offset((shoulderX + hipX) * 0.5, (shoulderY + hipY) * 0.5),
          hipNear: Offset(hipX, hipY),
          hipFar: Offset(hipX + 2, hipY - 2),
          kneeNear: Offset((hipX + footX) * 0.5, (hipY + footY) * 0.5),
          kneeFar: Offset((hipX + footX) * 0.5 + 2, (hipY + footY) * 0.5),
          ankleNear: Offset(footX, footY),
          ankleFar: Offset(footX + 4, footY),
          footNear: Offset(footX - 4, footY),
          footFar: Offset(footX, footY),
          viewMode: KinematicViewMode.side,
        );

      case AnatomyExerciseType.crunch:
        final pelvisX = cx - 14.0;
        final pelvisY = groundY - 6.0;
        final shoulderX = (cx - 36.0) + (14.0 * p);
        final shoulderY = (groundY - 8.0) - (20.0 * p);
        final headX = shoulderX - 10.0;
        final headY = shoulderY - 10.0;

        return AnatomyKinematicJoints(
          head: Offset(headX, headY),
          neck: Offset(shoulderX - 4, shoulderY - 4),
          shoulderNear: Offset(shoulderX, shoulderY),
          shoulderFar: Offset(shoulderX + 4, shoulderY - 2),
          elbowNear: Offset(shoulderX + 8, shoulderY - 12),
          elbowFar: Offset(shoulderX + 12, shoulderY - 10),
          wristNear: Offset(headX + 4, headY - 2),
          wristFar: Offset(headX + 8, headY - 2),
          chest: Offset(shoulderX + 8, shoulderY + 4),
          midSpine: Offset((shoulderX + pelvisX) * 0.5, (shoulderY + pelvisY) * 0.5),
          hipNear: Offset(pelvisX, pelvisY),
          hipFar: Offset(pelvisX + 4, pelvisY - 2),
          kneeNear: Offset(cx + 12, groundY - 28),
          kneeFar: Offset(cx + 16, groundY - 30),
          ankleNear: Offset(cx + 28, groundY),
          ankleFar: Offset(cx + 32, groundY),
          footNear: Offset(cx + 36, groundY),
          footFar: Offset(cx + 40, groundY),
          viewMode: KinematicViewMode.side,
        );

      case AnatomyExerciseType.donkeyKick:
        final hipX = cx - 10.0;
        final hipY = groundY - 28.0;
        final handX = cx + 22.0;
        final handY = groundY;
        final kneeKickX = (hipX - 12.0) - (8.0 * p);
        final kneeKickY = (hipY + 6.0) - (22.0 * p);
        final footKickX = kneeKickX - 4.0;
        final footKickY = kneeKickY - 18.0;

        return AnatomyKinematicJoints(
          head: Offset(cx + 32, groundY - 32),
          neck: Offset(cx + 24, groundY - 28),
          shoulderNear: Offset(handX - 4, groundY - 28),
          shoulderFar: Offset(handX, groundY - 30),
          elbowNear: Offset(handX - 2, groundY - 14),
          elbowFar: Offset(handX + 2, groundY - 14),
          wristNear: Offset(handX, handY),
          wristFar: Offset(handX + 4, handY),
          chest: Offset(cx + 8, groundY - 28),
          midSpine: Offset(cx, groundY - 28),
          hipNear: Offset(hipX, hipY),
          hipFar: Offset(hipX + 4, hipY - 2),
          kneeNear: Offset(kneeKickX, kneeKickY),
          kneeFar: Offset(cx - 8, groundY),
          ankleNear: Offset(footKickX, footKickY),
          ankleFar: Offset(cx - 24, groundY),
          footNear: Offset(footKickX - 2, footKickY - 4),
          footFar: Offset(cx - 26, groundY),
          viewMode: KinematicViewMode.side,
        );

      case AnatomyExerciseType.mountainClimber:
        // Đạp gối so le 2 chân liên tục lệch pha 180 độ (pi)
        // Khi chân gần co về trước sát ngực (driveNear -> 1.0), chân xa duỗi thẳng ra sau (driveFar -> 0.0)
        final driveNear = p;
        final driveFar = 1.0 - p;

        // Nhịp nhún vi mô tự nhiên của hông và cột sống khi chạy trong tư thế Plank
        final hipBounce = math.sin(p * math.pi * 2) * 1.5;

        // Chân gần (Near leg): co đạp liên tục giữa duỗi sau và co ngực
        final kneeNear = Offset.lerp(
          Offset(cx - 24, groundY - 10),
          Offset(cx + 10, groundY - 18),
          driveNear,
        )!;
        final ankleNear = Offset.lerp(
          Offset(cx - 42, groundY - 3),
          Offset(cx - 2, groundY - 6),
          driveNear,
        )!;
        final footNear = Offset.lerp(
          Offset(cx - 44, groundY),
          Offset(cx, groundY - 4),
          driveNear,
        )!;

        // Chân xa (Far leg): lệch pha 180 độ đối nghịch hoàn toàn với chân gần
        final kneeFar = Offset.lerp(
          Offset(cx - 22, groundY - 12),
          Offset(cx + 12, groundY - 20),
          driveFar,
        )!;
        final ankleFar = Offset.lerp(
          Offset(cx - 40, groundY - 5),
          Offset(cx, groundY - 8),
          driveFar,
        )!;
        final footFar = Offset.lerp(
          Offset(cx - 42, groundY - 2),
          Offset(cx + 2, groundY - 6),
          driveFar,
        )!;

        return AnatomyKinematicJoints(
          head: Offset(cx + 36, groundY - 34 + hipBounce * 0.5),
          neck: Offset(cx + 28, groundY - 30 + hipBounce * 0.5),
          shoulderNear: Offset(cx + 22, groundY - 28),
          shoulderFar: Offset(cx + 26, groundY - 30),
          elbowNear: Offset(cx + 22, groundY - 14),
          elbowFar: Offset(cx + 26, groundY - 14),
          wristNear: Offset(cx + 22, groundY),
          wristFar: Offset(cx + 26, groundY),
          chest: Offset(cx + 10, groundY - 26 + hipBounce * 0.7),
          midSpine: Offset(cx, groundY - 24 + hipBounce * 0.9),
          hipNear: Offset(cx - 10, groundY - 22 + hipBounce),
          hipFar: Offset(cx - 8, groundY - 24 + hipBounce),
          kneeNear: kneeNear,
          kneeFar: kneeFar,
          ankleNear: ankleNear,
          ankleFar: ankleFar,
          footNear: footNear,
          footFar: footFar,
          viewMode: KinematicViewMode.side,
        );

      case AnatomyExerciseType.burpee:
        // Burpee 4 pha chuyển động thể hình tiêu chuẩn:
        // Pha 1 (0.0 -> 0.25): Đứng thẳng -> Ngồi xổm hạ trọng tâm chống 2 tay xuống sàn (Squat Drop)
        // Pha 2 (0.25 -> 0.50): Bật 2 chân ra sau duỗi thẳng thành Plank (Thrust to Plank)
        // Pha 3 (0.50 -> 0.75): Bật thu 2 chân về dưới ngực (Tuck back to Squat)
        // Pha 4 (0.75 -> 1.00): Bật nhảy vươn thẳng 2 tay lên trần nhà và tiếp đất mềm (Vertical Jump & Land)

        // Các mốc tư thế cơ sở (Keyframes)
        final standHead = Offset(cx + 4, h * 0.22);
        final standNeck = Offset(cx + 4, h * 0.30);
        final standShoulder = Offset(cx + 4, h * 0.36);
        final standElbow = Offset(cx + 6, h * 0.49);
        final standWrist = Offset(cx + 6, h * 0.62);
        final standChest = Offset(cx + 4, h * 0.42);
        final standSpine = Offset(cx + 2, h * 0.49);
        final standHip = Offset(cx, h * 0.57);
        final standKnee = Offset(cx + 2, h * 0.73);
        final standAnkle = Offset(cx, groundY - 2);
        final standFoot = Offset(cx + 4, groundY);

        final crouchHead = Offset(cx + 24, groundY - 30);
        final crouchNeck = Offset(cx + 18, groundY - 27);
        final crouchShoulder = Offset(cx + 14, groundY - 24);
        final crouchElbow = Offset(cx + 16, groundY - 12);
        final crouchWrist = Offset(cx + 18, groundY);
        final crouchChest = Offset(cx + 10, groundY - 22);
        final crouchSpine = Offset(cx + 2, groundY - 20);
        final crouchHip = Offset(cx - 10, groundY - 18);
        final crouchKnee = Offset(cx + 6, groundY - 14);
        final crouchAnkle = Offset(cx - 6, groundY - 3);
        final crouchFoot = Offset(cx - 2, groundY);

        final plankHead = Offset(cx + 34, groundY - 32);
        final plankNeck = Offset(cx + 26, groundY - 29);
        final plankShoulder = Offset(cx + 18, groundY - 26);
        final plankElbow = Offset(cx + 18, groundY - 13);
        final plankWrist = Offset(cx + 18, groundY);
        final plankChest = Offset(cx + 8, groundY - 24);
        final plankSpine = Offset(cx - 2, groundY - 22);
        final plankHip = Offset(cx - 12, groundY - 20);
        final plankKnee = Offset(cx - 28, groundY - 11);
        final plankAnkle = Offset(cx - 44, groundY - 3);
        final plankFoot = Offset(cx - 46, groundY);

        Offset curHead, curNeck, curShoulder, curElbow, curWrist, curChest, curSpine, curHip, curKnee, curAnkle, curFoot;

        if (p < 0.25) {
          final t = p / 0.25;
          final sT = t * t * (3.0 - 2.0 * t);
          curHead = Offset.lerp(standHead, crouchHead, sT)!;
          curNeck = Offset.lerp(standNeck, crouchNeck, sT)!;
          curShoulder = Offset.lerp(standShoulder, crouchShoulder, sT)!;
          curElbow = Offset.lerp(standElbow, crouchElbow, sT)!;
          curWrist = Offset.lerp(standWrist, crouchWrist, sT)!;
          curChest = Offset.lerp(standChest, crouchChest, sT)!;
          curSpine = Offset.lerp(standSpine, crouchSpine, sT)!;
          curHip = Offset.lerp(standHip, crouchHip, sT)!;
          curKnee = Offset.lerp(standKnee, crouchKnee, sT)!;
          curAnkle = Offset.lerp(standAnkle, crouchAnkle, sT)!;
          curFoot = Offset.lerp(standFoot, crouchFoot, sT)!;
        } else if (p < 0.50) {
          final t = (p - 0.25) / 0.25;
          final sT = t * t * (3.0 - 2.0 * t);
          curHead = Offset.lerp(crouchHead, plankHead, sT)!;
          curNeck = Offset.lerp(crouchNeck, plankNeck, sT)!;
          curShoulder = Offset.lerp(crouchShoulder, plankShoulder, sT)!;
          curElbow = Offset.lerp(crouchElbow, plankElbow, sT)!;
          curWrist = Offset.lerp(crouchWrist, plankWrist, sT)!;
          curChest = Offset.lerp(crouchChest, plankChest, sT)!;
          curSpine = Offset.lerp(crouchSpine, plankSpine, sT)!;
          curHip = Offset.lerp(crouchHip, plankHip, sT)!;
          curKnee = Offset.lerp(crouchKnee, plankKnee, sT)!;
          curAnkle = Offset.lerp(crouchAnkle, plankAnkle, sT)!;
          curFoot = Offset.lerp(crouchFoot, plankFoot, sT)!;
        } else if (p < 0.75) {
          final t = (p - 0.50) / 0.25;
          final sT = t * t * (3.0 - 2.0 * t);
          curHead = Offset.lerp(plankHead, crouchHead, sT)!;
          curNeck = Offset.lerp(plankNeck, crouchNeck, sT)!;
          curShoulder = Offset.lerp(plankShoulder, crouchShoulder, sT)!;
          curElbow = Offset.lerp(plankElbow, crouchElbow, sT)!;
          curWrist = Offset.lerp(plankWrist, crouchWrist, sT)!;
          curChest = Offset.lerp(plankChest, crouchChest, sT)!;
          curSpine = Offset.lerp(plankSpine, crouchSpine, sT)!;
          curHip = Offset.lerp(plankHip, crouchHip, sT)!;
          curKnee = Offset.lerp(plankKnee, crouchKnee, sT)!;
          curAnkle = Offset.lerp(plankAnkle, crouchAnkle, sT)!;
          curFoot = Offset.lerp(plankFoot, crouchFoot, sT)!;
        } else {
          final t = (p - 0.75) / 0.25;
          final jumpHeight = math.sin(t * math.pi) * 28.0;

          final jumpHead = Offset(cx + 4, h * 0.16);
          final jumpNeck = Offset(cx + 4, h * 0.23);
          final jumpShoulder = Offset(cx + 4, h * 0.28);
          final jumpElbow = Offset(cx + 6, h * 0.18);
          final jumpWrist = Offset(cx + 6, h * 0.08);
          final jumpChest = Offset(cx + 4, h * 0.33);
          final jumpSpine = Offset(cx + 2, h * 0.40);
          final jumpHip = Offset(cx, h * 0.48);
          final jumpKnee = Offset(cx + 2, h * 0.63);
          final jumpAnkle = Offset(cx, groundY - 14);
          final jumpFoot = Offset(cx + 4, groundY - 12);

          if (t < 0.5) {
            final sT = (t / 0.5);
            final smoothT = sT * sT * (3.0 - 2.0 * sT);
            curHead = Offset.lerp(crouchHead, jumpHead, smoothT)! - Offset(0, jumpHeight);
            curNeck = Offset.lerp(crouchNeck, jumpNeck, smoothT)! - Offset(0, jumpHeight);
            curShoulder = Offset.lerp(crouchShoulder, jumpShoulder, smoothT)! - Offset(0, jumpHeight);
            curElbow = Offset.lerp(crouchElbow, jumpElbow, smoothT)! - Offset(0, jumpHeight);
            curWrist = Offset.lerp(crouchWrist, jumpWrist, smoothT)! - Offset(0, jumpHeight);
            curChest = Offset.lerp(crouchChest, jumpChest, smoothT)! - Offset(0, jumpHeight);
            curSpine = Offset.lerp(crouchSpine, jumpSpine, smoothT)! - Offset(0, jumpHeight);
            curHip = Offset.lerp(crouchHip, jumpHip, smoothT)! - Offset(0, jumpHeight);
            curKnee = Offset.lerp(crouchKnee, jumpKnee, smoothT)! - Offset(0, jumpHeight);
            curAnkle = Offset.lerp(crouchAnkle, jumpAnkle, smoothT)! - Offset(0, jumpHeight);
            curFoot = Offset.lerp(crouchFoot, jumpFoot, smoothT)! - Offset(0, jumpHeight);
          } else {
            final sT = (t - 0.5) / 0.5;
            final smoothT = sT * sT * (3.0 - 2.0 * sT);
            curHead = Offset.lerp(jumpHead, standHead, smoothT)! - Offset(0, jumpHeight);
            curNeck = Offset.lerp(jumpNeck, standNeck, smoothT)! - Offset(0, jumpHeight);
            curShoulder = Offset.lerp(jumpShoulder, standShoulder, smoothT)! - Offset(0, jumpHeight);
            curElbow = Offset.lerp(jumpElbow, standElbow, smoothT)! - Offset(0, jumpHeight);
            curWrist = Offset.lerp(jumpWrist, standWrist, smoothT)! - Offset(0, jumpHeight);
            curChest = Offset.lerp(jumpChest, standChest, smoothT)! - Offset(0, jumpHeight);
            curSpine = Offset.lerp(jumpSpine, standSpine, smoothT)! - Offset(0, jumpHeight);
            curHip = Offset.lerp(jumpHip, standHip, smoothT)! - Offset(0, jumpHeight);
            curKnee = Offset.lerp(jumpKnee, standKnee, smoothT)! - Offset(0, jumpHeight);
            curAnkle = Offset.lerp(jumpAnkle, standAnkle, smoothT)! - Offset(0, jumpHeight);
            curFoot = Offset.lerp(jumpFoot, standFoot, smoothT)! - Offset(0, jumpHeight);
          }
        }

        return AnatomyKinematicJoints(
          head: curHead,
          neck: curNeck,
          shoulderNear: curShoulder,
          shoulderFar: curShoulder + const Offset(4, -2),
          elbowNear: curElbow,
          elbowFar: curElbow + const Offset(4, -2),
          wristNear: curWrist,
          wristFar: curWrist + const Offset(4, -2),
          chest: curChest,
          midSpine: curSpine,
          hipNear: curHip,
          hipFar: curHip + const Offset(4, -2),
          kneeNear: curKnee,
          kneeFar: curKnee + const Offset(4, -2),
          ankleNear: curAnkle,
          ankleFar: curAnkle + const Offset(4, -2),
          footNear: curFoot,
          footFar: curFoot + const Offset(4, -2),
          viewMode: KinematicViewMode.side,
        );

      case AnatomyExerciseType.yoga:
      case AnatomyExerciseType.general:
      default:
        final wave = math.sin(p * math.pi * 2) * 3.0;
        return AnatomyKinematicJoints(
          head: Offset(cx + 4, h * 0.24 + wave),
          neck: Offset(cx + 2, h * 0.32 + wave),
          shoulderNear: Offset(cx, h * 0.38 + wave),
          shoulderFar: Offset(cx + 4, h * 0.36 + wave),
          elbowNear: Offset(cx + 16, h * 0.50 + wave),
          elbowFar: Offset(cx + 20, h * 0.48 + wave),
          wristNear: Offset(cx + 18, h * 0.62 + wave),
          wristFar: Offset(cx + 22, h * 0.60 + wave),
          chest: Offset(cx + 6, h * 0.42 + wave),
          midSpine: Offset(cx, h * 0.50 + wave),
          hipNear: Offset(cx - 4, h * 0.60),
          hipFar: Offset(cx, h * 0.60),
          kneeNear: Offset(cx + 2, h * 0.71),
          kneeFar: Offset(cx + 6, h * 0.71),
          ankleNear: Offset(cx, groundY),
          ankleFar: Offset(cx + 4, groundY),
          footNear: Offset(cx + 12, groundY),
          footFar: Offset(cx + 16, groundY),
          viewMode: KinematicViewMode.side,
        );
    }
  }

  // ==========================================
  // 2. VẼ MÔ HÌNH GIẢI PHẪU NHÌN NGHIÊNG (SIDE)
  // ==========================================
  void _paintSideAnatomy(
    Canvas canvas,
    Size size,
    AnatomyKinematicJoints joints,
    AnatomyExerciseType type,
  ) {
    // Thứ tự lớp vẽ từ xa tới gần (Depth Layering: Far Limb -> Torso & Pelvis -> Near Limb)
    // 1. Far Leg (Đùi sau & bắp chân xa)
    _drawLimbSegment(canvas, joints.hipFar, joints.kneeFar, 11, 14, 9, 0.2, isFar: true);
    _drawLimbSegment(canvas, joints.kneeFar, joints.ankleFar, 9, 12, 7, 0.2, isFar: true);
    _drawFoot(canvas, joints.ankleFar, joints.footFar, isFar: true);

    // 2. Far Arm
    _drawLimbSegment(canvas, joints.shoulderFar, joints.elbowFar, 9, 11, 8, 0.2, isFar: true);
    _drawLimbSegment(canvas, joints.elbowFar, joints.wristFar, 8, 9, 6, 0.2, isFar: true);

    // 3. Central Core & Torso (Ngực, Xô, Bụng, Mông)
    _drawSideTorsoAndMuscles(canvas, joints, type);

    // 4. Near Leg (Đùi trước Quads & Hamstrings gần)
    final quadAct = getMuscleActivation(progress, type, 'quads');
    final hamAct = getMuscleActivation(progress, type, 'hamstrings');
    final calfAct = getMuscleActivation(progress, type, 'calves_front');

    // Thigh (Quads + Hamstrings)
    _drawLimbSegment(
      canvas,
      joints.hipNear,
      joints.kneeNear,
      isMale ? 14 : 13,
      isMale ? 18 : 17,
      11,
      math.max(quadAct, hamAct),
      isThigh: true,
    );

    // Knee joint pivot
    _drawJointCap(canvas, joints.kneeNear, 4.5, quadAct > 0.6);

    // Shin & Calf (Bắp chuối)
    _drawLimbSegment(
      canvas,
      joints.kneeNear,
      joints.ankleNear,
      11,
      14,
      7,
      calfAct,
      isCalf: true,
    );
    _drawFoot(canvas, joints.ankleNear, joints.footNear, isFar: false);

    // 5. Near Arm (Vai Deltoid, Tay trước Biceps, Tay sau Triceps)
    final deltAct = getMuscleActivation(progress, type, 'shoulders');
    final bicepAct = getMuscleActivation(progress, type, 'biceps');
    final tricepAct = getMuscleActivation(progress, type, 'triceps');

    // Deltoid shoulder cap
    _drawDeltoidCap(canvas, joints.shoulderNear, deltAct);

    // Upper arm
    _drawLimbSegment(
      canvas,
      joints.shoulderNear,
      joints.elbowNear,
      isMale ? 11 : 9.5,
      isMale ? 14 : 12,
      9,
      math.max(bicepAct, tricepAct),
    );
    _drawJointCap(canvas, joints.elbowNear, 3.8, bicepAct > 0.6 || tricepAct > 0.6);

    // Forearm
    _drawLimbSegment(
      canvas,
      joints.elbowNear,
      joints.wristNear,
      9,
      10.5,
      6.5,
      bicepAct * 0.5,
    );
    _drawJointCap(canvas, joints.wristNear, 3.0, false);

    // 6. Head & Cyber Visor
    _drawHead(canvas, joints.head, joints.neck);
  }

  // ==========================================
  // 3. VẼ MÔ HÌNH GIẢI PHẪU CHÍNH DIỆN (FRONT)
  // ==========================================
  void _paintFrontAnatomy(
    Canvas canvas,
    Size size,
    AnatomyKinematicJoints joints,
    AnatomyExerciseType type,
  ) {
    final chestAct = getMuscleActivation(progress, type, 'chest');
    final absAct = getMuscleActivation(progress, type, 'abs');
    final latAct = getMuscleActivation(progress, type, 'lats');
    final deltAct = getMuscleActivation(progress, type, 'shoulders');
    final bicepAct = getMuscleActivation(progress, type, 'biceps');
    final quadAct = getMuscleActivation(progress, type, 'quads');
    final calfAct = getMuscleActivation(progress, type, 'calves_front');

    // 1. Legs (Cặp đùi và bắp chân trước)
    _drawLimbSegment(canvas, joints.hipNear, joints.kneeNear, 13, 17, 10, quadAct, isThigh: true);
    _drawLimbSegment(canvas, joints.hipFar, joints.kneeFar, 13, 17, 10, quadAct, isThigh: true);

    _drawJointCap(canvas, joints.kneeNear, 4.5, quadAct > 0.6);
    _drawJointCap(canvas, joints.kneeFar, 4.5, quadAct > 0.6);

    _drawLimbSegment(canvas, joints.kneeNear, joints.ankleNear, 10, 13.5, 7, calfAct, isCalf: true);
    _drawLimbSegment(canvas, joints.kneeFar, joints.ankleFar, 10, 13.5, 7, calfAct, isCalf: true);

    _drawFoot(canvas, joints.ankleNear, joints.footNear);
    _drawFoot(canvas, joints.ankleFar, joints.footFar);

    // 2. Torso Center, Pectorals, Lats & Abs
    _drawFrontTorso(canvas, joints, chestAct, absAct, latAct);

    // 3. Arms
    _drawDeltoidCap(canvas, joints.shoulderNear, deltAct);
    _drawDeltoidCap(canvas, joints.shoulderFar, deltAct);

    _drawLimbSegment(canvas, joints.shoulderNear, joints.elbowNear, 11, 14, 9, bicepAct);
    _drawLimbSegment(canvas, joints.shoulderFar, joints.elbowFar, 11, 14, 9, bicepAct);

    _drawJointCap(canvas, joints.elbowNear, 3.8, bicepAct > 0.6);
    _drawJointCap(canvas, joints.elbowFar, 3.8, bicepAct > 0.6);

    _drawLimbSegment(canvas, joints.elbowNear, joints.wristNear, 9, 10.5, 6.5, bicepAct * 0.5);
    _drawLimbSegment(canvas, joints.elbowFar, joints.wristFar, 9, 10.5, 6.5, bicepAct * 0.5);

    _drawJointCap(canvas, joints.wristNear, 3.0, false);
    _drawJointCap(canvas, joints.wristFar, 3.0, false);

    // 4. Head & Visor
    _drawHead(canvas, joints.head, joints.neck);
  }

  // ==========================================
  // 4. THÂN TRÊN & CÁC KHỐI CƠ ĐỘNG HỌC
  // ==========================================
  void _drawSideTorsoAndMuscles(
    Canvas canvas,
    AnatomyKinematicJoints joints,
    AnatomyExerciseType type,
  ) {
    final chestAct = getMuscleActivation(progress, type, 'chest');
    final absAct = getMuscleActivation(progress, type, 'abs');
    final gluteAct = getMuscleActivation(progress, type, 'glutes');
    final latsAct = getMuscleActivation(progress, type, 'lats');

    final basePaint = _getMusclePaint(math.max(chestAct, absAct), isFar: false);
    final outlinePaint = _getStrokePaint(math.max(chestAct, absAct));

    // Thân mình góc nghiêng (Torso profile polygon)
    final torsoPath = Path()
      ..moveTo(joints.neck.dx, joints.neck.dy)
      ..lineTo(joints.chest.dx + (isMale ? 10 : 8), joints.chest.dy)
      ..quadraticBezierTo(joints.chest.dx + (isMale ? 12 : 9), joints.chest.dy + 8, joints.midSpine.dx + 6, joints.midSpine.dy)
      ..lineTo(joints.hipNear.dx + 4, joints.hipNear.dy)
      ..lineTo(joints.hipNear.dx - 8, joints.hipNear.dy)
      ..lineTo(joints.midSpine.dx - 8, joints.midSpine.dy)
      ..lineTo(joints.shoulderNear.dx - 6, joints.shoulderNear.dy)
      ..close();

    canvas.drawPath(torsoPath, basePaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // Khối Cơ Mông (Gluteus Maximus - Peach Muscle)
    _drawSideGlute(canvas, joints.hipNear, gluteAct);

    // Tấm Ngực Nghiêng (Pectoral shelf)
    if (chestAct > 0.25) {
      final chestGlow = Paint()
        ..color = themeColor.withValues(alpha: 0.35 * chestAct)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..style = PaintingStyle.fill;
      final chestPath = Path()
        ..moveTo(joints.neck.dx, joints.neck.dy + 2)
        ..lineTo(joints.chest.dx + 11, joints.chest.dy + 2)
        ..lineTo(joints.chest.dx + 5, joints.chest.dy + 16)
        ..lineTo(joints.midSpine.dx, joints.midSpine.dy)
        ..close();
      canvas.drawPath(chestPath, chestGlow);
    }

    // Cơ bụng siết (Abs groove lines in side view)
    final abLinePaint = Paint()
      ..color = absAct > 0.4 ? themeColor : Colors.white24
      ..strokeWidth = absAct > 0.6 ? 2.0 : 1.2
      ..style = PaintingStyle.stroke;

    final abCenter = (joints.chest + joints.hipNear) * 0.5;
    canvas.drawLine(abCenter + const Offset(1, -6), abCenter + const Offset(7, -6), abLinePaint);
    canvas.drawLine(abCenter + const Offset(2, 0), abCenter + const Offset(8, 0), abLinePaint);
    canvas.drawLine(abCenter + const Offset(1, 6), abCenter + const Offset(7, 6), abLinePaint);

    if (absAct > 0.6) {
      final abGlow = Paint()
        ..color = themeColor.withValues(alpha: 0.4 * absAct)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(abCenter + const Offset(4, 0), 10, abGlow);
    }

    // Xô lưng (Lats profile)
    if (latsAct > 0.3) {
      final latsPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.35 * latsAct)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final latsPath = Path()
        ..moveTo(joints.shoulderNear.dx - 4, joints.shoulderNear.dy)
        ..lineTo(joints.midSpine.dx - 8, joints.midSpine.dy)
        ..lineTo(joints.midSpine.dx - 2, joints.midSpine.dy + 12)
        ..lineTo(joints.shoulderNear.dx + 2, joints.shoulderNear.dy + 10)
        ..close();
      canvas.drawPath(latsPath, latsPaint);
    }
  }

  void _drawFrontTorso(
    Canvas canvas,
    AnatomyKinematicJoints joints,
    double chestAct,
    double absAct,
    double latsAct,
  ) {
    final cx = (joints.shoulderNear.dx + joints.shoulderFar.dx) * 0.5;
    final shoulderW = (joints.shoulderFar.dx - joints.shoulderNear.dx).abs();

    // Thân chính (Front Torso V-Taper / Hourglass)
    final torsoPath = Path()
      ..moveTo(joints.neck.dx - 6, joints.neck.dy)
      ..lineTo(joints.shoulderNear.dx, joints.shoulderNear.dy)
      ..lineTo(joints.shoulderNear.dx + 2, joints.chest.dy + 8) // Armpit
      ..quadraticBezierTo(cx - (isMale ? 14 : 11), joints.midSpine.dy, joints.hipNear.dx, joints.hipNear.dy)
      ..lineTo(joints.hipFar.dx, joints.hipFar.dy)
      ..quadraticBezierTo(cx + (isMale ? 14 : 11), joints.midSpine.dy, joints.shoulderFar.dx - 2, joints.chest.dy + 8)
      ..lineTo(joints.shoulderFar.dx, joints.shoulderFar.dy)
      ..lineTo(joints.neck.dx + 6, joints.neck.dy)
      ..close();

    final basePaint = _getMusclePaint(math.max(chestAct, absAct), isFar: false);
    final outlinePaint = _getStrokePaint(math.max(chestAct, absAct));
    canvas.drawPath(torsoPath, basePaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // Cơ ngực đôi (Left & Right Pectoralis Plates)
    final chestY = joints.chest.dy;
    final plateW = (shoulderW * 0.38);
    final leftChest = Path()
      ..moveTo(cx - 2, chestY - 10)
      ..lineTo(cx - plateW, chestY - 10)
      ..quadraticBezierTo(cx - plateW - 2, chestY + 8, cx - (plateW * 0.5), chestY + 12)
      ..quadraticBezierTo(cx - 4, chestY + 13, cx - 2, chestY + 11)
      ..close();

    final rightChest = Path()
      ..moveTo(cx + 2, chestY - 10)
      ..lineTo(cx + plateW, chestY - 10)
      ..quadraticBezierTo(cx + plateW + 2, chestY + 8, cx + (plateW * 0.5), chestY + 12)
      ..quadraticBezierTo(cx + 4, chestY + 13, cx + 2, chestY + 11)
      ..close();

    final chestPaint = _getMusclePaint(chestAct, isFar: false);
    final chestStroke = _getStrokePaint(chestAct);

    if (chestAct > 0.6) {
      final glow = Paint()
        ..color = themeColor.withValues(alpha: 0.45 * chestAct)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(leftChest, glow);
      canvas.drawPath(rightChest, glow);
    }

    canvas.drawPath(leftChest, chestPaint);
    canvas.drawPath(rightChest, chestPaint);
    canvas.drawPath(leftChest, chestStroke);
    canvas.drawPath(rightChest, chestStroke);

    // Cơ bụng (Abs: 6 múi Nam hoặc số 11 Nữ)
    if (isMale) {
      // 6 múi Nam vạm vỡ
      final absPaint = _getMusclePaint(absAct, isFar: false);
      final absStroke = _getStrokePaint(absAct);

      for (int row = 0; row < 3; row++) {
        final rowY = joints.midSpine.dy - 10 + (row * 10.0);
        final leftAb = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 10, rowY, 8.5, 8.0),
          const Radius.circular(2.5),
        );
        final rightAb = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 1.5, rowY, 8.5, 8.0),
          const Radius.circular(2.5),
        );

        if (absAct > 0.65) {
          final abGlow = Paint()
            ..color = themeColor.withValues(alpha: 0.35 * absAct)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawRRect(leftAb, abGlow);
          canvas.drawRRect(rightAb, abGlow);
        }

        canvas.drawRRect(leftAb, absPaint);
        canvas.drawRRect(rightAb, absPaint);
        canvas.drawRRect(leftAb, absStroke);
        canvas.drawRRect(rightAb, absStroke);
      }
    } else {
      // Bụng số 11 Nữ thanh thoát
      final groovePaint = Paint()
        ..color = absAct > 0.4 ? themeColor : Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = absAct > 0.6 ? 2.0 : 1.2
        ..style = PaintingStyle.stroke;

      // Đường rãnh giữa Linea Alba
      canvas.drawLine(
        Offset(cx, joints.midSpine.dy - 12),
        Offset(cx, joints.hipNear.dy - 4),
        groovePaint,
      );

      // Hai đường rãnh số 11 hai bên
      final abLineLeft = Path()
        ..moveTo(cx - 7, joints.midSpine.dy - 8)
        ..lineTo(cx - 6, joints.midSpine.dy + 12);
      final abLineRight = Path()
        ..moveTo(cx + 7, joints.midSpine.dy - 8)
        ..lineTo(cx + 6, joints.midSpine.dy + 12);

      if (absAct > 0.6) {
        final glow = Paint()
          ..color = themeColor.withValues(alpha: 0.45 * absAct)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(Offset(cx, joints.midSpine.dy), 10, glow);
      }

      canvas.drawPath(abLineLeft, groovePaint);
      canvas.drawPath(abLineRight, groovePaint);
    }
  }

  // ==========================================
  // 5. CƠ MÔNG QUẢ ĐÀO (GLUTEUS MAXIMUS)
  // ==========================================
  void _drawSideGlute(Canvas canvas, Offset hip, double activation) {
    // Độ nở cong của cơ mông: Nữ cong tròn quả đào hơn, Nam săn chắc
    final gluteRadius = isMale ? 14.0 : 18.5;
    final pump = activation * (isMale ? 2.5 : 4.0);

    final glutePath = Path()
      ..moveTo(hip.dx + 2, hip.dy - 8)
      ..quadraticBezierTo(
        hip.dx - gluteRadius - pump,
        hip.dy,
        hip.dx - (gluteRadius * 0.7) - pump,
        hip.dy + 14,
      )
      ..quadraticBezierTo(hip.dx - 2, hip.dy + 16, hip.dx + 2, hip.dy + 6)
      ..close();

    final glutePaint = _getMusclePaint(activation, isFar: false);
    final gluteStroke = _getStrokePaint(activation);

    if (activation > 0.5) {
      final gluteGlow = Paint()
        ..color = themeColor.withValues(alpha: 0.45 * activation)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(glutePath, gluteGlow);
    }

    canvas.drawPath(glutePath, glutePaint);
    canvas.drawPath(glutePath, gluteStroke);
  }

  // ==========================================
  // 6. KHỐI CƠ CHI (LIMB SEGMENT WITH ANATOMY)
  // ==========================================
  void _drawLimbSegment(
    Canvas canvas,
    Offset p1,
    Offset p2,
    double wStart,
    double wMid,
    double wEnd,
    double activation, {
    bool isFar = false,
    bool isThigh = false,
    bool isCalf = false,
  }) {
    final diff = p2 - p1;
    final length = diff.distance;
    if (length < 1.0) return;

    final unit = diff / length;
    final normal = Offset(-unit.dy, unit.dx);

    // Hypertrophic pump on activation
    final pump = activation * 3.5;
    final effMid = wMid + pump;

    final halfStart = wStart * 0.5;
    final halfMid = effMid * 0.5;
    final halfEnd = wEnd * 0.5;

    final path = Path();
    // Start side 1
    path.moveTo(p1.dx + normal.dx * halfStart, p1.dy + normal.dy * halfStart);
    // Outer muscle bulge
    path.quadraticBezierTo(
      p1.dx + diff.dx * 0.45 + normal.dx * halfMid,
      p1.dy + diff.dy * 0.45 + normal.dy * halfMid,
      p2.dx + normal.dx * halfEnd,
      p2.dy + normal.dy * halfEnd,
    );
    // Ankle / joint end cap
    path.lineTo(p2.dx - normal.dx * halfEnd, p2.dy - normal.dy * halfEnd);
    // Inner muscle contour
    path.quadraticBezierTo(
      p1.dx + diff.dx * 0.55 - normal.dx * (halfMid * (isCalf ? 0.7 : 0.9)),
      p1.dy + diff.dy * 0.55 - normal.dy * (halfMid * (isCalf ? 0.7 : 0.9)),
      p1.dx - normal.dx * halfStart,
      p1.dy - normal.dy * halfStart,
    );
    path.close();

    final paint = _getMusclePaint(activation, isFar: isFar);
    final stroke = _getStrokePaint(activation, isFar: isFar);

    if (activation > 0.6 && !isFar) {
      final glow = Paint()
        ..color = themeColor.withValues(alpha: 0.45 * activation)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(path, glow);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
  }

  void _drawDeltoidCap(Canvas canvas, Offset shoulder, double activation) {
    final capRadius = isMale ? 7.5 : 6.0;
    final pump = activation * 2.0;

    final capPaint = _getMusclePaint(activation, isFar: false);
    final capStroke = _getStrokePaint(activation);

    if (activation > 0.6) {
      final glow = Paint()
        ..color = themeColor.withValues(alpha: 0.5 * activation)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(shoulder, capRadius + pump + 2, glow);
    }

    canvas.drawCircle(shoulder, capRadius + pump, capPaint);
    canvas.drawCircle(shoulder, capRadius + pump, capStroke);
  }

  void _drawJointCap(Canvas canvas, Offset joint, double radius, bool isGlowing) {
    final jointFill = Paint()
      ..color = isGlowing ? Colors.white : themeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final jointRing = Paint()
      ..color = themeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    if (isGlowing) {
      final glow = Paint()
        ..color = themeColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(joint, radius + 2, glow);
    }

    canvas.drawCircle(joint, radius, jointFill);
    canvas.drawCircle(joint, radius, jointRing);
  }

  void _drawFoot(Canvas canvas, Offset ankle, Offset toe, {bool isFar = false}) {
    final footPaint = Paint()
      ..color = isFar ? const Color(0xFF0A101C) : (isMale ? const Color(0xFF0F172A) : const Color(0xFF190D1C))
      ..style = PaintingStyle.fill;
    final strokePaint = _getStrokePaint(0.0, isFar: isFar);

    final path = Path()
      ..moveTo(ankle.dx - 4, ankle.dy)
      ..lineTo(toe.dx, toe.dy)
      ..lineTo(toe.dx - 2, toe.dy + 4)
      ..lineTo(ankle.dx - 6, ankle.dy + 4)
      ..close();

    canvas.drawPath(path, footPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawHead(Canvas canvas, Offset head, Offset neck) {
    // Cổ
    final neckPaint = Paint()
      ..color = isMale ? const Color(0xFF0F172A) : const Color(0xFF190D1C)
      ..style = PaintingStyle.fill;
    final neckPath = Path()
      ..moveTo(neck.dx - (isMale ? 5 : 4), neck.dy + 4)
      ..lineTo(head.dx - (isMale ? 4 : 3), head.dy + 6)
      ..lineTo(head.dx + (isMale ? 4 : 3), head.dy + 6)
      ..lineTo(neck.dx + (isMale ? 5 : 4), neck.dy + 4)
      ..close();
    canvas.drawPath(neckPath, neckPaint);

    // Đầu / Mũ giải phẫu Holographic
    final headRect = Rect.fromCenter(center: head, width: isMale ? 18 : 15.5, height: isMale ? 22 : 19.5);
    final headPaint = Paint()
      ..color = isMale ? const Color(0xFF0D1B2A) : const Color(0xFF220D22)
      ..style = PaintingStyle.fill;
    final headStroke = Paint()
      ..color = themeColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawOval(headRect, headPaint);
    canvas.drawOval(headRect, headStroke);

    // Kính bảo hộ Cyber Visor phát sáng
    final visorPaint = Paint()
      ..color = themeColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final visorGlow = Paint()
      ..color = themeColor.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final visorP1 = Offset(head.dx + 2, head.dy - 1);
    final visorP2 = Offset(head.dx + (isMale ? 8 : 7), head.dy);
    canvas.drawLine(visorP1, visorP2, visorGlow);
    canvas.drawLine(visorP1, visorP2, visorPaint);
  }

  // ==========================================
  // 7. VẼ MÔI TRƯỜNG & THIẾT BỊ (EQUIPMENT)
  // ==========================================
  void _drawEnvironment(
    Canvas canvas,
    Size size,
    AnatomyKinematicJoints joints,
    AnatomyExerciseType type,
  ) {
    final groundY = size.height * 0.79;

    // Sàn lưới Holographic Grid
    final floorLinePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width * 0.08, groundY), Offset(size.width * 0.92, groundY), floorLinePaint);

    final glowFloor = Paint()
      ..color = themeColor.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, groundY - 1, size.width * 0.70, 3), glowFloor);

    // Vạch vi mô phản xạ sàn
    for (int i = 0; i < 7; i++) {
      final gx = size.width * (0.2 + i * 0.1);
      canvas.drawLine(Offset(gx, groundY), Offset(gx - 6, groundY + 8), floorLinePaint);
    }

    // Ghế tập Holographic Bench
    if (joints.hasBench && joints.benchRect != null) {
      final bench = joints.benchRect!;
      final benchPaint = Paint()
        ..color = const Color(0xFF1E293B).withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      final benchStroke = Paint()
        ..color = themeColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(RRect.fromRectAndRadius(bench, const Radius.circular(4)), benchPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(bench, const Radius.circular(4)), benchStroke);
    }

    // Thanh xà đơn (Pull-up Bar)
    if (joints.hasPullUpBar && joints.pullUpBarY != null) {
      final barY = joints.pullUpBarY!;
      final barPaint = Paint()
        ..color = Colors.white70
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;
      final barGlow = Paint()
        ..color = themeColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawLine(Offset(size.width * 0.18, barY), Offset(size.width * 0.82, barY), barGlow);
      canvas.drawLine(Offset(size.width * 0.18, barY), Offset(size.width * 0.82, barY), barPaint);

      // Điểm bám tay phát sáng
      canvas.drawCircle(Offset(size.width * 0.5 - 38, barY), 4, Paint()..color = themeColor);
      canvas.drawCircle(Offset(size.width * 0.5 + 38, barY), 4, Paint()..color = themeColor);
    }
  }

  void _drawEquipmentOverlay(
    Canvas canvas,
    Size size,
    AnatomyKinematicJoints joints,
  ) {
    if (joints.hasDumbbells) {
      if (joints.dumbbellNear != null) {
        _drawNeonDumbbell(canvas, joints.dumbbellNear!);
      }
      if (joints.dumbbellFar != null && joints.viewMode == KinematicViewMode.front) {
        _drawNeonDumbbell(canvas, joints.dumbbellFar!);
      }
    }
  }

  void _drawNeonDumbbell(Canvas canvas, Offset center) {
    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final platePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final plateRing = Paint()
      ..color = themeColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Tay cầm tạ
    canvas.drawLine(center - const Offset(9, 0), center + const Offset(9, 0), barPaint);

    // Hai bánh tạ hai đầu
    final plate1 = RRect.fromRectAndRadius(Rect.fromCenter(center: center - const Offset(9, 0), width: 4.5, height: 16), const Radius.circular(2));
    final plate2 = RRect.fromRectAndRadius(Rect.fromCenter(center: center + const Offset(9, 0), width: 4.5, height: 16), const Radius.circular(2));

    canvas.drawRRect(plate1, platePaint);
    canvas.drawRRect(plate2, platePaint);
    canvas.drawRRect(plate1, plateRing);
    canvas.drawRRect(plate2, plateRing);
  }

  // ==========================================
  // VỆT QUỸ ĐẠO CHUYỂN ĐỘNG MỜ (MOTION TRAILS / TRAJECTORY)
  // ==========================================
  void _drawMotionTrails(
    Canvas canvas,
    Size size,
    AnatomyKinematicJoints joints,
    AnatomyExerciseType type,
  ) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final groundY = h * 0.79;

    final trailColor = themeColor.withValues(alpha: 0.60);
    final glowColor = themeColor.withValues(alpha: 0.22);

    final glowPaint = Paint()
      ..color = glowColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final dashPaint = Paint()
      ..color = trailColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final markerFill = Paint()
      ..color = themeColor
      ..style = PaintingStyle.fill;
    final markerGlow = Paint()
      ..color = themeColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final List<Path> paths = [];
    final List<Offset> currentPoints = [];

    switch (type) {
      case AnatomyExerciseType.bicepCurl:
        // Cung đường cuốn tạ vòng cung quanh khớp khuỷu tay
        final elbowY = h * 0.52;
        final elbowXLeft = cx - 20.0;
        final elbowXRight = cx + 20.0;
        final forearmLength = h * 0.22;

        final pathLeft = Path();
        final pathRight = Path();
        for (int i = 0; i <= 20; i++) {
          final t = i / 20.0;
          final angle = 0.15 + (1.75 * t);
          final pXLeft = elbowXLeft + (forearmLength * 0.55 * math.sin(angle));
          final pYLeft = elbowY + (forearmLength * math.cos(angle));
          final pXRight = elbowXRight - (forearmLength * 0.55 * math.sin(angle));
          final pYRight = elbowY + (forearmLength * math.cos(angle));
          if (i == 0) {
            pathLeft.moveTo(pXLeft, pYLeft);
            pathRight.moveTo(pXRight, pYRight);
          } else {
            pathLeft.lineTo(pXLeft, pYLeft);
            pathRight.lineTo(pXRight, pYRight);
          }
        }
        paths.addAll([pathLeft, pathRight]);
        if (joints.dumbbellNear != null) currentPoints.add(joints.dumbbellNear!);
        if (joints.dumbbellFar != null) currentPoints.add(joints.dumbbellFar!);
        break;

      case AnatomyExerciseType.lateralRaise:
        // Cung đường dang tạ vòng cung từ hông ra hai bên vai
        final shoulderY = h * 0.38;
        final armLength = h * 0.26;
        final pathLeft = Path();
        final pathRight = Path();
        for (int i = 0; i <= 20; i++) {
          final t = i / 20.0;
          final angle = (math.pi * 0.5) * (1.0 - t);
          final pXLeft = (cx - 24) - (armLength * math.cos(angle));
          final pYLeft = shoulderY + (armLength * math.sin(angle));
          final pXRight = (cx + 24) + (armLength * math.cos(angle));
          final pYRight = shoulderY + (armLength * math.sin(angle));
          if (i == 0) {
            pathLeft.moveTo(pXLeft, pYLeft);
            pathRight.moveTo(pXRight, pYRight);
          } else {
            pathLeft.lineTo(pXLeft, pYLeft);
            pathRight.lineTo(pXRight, pYRight);
          }
        }
        paths.addAll([pathLeft, pathRight]);
        if (joints.dumbbellNear != null) currentPoints.add(joints.dumbbellNear!);
        if (joints.dumbbellFar != null) currentPoints.add(joints.dumbbellFar!);
        break;

      case AnatomyExerciseType.shoulderPress:
        // Quỹ đạo đẩy tạ thẳng đứng qua đầu
        final pathLeft = Path()
          ..moveTo(cx - 28, h * 0.33)
          ..lineTo(cx - 14, h * 0.16);
        final pathRight = Path()
          ..moveTo(cx + 28, h * 0.33)
          ..lineTo(cx + 14, h * 0.16);
        paths.addAll([pathLeft, pathRight]);
        if (joints.dumbbellNear != null) currentPoints.add(joints.dumbbellNear!);
        if (joints.dumbbellFar != null) currentPoints.add(joints.dumbbellFar!);
        break;

      case AnatomyExerciseType.squat:
        // Quỹ đạo đường Bar Path thẳng đứng chuẩn vật lý trên vai/lưng
        final squatPath = Path()
          ..moveTo(cx - 6, h * 0.40)
          ..lineTo(cx - 6, h * 0.54);
        paths.add(squatPath);
        currentPoints.add(joints.shoulderNear);
        break;

      case AnatomyExerciseType.benchPress:
        // Quỹ đạo tạ đẩy ngực thẳng đứng chuẩn an toàn
        final benchPath = Path()
          ..moveTo(cx - 6, groundY - 32)
          ..lineTo(cx - 6, groundY - 56);
        paths.add(benchPath);
        if (joints.dumbbellNear != null) currentPoints.add(joints.dumbbellNear!);
        break;

      default:
        return;
    }

    // Vẽ cung đường phát sáng và nét đứt
    for (final p in paths) {
      canvas.drawPath(p, glowPaint);
      _drawDashedPath(canvas, p, dashPaint, dashWidth: 4.5, dashSpace: 3.5);
    }

    // Điểm chỉ báo vị trí tạ / mốc khớp hiện tại
    for (final pt in currentPoints) {
      canvas.drawCircle(pt, 5.0, markerGlow);
      canvas.drawCircle(pt, 2.5, markerFill);
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dashWidth = 5.0,
    double dashSpace = 4.0,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extractLength = math.min(dashWidth, metric.length - distance);
        final subPath = metric.extractPath(distance, distance + extractLength);
        canvas.drawPath(subPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  // ==========================================
  // 8. BẢNG HUD THÔNG SỐ KÍCH HOẠT CƠ
  // ==========================================
  void _drawMuscleActivationHUD(Canvas canvas, Size size, AnatomyExerciseType type) {
    final primary = getPrimaryMuscleId(type);
    final act = getMuscleActivation(progress, type, primary);
    final pct = (act * 100).toInt();

    // Tên cơ hiển thị
    String muscleLabel;
    switch (primary) {
      case 'quads':
        muscleLabel = 'CƠ ĐÙI TRƯỚC (QUADS)';
        break;
      case 'glutes':
        muscleLabel = 'CƠ MÔNG (GLUTES)';
        break;
      case 'hamstrings':
        muscleLabel = 'CƠ ĐÙI SAU (HAMSTRINGS)';
        break;
      case 'chest':
        muscleLabel = 'CƠ NGỰC (PECTORALS)';
        break;
      case 'lats':
        muscleLabel = 'LƯNG XÔ (LATS)';
        break;
      case 'shoulders':
        muscleLabel = 'CƠ VAI (DELTOIDS)';
        break;
      case 'triceps':
        muscleLabel = 'TAY SAU (TRICEPS)';
        break;
      case 'biceps':
        muscleLabel = 'TAY TRƯỚC (BICEPS)';
        break;
      case 'abs':
        muscleLabel = 'CƠ BỤNG (CORE / ABS)';
        break;
      case 'calves_front':
      case 'calves_back':
        muscleLabel = 'BẮP CHÂN (CALVES)';
        break;
      default:
        muscleLabel = 'TOÀN THÂN (FULL BODY)';
    }

    // Badge HUD góc trên bên phải
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '⚡ $muscleLabel: ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          TextSpan(
            text: '$pct%',
            style: TextStyle(
              color: themeColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = Rect.fromLTWH(
      size.width - textPainter.width - 24,
      10,
      textPainter.width + 16,
      20,
    );

    final badgeBg = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final badgeBorder = Paint()
      ..color = themeColor.withValues(alpha: 0.4 + 0.5 * act)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)), badgeBg);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)), badgeBorder);

    textPainter.paint(canvas, Offset(badgeRect.left + 8, badgeRect.top + 4.5));
  }

  // ==========================================
  // HELPER PAINTS
  // ==========================================
  Paint _getMusclePaint(double activation, {required bool isFar}) {
    if (isFar) {
      return Paint()
        ..color = isMale ? const Color(0xFF08101E) : const Color(0xFF130917)
        ..style = PaintingStyle.fill;
    }

    if (activation > 0.35) {
      // Dynamic Glowing Shader on peak contraction
      final actFactor = ((activation - 0.35) / 0.65).clamp(0.0, 1.0);
      final alpha = 0.20 + (0.75 * actFactor);

      return Paint()
        ..shader = LinearGradient(
          colors: [
            themeColor.withValues(alpha: alpha),
            themeColorSecondary.withValues(alpha: alpha * 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 300, 300))
        ..style = PaintingStyle.fill;
    }

    // Stealth anatomical dark slate
    return Paint()
      ..color = isMale ? const Color(0xFF0F172A) : const Color(0xFF190D1C)
      ..style = PaintingStyle.fill;
  }

  Paint _getStrokePaint(double activation, {bool isFar = false}) {
    if (isFar) {
      return Paint()
        ..color = themeColor.withValues(alpha: 0.12)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
    }

    if (activation > 0.4) {
      final actFactor = ((activation - 0.4) / 0.6).clamp(0.0, 1.0);
      return Paint()
        ..color = Color.lerp(themeColor.withValues(alpha: 0.4), Colors.white, actFactor * 0.6)!
        ..strokeWidth = 1.2 + (1.2 * actFactor)
        ..style = PaintingStyle.stroke;
    }

    return Paint()
      ..color = themeColor.withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant AnatomyKinematicPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.exerciseTitle != exerciseTitle ||
        oldDelegate.isMale != isMale ||
        oldDelegate.customThemeColor != customThemeColor;
  }
}
