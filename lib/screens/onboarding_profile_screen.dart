import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'main_screen.dart';

class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  State<OnboardingProfileScreen> createState() => _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

  String _gender = 'male';
  double _activityLevel = 1.55;
  String _fitnessGoal = 'cutting';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    final initialName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : (LocaleService.isVietnamese ? 'Hoàng Nguyễn' : 'Alex');

    _nameController = TextEditingController(text: initialName);
    _ageController = TextEditingController(text: '24');
    _heightController = TextEditingController(text: '175');
    _weightController = TextEditingController(text: '70');
    _targetWeightController = TextEditingController(text: '65');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim().isEmpty
          ? (LocaleService.isVietnamese ? 'Bạn' : 'Athlete')
          : _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 24;
      final height = double.tryParse(_heightController.text.trim()) ?? 175.0;
      final weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
      final targetWeight = double.tryParse(_targetWeightController.text.trim()) ?? 65.0;

      final profile = UserProfile(
        name: name,
        gender: _gender,
        age: age,
        height: height,
        weight: weight,
        targetWeight: targetWeight,
        activityLevel: _activityLevel,
        fitnessGoal: _fitnessGoal,
      );

      await StorageService.saveUserProfile(profile);
      await StorageService.saveNutritionGoal(_fitnessGoal);
      await StorageService.setCompletedOnboarding(true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu thông tin: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badge & Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F0FF), Color(0xFF9D00FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isVi ? 'THIẾT LẬP HỒ SƠ SINH HỌC' : 'SETUP BIOMETRIC PROFILE',
                        style: AppTheme.font(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isVi
                            ? 'Cung cấp thông số cơ thể để AI Coach tính toán chuẩn xác calo tiêu hao, macro & lộ trình luyện tập cho bạn.'
                            : 'Provide your body metrics so AI Coach can personalize your calorie burn, macros & workout journey.',
                        style: AppTheme.font(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 1. Full Name
                _buildSectionTitle(
                  icon: Icons.person_rounded,
                  title: isVi ? 'Họ và Tên' : 'Full Name',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: isVi ? 'Nhập họ tên của bạn' : 'Enter your full name',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF00F0FF)),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 2. Biological Gender
                _buildSectionTitle(
                  icon: Icons.wc_rounded,
                  title: isVi ? 'Giới tính sinh học' : 'Biological Gender',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderCard(
                        value: 'male',
                        label: isVi ? 'Nam ♂' : 'Male ♂',
                        color: Colors.blueAccent,
                        icon: Icons.male_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGenderCard(
                        value: 'female',
                        label: isVi ? 'Nữ ♀' : 'Female ♀',
                        color: Colors.pinkAccent,
                        icon: Icons.female_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Biometrics Grid (Age, Height, Weight, Target Weight)
                _buildSectionTitle(
                  icon: Icons.monitor_weight_rounded,
                  title: isVi ? 'Chỉ số cơ thể' : 'Body Measurements',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        controller: _ageController,
                        label: isVi ? 'Tuổi' : 'Age',
                        suffix: isVi ? 'tuổi' : 'yrs',
                        icon: Icons.cake_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumericField(
                        controller: _heightController,
                        label: isVi ? 'Chiều cao' : 'Height',
                        suffix: 'cm',
                        icon: Icons.height_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        controller: _weightController,
                        label: isVi ? 'Cân nặng hiện tại' : 'Current Weight',
                        suffix: 'kg',
                        icon: Icons.scale_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumericField(
                        controller: _targetWeightController,
                        label: isVi ? 'Cân nặng mục tiêu' : 'Target Weight',
                        suffix: 'kg',
                        icon: Icons.flag_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 4. Fitness Goal
                _buildSectionTitle(
                  icon: Icons.track_changes_rounded,
                  title: isVi ? 'Mục tiêu luyện tập' : 'Fitness Goal',
                ),
                const SizedBox(height: 10),
                _buildGoalCard(
                  keyId: 'cutting',
                  title: isVi ? 'Siết Mỡ (Fat Loss)' : 'Fat Loss (Cutting)',
                  subtitle: isVi ? 'Thâm hụt -450 kcal/ngày • Tối đa săn chắc' : 'Deficit -450 kcal/day • Lean definition',
                  icon: '🔥',
                  color: const Color(0xFFFF3B30),
                ),
                const SizedBox(height: 8),
                _buildGoalCard(
                  keyId: 'bulking',
                  title: isVi ? 'Tăng Cơ (Muscle Gain)' : 'Muscle Gain (Bulking)',
                  subtitle: isVi ? 'Dư thừa +350 kcal/ngày • Tối đa phì đại cơ' : 'Surplus +350 kcal/day • Maximum hypertrophy',
                  icon: '💪',
                  color: const Color(0xFF00F0FF),
                ),
                const SizedBox(height: 8),
                _buildGoalCard(
                  keyId: 'balanced',
                  title: isVi ? 'Cân Bằng (Balanced)' : 'Balanced Maintenance',
                  subtitle: isVi ? 'Bằng mức TDEE • Duy trì vóc dáng & sức khỏe' : 'Matches TDEE • Maintain weight & health',
                  icon: '⚖️',
                  color: const Color(0xFF9D00FF),
                ),
                const SizedBox(height: 8),
                _buildGoalCard(
                  keyId: 'endurance',
                  title: isVi ? 'Bền Bỉ (Endurance)' : 'Cardio & Endurance',
                  subtitle: isVi ? 'Bù đắp +150 kcal/ngày • Tăng sức bền tim mạch' : 'Refuel +150 kcal/day • Stamina & stamina',
                  icon: '⚡',
                  color: const Color(0xFFFFB800),
                ),

                const SizedBox(height: 24),

                // 5. Activity Level
                _buildSectionTitle(
                  icon: Icons.directions_run_rounded,
                  title: isVi ? 'Mức độ hoạt động' : 'Daily Activity Level',
                ),
                const SizedBox(height: 8),
                _buildActivityOption(
                  value: 1.2,
                  label: isVi ? 'Ít vận động (Công việc văn phòng, ít đi lại)' : 'Sedentary (Little or no exercise)',
                ),
                _buildActivityOption(
                  value: 1.375,
                  label: isVi ? 'Nhẹ nhàng (Tập luyện nhẹ 1-3 ngày/tuần)' : 'Light (Exercise 1-3 days/week)',
                ),
                _buildActivityOption(
                  value: 1.55,
                  label: isVi ? 'Vừa phải (Tập luyện tích cực 3-5 ngày/tuần)' : 'Moderate (Exercise 3-5 days/week)',
                ),
                _buildActivityOption(
                  value: 1.725,
                  label: isVi ? 'Năng động (Tập luyện nặng 6-7 ngày/tuần)' : 'Active (Hard exercise 6-7 days/week)',
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: Colors.black,
                      elevation: 6,
                      shadowColor: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black87,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                isVi ? 'HOÀN TẤT & KẾT NỐI AI COACH' : 'FINISH & CONNECT AI COACH',
                                style: AppTheme.font(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00F0FF), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.font(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.white60, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
  }) {
    final isVi = LocaleService.isVietnamese;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: const Color(0xFF00F0FF), size: 18),
        filled: true,
        fillColor: AppTheme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return isVi ? 'Cần nhập' : 'Required';
        }
        if (double.tryParse(val.trim()) == null) {
          return isVi ? 'Số không hợp lệ' : 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget _buildGoalCard({
    required String keyId,
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    final isSelected = _fitnessGoal == keyId;
    return GestureDetector(
      onTap: () => setState(() => _fitnessGoal = keyId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? color.withValues(alpha: 0.9) : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOption({
    required double value,
    required String label,
  }) {
    final isSelected = (_activityLevel - value).abs() < 0.01;
    return GestureDetector(
      onTap: () => setState(() => _activityLevel = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F0FF)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF00F0FF) : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
