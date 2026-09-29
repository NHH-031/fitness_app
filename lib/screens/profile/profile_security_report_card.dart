import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/biometric_service.dart';
import '../../services/locale_service.dart';
import '../../services/report_export_service.dart';
import '../../theme.dart';
import '../../utils/app_haptics.dart';
import '../body_measurements_screen.dart';

class ProfileSecurityReportCard extends StatefulWidget {
  const ProfileSecurityReportCard({super.key});

  @override
  State<ProfileSecurityReportCard> createState() => _ProfileSecurityReportCardState();
}

class _ProfileSecurityReportCardState extends State<ProfileSecurityReportCard> {
  bool _isBiometricEnabled = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final enabled = await BiometricService.instance.isAppLockEnabled();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    AppHaptics.selection();
    if (value) {
      // Xác thực thử trước khi kích hoạt
      final authenticated = await BiometricService.instance.authenticate(
        reason: LocaleService.isVietnamese
            ? 'Xác thực sinh trắc học để kích hoạt khóa ứng dụng'
            : 'Authenticate to enable biometric app lock',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocaleService.isVietnamese
                    ? 'Xác thực không thành công. Chưa bật khóa sinh trắc học.'
                    : 'Authentication failed. Lock not enabled.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    await BiometricService.instance.setAppLockEnabled(value);
    if (mounted) {
      setState(() => _isBiometricEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? (LocaleService.isVietnamese
                    ? 'Đã bật khóa Vân tay / Face ID khi mở ứng dụng!'
                    : 'Biometric App Lock enabled!')
                : (LocaleService.isVietnamese
                    ? 'Đã tắt khóa ứng dụng.'
                    : 'Biometric App Lock disabled.'),
          ),
          backgroundColor: value ? const Color(0xFF00E676) : Colors.white24,
        ),
      );
    }
  }

  Future<void> _exportReport() async {
    AppHaptics.medium();
    setState(() => _isExporting = true);
    try {
      await ReportExportService.instance.export30DaySummary(context);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedShield01,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isVi ? 'BẢO MẬT & BÁO CÁO THỂ HÌNH' : 'SECURITY & HEALTH REPORT',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. Biometric App Lock Switch Tile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFingerPrint,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVi ? 'Khóa bảo mật Sinh trắc học' : 'Biometric App Lock',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVi
                            ? 'Vân tay hoặc Face ID khi mở app'
                            : 'Require Face ID / Fingerprint on launch',
                        style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometric,
                  activeTrackColor: AppColors.info,
                  activeThumbColor: Colors.black,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Body Tape & Before/After Slider Navigation Tile
          InkWell(
            onTap: () {
              AppHaptics.light();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BodyMeasurementsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF14141E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedBodyPartMuscle,
                      color: Colors.purpleAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVi ? 'Số Đo Cơ Thể & Ảnh Before/After' : 'Body Tape & Before/After Slider',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVi
                              ? '% Mỡ US Navy & Thanh trượt so sánh vóc dáng'
                              : 'US Navy Body Fat % & Photo transformation slider',
                          style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Export 30-Day Health Report Button
          InkWell(
            onTap: _isExporting ? null : _exportReport,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    const Color(0xFF0088AA).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.info,
                            ),
                          )
                        : const Icon(
                            Icons.share_rounded,
                            color: AppColors.info,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVi ? 'Xuất Báo Cáo Sức Khỏe 30 Ngày' : 'Export 30-Day Health Report',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVi
                              ? 'Tổng hợp bài tập, calo, dinh dưỡng & số đo để gửi PT/Bác sĩ'
                              : 'Summary of workouts, calories & body tape for PT/Doctor',
                          style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, color: AppColors.info, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
