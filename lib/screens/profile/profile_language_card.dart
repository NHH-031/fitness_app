import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/locale_service.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';

class ProfileLanguageCard extends StatelessWidget {
  final VoidCallback onLanguageChanged;

  const ProfileLanguageCard({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLang = LocaleService.currentLanguage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedGlobe,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                LocaleService.tr('language_section_title'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildLanguageOption(
                flag: '🇻🇳',
                label: 'VI',
                isSelected: currentLang == 'vi',
                onTap: () async {
                  await LocaleService.setLanguage('vi');
                  await StorageService.saveAppLanguage('vi');
                  onLanguageChanged();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildLanguageOption(
                flag: '🇬🇧',
                label: 'EN',
                isSelected: currentLang == 'en',
                onTap: () async {
                  await LocaleService.setLanguage('en');
                  await StorageService.saveAppLanguage('en');
                  onLanguageChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.info.withValues(alpha: 0.2)
              : const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.info : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.info : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
