import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/body_measurement.dart';
import '../models/user_profile.dart';
import '../repositories/body_measurement_repository.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';
import '../widgets/before_after_slider_widget.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  UserProfile _profile = UserProfile.defaultProfile();
  List<BodyMeasurement> _measurements = [];
  bool _isLoading = true;

  String _beforeImagePath = '';
  String _afterImagePath = '';

  static const String _prefKeyBefore = 'body_photo_before_path';
  static const String _prefKeyAfter = 'body_photo_after_path';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await StorageService.getUserProfile();
    final measurements = await BodyMeasurementRepository.instance.getMeasurements();
    final prefs = await SharedPreferences.getInstance();

    final before = prefs.getString(_prefKeyBefore) ?? '';
    final after = prefs.getString(_prefKeyAfter) ?? '';

    if (mounted) {
      setState(() {
        _profile = profile;
        _measurements = measurements;
        _beforeImagePath = before;
        _afterImagePath = after;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPhoto(bool isBefore) async {
    AppHaptics.light();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBefore
                    ? (LocaleService.isVietnamese ? 'Chọn ảnh TRƯỚC (Before)' : 'Select BEFORE Photo')
                    : (LocaleService.isVietnamese ? 'Chọn ảnh SAU (After)' : 'Select AFTER Photo'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.info),
                title: Text(
                  LocaleService.isVietnamese ? 'Chụp ảnh mới' : 'Take a photo',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.info),
                title: Text(
                  LocaleService.isVietnamese ? 'Chọn từ thư viện' : 'Choose from gallery',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final tag = isBefore ? 'before' : 'after';
      final fileName = 'body_${tag}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');

      final prefs = await SharedPreferences.getInstance();
      if (isBefore) {
        await prefs.setString(_prefKeyBefore, savedFile.path);
        setState(() => _beforeImagePath = savedFile.path);
      } else {
        await prefs.setString(_prefKeyAfter, savedFile.path);
        setState(() => _afterImagePath = savedFile.path);
      }

      AppHaptics.success();
    } catch (e) {
      debugPrint('Error picking body photo: $e');
    }
  }

  void _showAddMeasurementSheet() {
    AppHaptics.medium();
    final isVi = LocaleService.isVietnamese;
    final latest = _measurements.isNotEmpty ? _measurements.first : null;

    final waistCtrl = TextEditingController(text: latest?.waistCm?.toString() ?? '');
    final neckCtrl = TextEditingController(text: latest?.neckCm?.toString() ?? '');
    final chestCtrl = TextEditingController(text: latest?.chestCm?.toString() ?? '');
    final hipsCtrl = TextEditingController(text: latest?.hipsCm?.toString() ?? '');
    final bicepCtrl = TextEditingController(text: latest?.bicepCm?.toString() ?? '');
    final thighCtrl = TextEditingController(text: latest?.thighCm?.toString() ?? '');
    final weightCtrl = TextEditingController(text: (_profile.weight > 0 ? _profile.weight.toString() : ''));

    double previewBodyFat = 0.0;
    String previewCategory = '';

    void updatePreview(StateSetter modalSetState) {
      final waist = double.tryParse(waistCtrl.text.trim()) ?? 0;
      final neck = double.tryParse(neckCtrl.text.trim()) ?? 0;
      final hips = double.tryParse(hipsCtrl.text.trim());

      if (waist > 0 && neck > 0) {
        final bf = UserMetricsService.calculateBodyFatPercent(
          waistCm: waist,
          neckCm: neck,
          heightCm: _profile.height,
          hipsCm: hips,
          gender: _profile.gender,
        );
        modalSetState(() {
          previewBodyFat = bf;
          previewCategory = UserMetricsService.getBodyFatCategory(
            bf,
            gender: _profile.gender,
          );
        });
      } else {
        modalSetState(() {
          previewBodyFat = 0.0;
          previewCategory = '';
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, modalSetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedBodyPartMuscle,
                      color: AppColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isVi ? 'Ghi nhận Số đo Cơ thể' : 'Record Body Measurements',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Preview US Navy Body Fat %
                if (previewBodyFat > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F3242), Color(0xFF142436)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_graph_rounded, color: AppColors.info, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Ước tính % Mỡ Hải quân (US Navy)' : 'Estimated Body Fat (US Navy)',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                            Text(
                              '$previewBodyFat% - $previewCategory',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Input fields grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: waistCtrl,
                        label: isVi ? 'Vòng eo (cm) *' : 'Waist (cm) *',
                        icon: Icons.compress_rounded,
                        onChanged: (_) => updatePreview(modalSetState),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: neckCtrl,
                        label: isVi ? 'Vòng cổ (cm) *' : 'Neck (cm) *',
                        icon: Icons.accessibility_new_rounded,
                        onChanged: (_) => updatePreview(modalSetState),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: chestCtrl,
                        label: isVi ? 'Vòng ngực (cm)' : 'Chest (cm)',
                        icon: Icons.fitness_center_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: hipsCtrl,
                        label: isVi ? 'Vòng mông (cm)' : 'Hips (cm)',
                        icon: Icons.airline_seat_legroom_extra_rounded,
                        onChanged: (_) => updatePreview(modalSetState),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: bicepCtrl,
                        label: isVi ? 'Bắp tay (cm)' : 'Bicep (cm)',
                        icon: Icons.sports_mma_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: thighCtrl,
                        label: isVi ? 'Vòng đùi (cm)' : 'Thigh (cm)',
                        icon: Icons.directions_walk_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: weightCtrl,
                  label: isVi ? 'Cân nặng (kg)' : 'Weight (kg)',
                  icon: Icons.monitor_weight_rounded,
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final waist = double.tryParse(waistCtrl.text.trim());
                      final neck = double.tryParse(neckCtrl.text.trim());
                      final chest = double.tryParse(chestCtrl.text.trim());
                      final hips = double.tryParse(hipsCtrl.text.trim());
                      final bicep = double.tryParse(bicepCtrl.text.trim());
                      final thigh = double.tryParse(thighCtrl.text.trim());
                      final weight = double.tryParse(weightCtrl.text.trim());

                      double? calculatedBf;
                      if (waist != null && neck != null && waist > 0 && neck > 0) {
                        calculatedBf = UserMetricsService.calculateBodyFatPercent(
                          waistCm: waist,
                          neckCm: neck,
                          heightCm: _profile.height,
                          hipsCm: hips,
                          gender: _profile.gender,
                        );
                      }

                      final now = DateTime.now();
                      final measurement = BodyMeasurement(
                        id: 'meas_${now.millisecondsSinceEpoch}',
                        date: now.toIso8601String().split('T')[0],
                        waistCm: waist,
                        neckCm: neck,
                        chestCm: chest,
                        hipsCm: hips,
                        bicepCm: bicep,
                        thighCm: thigh,
                        weight: weight,
                        bodyFatPercent: calculatedBf,
                        createdAt: now,
                      );

                      await BodyMeasurementRepository.instance.saveMeasurement(measurement);

                      // Cập nhật cân nặng người dùng nếu nhập
                      if (weight != null && weight > 0) {
                        final updatedProfile = _profile.copyWith(weight: weight);
                        await StorageService.saveUserProfile(updatedProfile);
                      }

                      AppHaptics.success();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      isVi ? 'LƯU SỐ ĐO HÔM NAY' : 'SAVE MEASUREMENTS',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        onChanged: onChanged,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.info, size: 18),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;
    final latest = _measurements.isNotEmpty ? _measurements.first : null;

    double? currentBf = latest?.bodyFatPercent;
    String category = '';
    if (currentBf != null && currentBf > 0) {
      category = UserMetricsService.getBodyFatCategory(currentBf, gender: _profile.gender);
    } else if (latest?.waistCm != null && latest?.neckCm != null) {
      currentBf = UserMetricsService.calculateBodyFatPercent(
        waistCm: latest!.waistCm!,
        neckCm: latest.neckCm!,
        heightCm: _profile.height,
        hipsCm: latest.hipsCm,
        gender: _profile.gender,
      );
      category = UserMetricsService.getBodyFatCategory(currentBf, gender: _profile.gender);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isVi ? 'Số Đo & Vóc Dáng' : 'Body Measurements',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.info, size: 26),
            tooltip: isVi ? 'Thêm số đo mới' : 'Add Measurement',
            onPressed: _showAddMeasurementSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.info))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Before & After Progress Photo Slider Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  color: AppColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isVi ? 'SO SÁNH TIẾN TRÌNH VÓC DÁNG' : 'BODY TRANSFORMATION SLIDER',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVi ? 'Kéo thanh trượt để so sánh sự biến đổi cơ bắp' : 'Drag slider to compare body transformation',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        // Slider
                        BeforeAfterSliderWidget(
                          beforeImagePath: _beforeImagePath,
                          afterImagePath: _afterImagePath,
                          beforeLabel: isVi ? 'Trước (Before)' : 'Before',
                          afterLabel: isVi ? 'Hiện tại (After)' : 'Current',
                          height: 280,
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickPhoto(true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                label: Text(isVi ? 'Đổi ảnh Trước' : 'Change Before', style: const TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _pickPhoto(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                                  foregroundColor: const Color(0xFF00F0FF),
                                  side: const BorderSide(color: Color(0xFF00F0FF)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                                label: Text(isVi ? 'Đổi ảnh Sau' : 'Change After', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. US Navy Body Fat % Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF122436), Color(0xFF0C1624)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.info, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              currentBf != null && currentBf > 0 ? '${currentBf.toStringAsFixed(1)}%' : '--',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVi ? '% MỠ CƠ THỂ (US NAVY METHOD)' : 'US NAVY BODY FAT %',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.isNotEmpty ? category : (isVi ? 'Cần cập nhật số đo eo & cổ' : 'Update waist & neck'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isVi
                                    ? 'Tính chuẩn theo chu vi vòng eo, cổ và chiều cao'
                                    : 'Scientific formula using waist, neck, and height',
                                style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Current Circumferences Tiles
                  Text(
                    isVi ? 'SỐ ĐO GẦN ĐÂY NHẤT' : 'LATEST MEASUREMENTS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeasureTile(
                          title: isVi ? 'Vòng Eo' : 'Waist',
                          value: latest?.waistCm != null ? '${latest!.waistCm} cm' : '--',
                          icon: Icons.compress_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMeasureTile(
                          title: isVi ? 'Vòng Ngực' : 'Chest',
                          value: latest?.chestCm != null ? '${latest!.chestCm} cm' : '--',
                          icon: Icons.fitness_center_rounded,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMeasureTile(
                          title: isVi ? 'Vòng Mông' : 'Hips',
                          value: latest?.hipsCm != null ? '${latest!.hipsCm} cm' : '--',
                          icon: Icons.airline_seat_legroom_extra_rounded,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeasureTile(
                          title: isVi ? 'Vòng Cổ' : 'Neck',
                          value: latest?.neckCm != null ? '${latest!.neckCm} cm' : '--',
                          icon: Icons.accessibility_new_rounded,
                          color: Colors.tealAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMeasureTile(
                          title: isVi ? 'Bắp Tay' : 'Bicep',
                          value: latest?.bicepCm != null ? '${latest!.bicepCm} cm' : '--',
                          icon: Icons.sports_mma_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMeasureTile(
                          title: isVi ? 'Vòng Đùi' : 'Thigh',
                          value: latest?.thighCm != null ? '${latest!.thighCm} cm' : '--',
                          icon: Icons.directions_walk_rounded,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. History Log List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isVi ? 'LỊCH SỬ SỐ ĐO' : 'MEASUREMENT HISTORY',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_measurements.length} ${isVi ? 'lần ghi' : 'logs'}',
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_measurements.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.straighten_rounded, color: Colors.white24, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              isVi ? 'Chưa có dữ liệu số đo nào.' : 'No measurements logged yet.',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._measurements.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14141E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                item.date,
                                style: const TextStyle(
                                  color: AppColors.info,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Eo: ${item.waistCm ?? '--'} cm  •  Ngực: ${item.chestCm ?? '--'} cm  •  Cổ: ${item.neckCm ?? '--'} cm',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.bodyFatPercent != null)
                                    Text(
                                      'Mỡ: ${item.bodyFatPercent!.toStringAsFixed(1)}% (${UserMetricsService.getBodyFatCategory(item.bodyFatPercent!, gender: _profile.gender)})',
                                      style: const TextStyle(color: AppColors.info, fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () async {
                                await BodyMeasurementRepository.instance.deleteMeasurement(item.id);
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMeasurementSheet,
        backgroundColor: AppColors.info,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          isVi ? 'GHI SỐ ĐO MỚI' : 'NEW MEASUREMENT',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildMeasureTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
