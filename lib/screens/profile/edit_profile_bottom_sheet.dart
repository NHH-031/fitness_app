import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';
import '../../utils/app_haptics.dart';
import '../../widgets/app_ui_components.dart';

class EditProfileBottomSheet extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onSaved;

  const EditProfileBottomSheet({
    super.key,
    required this.profile,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required Function(UserProfile) onSaved,
  }) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => EditProfileBottomSheet(
        profile: profile,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  late String _gender;
  late double _activityLevel;
  late String _fitnessGoal;

  Map<double, String> get _activityLabels {
    if (LocaleService.isVietnamese) {
      return {
        1.2: 'Ít vận động (Ngồi nhiều, không tập)',
        1.375: 'Vận động nhẹ (Tập 1-3 ngày/tuần)',
        1.55: 'Vận động vừa (Tập 3-5 ngày/tuần)',
        1.725: 'Năng động (Tập 6-7 ngày/tuần)',
        1.9: 'Rất năng động (Tập nặng 2 buổi/ngày)',
      };
    } else {
      return {
        1.2: 'Sedentary (Little to no exercise)',
        1.375: 'Lightly active (Exercise 1-3 days/week)',
        1.55: 'Moderately active (Exercise 3-5 days/week)',
        1.725: 'Very active (Exercise 6-7 days/week)',
        1.9: 'Extra active (Hard daily exercise/training)',
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(text: widget.profile.age.toString());
    _heightController =
        TextEditingController(text: widget.profile.height.toStringAsFixed(0));
    _weightController =
        TextEditingController(text: widget.profile.weight.toStringAsFixed(1));
    _targetWeightController = TextEditingController(
        text: widget.profile.targetWeight.toStringAsFixed(1));
    _gender = widget.profile.gender;
    _activityLevel = widget.profile.activityLevel;
    _fitnessGoal = widget.profile.fitnessGoal;
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      AppHaptics.success();
      final updated = widget.profile.copyWith(
        name: _nameController.text.trim(),
        gender: _gender,
        age: int.tryParse(_ageController.text) ?? widget.profile.age,
        height: double.tryParse(_heightController.text) ?? widget.profile.height,
        weight: double.tryParse(_weightController.text) ?? widget.profile.weight,
        targetWeight: double.tryParse(_targetWeightController.text) ??
            widget.profile.targetWeight,
        activityLevel: _activityLevel,
        fitnessGoal: _fitnessGoal,
      );
      widget.onSaved(updated);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BottomSheetDragHandle(),
              const SizedBox(height: 4),
              Text(
                LocaleService.tr('edit_profile_sheet_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                LocaleService.tr('edit_profile_sheet_sub'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: LocaleService.tr('field_name'),
                icon: Icons.person_rounded,
                validator: (val) => val == null || val.trim().isEmpty
                    ? LocaleService.tr('please_enter_name')
                    : null,
              ),

              const SizedBox(height: 14),

              // Gender Selector
              Text(
                LocaleService.tr('field_gender'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderChoice(
                      label: LocaleService.tr('field_male'),
                      icon: Icons.male_rounded,
                      isSelected: _gender.toLowerCase() == 'male',
                      onTap: () => setState(() => _gender = 'male'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildGenderChoice(
                      label: LocaleService.tr('field_female'),
                      icon: Icons.female_rounded,
                      isSelected: _gender.toLowerCase() == 'female',
                      onTap: () => setState(() => _gender = 'female'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Age & Height
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      label: LocaleService.tr('field_age'),
                      icon: Icons.cake_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 10 || n > 120) return '10-120';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: LocaleService.tr('field_height'),
                      icon: Icons.height_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final n = double.tryParse(val ?? '');
                        if (n == null || n < 80 || n > 250) return '80-250';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Weight & Target Weight
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: LocaleService.tr('field_weight'),
                      icon: Icons.monitor_weight_rounded,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        final n = double.tryParse(val ?? '');
                        if (n == null || n < 30 || n > 300) return '30-300';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _targetWeightController,
                      label: LocaleService.tr('field_target_weight'),
                      icon: Icons.flag_rounded,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        final n = double.tryParse(val ?? '');
                        if (n == null || n < 30 || n > 300) return '30-300';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Activity Level Dropdown
              Text(
                LocaleService.tr('field_activity_level'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: _activityLevel,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E2C),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: _activityLabels.entries.map((e) {
                      return DropdownMenuItem<double>(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _activityLevel = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Save Button
              BouncingTap(
                hapticType: AppHapticFeedbackType.medium,
                scaleDown: 0.97,
                onTap: _submit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    LocaleService.tr('save_profile_btn'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
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
    );
  }

  Widget _buildGenderChoice({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return BouncingTap(
      hapticType: AppHapticFeedbackType.selection,
      scaleDown: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.info.withValues(alpha: 0.15)
              : const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.info : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.info : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.info, size: 18),
        filled: true,
        fillColor: const Color(0xFF1E1E2C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.info, width: 1.5),
        ),
      ),
    );
  }
}
