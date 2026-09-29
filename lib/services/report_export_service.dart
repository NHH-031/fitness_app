import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/body_measurement_repository.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';

class ReportExportService {
  ReportExportService._();
  static final ReportExportService instance = ReportExportService._();

  /// Tổng hợp và tạo văn bản báo cáo 30 ngày chi tiết
  Future<String> generate30DayReportText() async {
    final profile = await StorageService.getUserProfile();
    final latestMeasurement = await BodyMeasurementRepository.instance.getLatestMeasurement();
    final allWorkouts = await WorkoutRepository.instance.getWorkoutLogs();
    final allFoods = await NutritionRepository.instance.getFoodLogs();

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Lọc workout 30 ngày qua
    final recentWorkouts = allWorkouts.where((w) {
      final ts = DateTime.tryParse(w['timestamp']?.toString() ?? '');
      return ts != null && ts.isAfter(thirtyDaysAgo);
    }).toList();

    // Lọc food logs 30 ngày qua
    final recentFoods = allFoods.where((f) => f.timestamp.isAfter(thirtyDaysAgo)).toList();

    // Thống kê bài tập
    final totalWorkoutCount = recentWorkouts.length;
    final totalWorkoutMinutes = recentWorkouts.fold<int>(
      0,
      (sum, w) => sum + ((w['duration'] as num?)?.toInt() ?? 0),
    );
    final totalWorkoutCalories = recentWorkouts.fold<int>(
      0,
      (sum, w) => sum + ((w['calories'] as num?)?.toInt() ?? 0),
    );

    // Thống kê dinh dưỡng
    final daysLogged = recentFoods
        .map((f) => '${f.timestamp.year}-${f.timestamp.month}-${f.timestamp.day}')
        .toSet()
        .length;
    final divisor = daysLogged > 0 ? daysLogged : 1;
    final totalFoodCalories = recentFoods.fold<int>(0, (sum, f) => sum + f.calories);
    final avgDailyCalories = (totalFoodCalories / divisor).round();
    final avgProtein = (recentFoods.fold<double>(0.0, (sum, f) => sum + f.protein) / divisor).round();
    final avgCarbs = (recentFoods.fold<double>(0.0, (sum, f) => sum + f.carbs) / divisor).round();
    final avgFat = (recentFoods.fold<double>(0.0, (sum, f) => sum + f.fat) / divisor).round();

    // Ước tính body fat nếu có số đo
    double? bodyFatPercent = latestMeasurement?.bodyFatPercent;
    String bodyFatCategory = '';
    if (bodyFatPercent != null) {
      bodyFatCategory = UserMetricsService.getBodyFatCategory(
        bodyFatPercent,
        gender: profile.gender,
      );
    } else if (latestMeasurement?.waistCm != null && latestMeasurement?.neckCm != null) {
      bodyFatPercent = UserMetricsService.calculateBodyFatPercent(
        waistCm: latestMeasurement!.waistCm!,
        neckCm: latestMeasurement.neckCm!,
        heightCm: profile.height,
        hipsCm: latestMeasurement.hipsCm,
        gender: profile.gender,
      );
      bodyFatCategory = UserMetricsService.getBodyFatCategory(
        bodyFatPercent,
        gender: profile.gender,
      );
    }

    final isVi = LocaleService.isVietnamese;
    final buffer = StringBuffer();

    buffer.writeln('====================================================');
    buffer.writeln(isVi
        ? '🏋️ FITNESS TRACKER - BÁO CÁO THỂ HÌNH & DINH DƯỠNG (30 NGÀY)'
        : '🏋️ FITNESS TRACKER - HEALTH & FITNESS REPORT (LAST 30 DAYS)');
    buffer.writeln('====================================================\n');

    // 1. Hồ sơ người dùng
    buffer.writeln(isVi ? '👤 1. HỒ SƠ HỘI VIÊN:' : '👤 1. USER PROFILE:');
    buffer.writeln(isVi ? '- Họ và tên: ${profile.name}' : '- Name: ${profile.name}');
    buffer.writeln(isVi
        ? '- Chiều cao: ${profile.height} cm | Cân nặng: ${profile.weight} kg'
        : '- Height: ${profile.height} cm | Weight: ${profile.weight} kg');
    buffer.writeln('- BMI: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})');
    buffer.writeln(isVi ? '- Mục tiêu: ${profile.fitnessGoal.toUpperCase()}' : '- Goal: ${profile.fitnessGoal.toUpperCase()}');
    buffer.writeln('- BMR: ${profile.bmr.round()} kcal | TDEE: ${profile.tdee.round()} kcal\n');

    // 2. Số đo hình thể & Mỡ US Navy
    buffer.writeln(isVi ? '📏 2. TIẾN TRÌNH SỐ ĐO & % MỠ CƠ THỂ:' : '📏 2. BODY COMPOSITION & US NAVY BODY FAT:');
    if (bodyFatPercent != null && bodyFatPercent > 0) {
      buffer.writeln(isVi
          ? '- % Mỡ cơ thể (US Navy): $bodyFatPercent% ($bodyFatCategory)'
          : '- Body Fat (US Navy): $bodyFatPercent% ($bodyFatCategory)');
    }
    if (latestMeasurement != null) {
      buffer.writeln(isVi ? '- Ngày cập nhật số đo: ${latestMeasurement.date}' : '- Measurement date: ${latestMeasurement.date}');
      if (latestMeasurement.waistCm != null) buffer.writeln(isVi ? '  + Vòng eo: ${latestMeasurement.waistCm} cm' : '  + Waist: ${latestMeasurement.waistCm} cm');
      if (latestMeasurement.chestCm != null) buffer.writeln(isVi ? '  + Vòng ngực: ${latestMeasurement.chestCm} cm' : '  + Chest: ${latestMeasurement.chestCm} cm');
      if (latestMeasurement.hipsCm != null) buffer.writeln(isVi ? '  + Vòng mông: ${latestMeasurement.hipsCm} cm' : '  + Hips: ${latestMeasurement.hipsCm} cm');
      if (latestMeasurement.neckCm != null) buffer.writeln(isVi ? '  + Vòng cổ: ${latestMeasurement.neckCm} cm' : '  + Neck: ${latestMeasurement.neckCm} cm');
      if (latestMeasurement.bicepCm != null) buffer.writeln(isVi ? '  + Bắp tay: ${latestMeasurement.bicepCm} cm' : '  + Bicep: ${latestMeasurement.bicepCm} cm');
      if (latestMeasurement.thighCm != null) buffer.writeln(isVi ? '  + Vòng đùi: ${latestMeasurement.thighCm} cm' : '  + Thigh: ${latestMeasurement.thighCm} cm');
    } else {
      buffer.writeln(isVi ? '- Chưa ghi nhận số đo vòng cơ thể.' : '- No body measurements recorded yet.');
    }
    buffer.writeln('');

    // 3. Hoạt động tập luyện
    buffer.writeln(isVi ? '🔥 3. HOẠT ĐỘNG RÈN LUYỆN (30 NGÀY QUA):' : '🔥 3. WORKOUT ACTIVITY (LAST 30 DAYS):');
    buffer.writeln(isVi
        ? '- Tổng số buổi rèn luyện: $totalWorkoutCount buổi'
        : '- Total workout sessions: $totalWorkoutCount');
    buffer.writeln(isVi
        ? '- Tổng thời lượng tập: $totalWorkoutMinutes phút (~${(totalWorkoutMinutes / 60.0).toStringAsFixed(1)} giờ)'
        : '- Total duration: $totalWorkoutMinutes mins (~${(totalWorkoutMinutes / 60.0).toStringAsFixed(1)} hours)');
    buffer.writeln(isVi
        ? '- Tổng năng lượng đốt cháy: $totalWorkoutCalories kcal'
        : '- Total calories burned: $totalWorkoutCalories kcal\n');

    // 4. Dinh dưỡng
    buffer.writeln(isVi ? '🥗 4. THỐNG KÊ DINH DƯỠNG (30 NGÀY QUA):' : '🥗 4. NUTRITION SUMMARY (LAST 30 DAYS):');
    buffer.writeln(isVi
        ? '- Tổng số món ăn đã ghi nhận: ${recentFoods.length} món'
        : '- Total food entries logged: ${recentFoods.length}');
    buffer.writeln(isVi
        ? '- Trung bình Calo nạp/ngày: $avgDailyCalories kcal'
        : '- Average daily calories: $avgDailyCalories kcal');
    buffer.writeln(isVi
        ? '- Tỉ lệ Macros trung bình hàng ngày: Protein: ${avgProtein}g | Carbs: ${avgCarbs}g | Fat: ${avgFat}g'
        : '- Average daily macros: Protein: ${avgProtein}g | Carbs: ${avgCarbs}g | Fat: ${avgFat}g\n');

    buffer.writeln('====================================================');
    buffer.writeln(isVi
        ? '📅 Báo cáo tạo lúc: ${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
        : '📅 Generated on: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    buffer.writeln('🚀 Fitness Tracker v2.0 - Powered by AI & Personal Health Science');
    buffer.writeln('====================================================');

    return buffer.toString();
  }

  /// Xuất và chia sẻ báo cáo qua Share Sheet (Zalo, Gmail, Tin nhắn, File...)
  Future<void> export30DaySummary(BuildContext context) async {
    try {
      final reportText = await generate30DayReportText();

      // Lưu file tạm để hỗ trợ chia sẻ dạng tệp văn bản đính kèm
      final tempDir = await getTemporaryDirectory();
      final dateSlug = DateTime.now().toIso8601String().split('T')[0];
      final file = File('${tempDir.path}/Fitness_Tracker_Report_$dateSlug.txt');
      await file.writeAsString(reportText);

      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final originRect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      final title = LocaleService.isVietnamese
          ? 'Báo cáo Sức khỏe Fitness Tracker (30 Ngày)'
          : 'Fitness Tracker Health Report (30 Days)';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          text: reportText,
          subject: title,
          sharePositionOrigin: originRect,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing health report: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleService.isVietnamese
                  ? 'Không thể xuất báo cáo: $e'
                  : 'Failed to export report: $e',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
