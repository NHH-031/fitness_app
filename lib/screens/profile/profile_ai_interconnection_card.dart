import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/user_profile.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';
import '../ai_chat_history_screen.dart';
import '../../services/storage_service.dart';

class ProfileAiInterconnectionCard extends StatelessWidget {
  final UserProfile profile;
  final String Function(String) getGoalDisplayName;

  const ProfileAiInterconnectionCard({
    super.key,
    required this.profile,
    required this.getGoalDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9D00FF).withValues(alpha: 0.15),
            AppColors.info.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: const Color(0xFF9D00FF).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAiSparkles,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                LocaleService.tr('ai_integration_title'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_activity'),
            status: LocaleService.tr('ai_sync_activity', args: {
              'age': profile.age.toString(),
              'gender': profile.gender == 'male'
                  ? LocaleService.tr('field_male')
                  : LocaleService.tr('field_female'),
              'goal': getGoalDisplayName(profile.fitnessGoal),
            }),
            hugeIcon: HugeIcons.strokeRoundedDumbbell01,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_food'),
            status: LocaleService.tr('ai_sync_food', args: {
              'cal': profile.targetCalories.toString(),
            }),
            hugeIcon: HugeIcons.strokeRoundedApple01,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_dashboard'),
            status: LocaleService.tr('ai_sync_dashboard', args: {
              'bmr': profile.bmr.round().toString(),
            }),
            hugeIcon: HugeIcons.strokeRoundedHome01,
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatHistoryScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D00FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF9D00FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_rounded, color: Color(0xFF00F0FF), size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            LocaleService.tr('view_chat_history_btn'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showApiKeyDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.vpn_key_rounded, color: Color(0xFF00F0FF), size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            LocaleService.isVietnamese ? 'Cài đặt API Key' : 'API Key Setup',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    final currentKey = await StorageService.getGeminiApiKey() ?? '';
    if (!context.mounted) return;
    final controller = TextEditingController(text: currentKey);
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161A29),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF9D00FF), width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: Color(0xFF00F0FF), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LocaleService.isVietnamese
                      ? 'Cấu hình Gemini API Key'
                      : 'Gemini API Key Setup',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.isVietnamese
                    ? 'Nhập khóa API Gemini của bạn để kích hoạt đầy đủ các tính năng AI (quét dinh dưỡng, tư vấn thể hình).'
                    : 'Enter your Gemini API key to enable AI features (nutrition scanner, workout coach).',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white60,
                      size: 20,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                LocaleService.isVietnamese ? 'Hủy' : 'Cancel',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await StorageService.saveGeminiApiKey(controller.text.trim());
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LocaleService.isVietnamese
                          ? 'Đã lưu Gemini API Key thành công!'
                          : 'Gemini API Key saved successfully!',
                    ),
                    backgroundColor: const Color(0xFF30D158),
                  ),
                );
              },
              child: Text(
                LocaleService.isVietnamese ? 'Lưu' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSyncItem({
    required String tabName,
    required String status,
    required List<List<dynamic>> hugeIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              HugeIcon(icon: hugeIcon, color: AppColors.info, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tabName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
