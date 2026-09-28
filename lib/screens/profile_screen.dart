import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'profile/edit_profile_bottom_sheet.dart';
import 'profile/profile_achievements_card.dart';
import 'profile/profile_account_sync_card.dart';
import 'profile/profile_ai_interconnection_card.dart';
import 'profile/profile_battery_card.dart';
import 'profile/profile_biometrics_card.dart';
import 'profile/profile_goal_selector_card.dart';
import 'profile/profile_hero_card.dart';
import 'profile/profile_language_card.dart';
import 'profile/profile_macro_blueprint_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  UserProfile _profile = UserProfile.defaultProfile();
  bool _isLoading = true;
  bool _isGuest = false;
  bool _isSigningIn = false;
  bool _isBatteryExempt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    StorageService.profileUpdateNotifier.addListener(_loadProfile);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StorageService.profileUpdateNotifier.removeListener(_loadProfile);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBatteryOptimization();
    }
  }

  Future<void> _loadProfile() async {
    final profile = await StorageService.getUserProfile();
    final isGuest = await StorageService.isGuestMode();
    final isExempt = await BackgroundService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isGuest = isGuest;
        _isBatteryExempt = isExempt;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkBatteryOptimization() async {
    final isExempt = await BackgroundService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _isBatteryExempt = isExempt;
      });
    }
  }

  Future<void> _requestBatteryOptimization() async {
    await BackgroundService.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(milliseconds: 800));
    await _checkBatteryOptimization();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              color: Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocaleService.tr('sign_out_confirm_title'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          LocaleService.tr('sign_out_confirm_msg'),
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              LocaleService.tr('cancel_btn'),
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              LocaleService.tr('sign_out_btn'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().signOut();
      await StorageService.setGuestMode(false);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleGoogleSignInFromProfile() async {
    setState(() => _isSigningIn = true);
    try {
      final credential = await AuthService().signInWithGoogle();
      if (!mounted) return;
      if (credential != null && credential.user != null) {
        await StorageService.setGuestMode(false);
        await FirestoreService().syncOnLogin();
        await _loadProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleService.isVietnamese
                  ? 'Đăng nhập Google & đồng bộ dữ liệu thành công!'
                  : 'Google Sign-In and Cloud Sync successful!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleService.isVietnamese
                ? 'Đăng nhập không thành công. Vui lòng thử lại.'
                : 'Sign in failed. Please try again.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _updateGoal(String goal) async {
    final updated = _profile.copyWith(fitnessGoal: goal);
    await StorageService.saveUserProfile(updated);
    await StorageService.saveNutritionGoal(goal);
    setState(() {
      _profile = updated;
    });
  }

  String _getGoalDisplayName(String goal) {
    switch (goal.toLowerCase()) {
      case 'cutting':
        return LocaleService.isVietnamese ? 'SIẾT MỠ' : 'FAT LOSS';
      case 'bulking':
        return LocaleService.isVietnamese ? 'TĂNG CƠ' : 'MUSCLE GAIN';
      case 'endurance':
        return LocaleService.isVietnamese ? 'BỀN BỈ' : 'ENDURANCE';
      case 'balanced':
      default:
        return LocaleService.isVietnamese ? 'CÂN BẰNG' : 'BALANCED';
    }
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.lightBlueAccent;
    if (bmi < 24.9) return AppColors.info;
    if (bmi < 29.9) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _showEditProfileDialog() {
    EditProfileBottomSheet.show(
      context,
      profile: _profile,
      onSaved: (updated) async {
        await StorageService.saveUserProfile(updated);
        await StorageService.saveNutritionGoal(updated.fitnessGoal);
        setState(() {
          _profile = updated;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedCloudSavingDone01,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocaleService.isVietnamese
                        ? 'Đã lưu hồ sơ & đồng bộ Firebase, AI thành công!'
                        : 'Profile updated & synced to Cloud & AI successfully!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E2C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.info, width: 0.8),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final targetMacros = _profile.targetMacros;
    final bmi = _profile.bmi;
    final bmiColor = _getBmiColor(bmi);
    final weightDiff = _profile.weight - _profile.targetWeight;
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppRadius.card,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Edit Profile Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('profile_title'),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocaleService.tr('profile_subtitle'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            color: AppColors.info,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            LocaleService.tr('edit_profile_btn'),
                            style: const TextStyle(
                              color: AppColors.info,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // 1. Language Selector Card
              ProfileLanguageCard(
                onLanguageChanged: () => setState(() {}),
              ),

              const SizedBox(height: AppSpacing.md),

              // 2. User Hero Card
              ProfileHeroCard(
                profile: _profile,
                isGuest: _isGuest,
                getGoalDisplayName: _getGoalDisplayName,
                onTap: _showEditProfileDialog,
              ),

              const SizedBox(height: AppSpacing.md),

              // 3. Achievements & Badges Entry Card
              const ProfileAchievementsCard(),

              const SizedBox(height: AppSpacing.md),

              // 4. Account & Cloud Sync Status Card
              ProfileAccountSyncCard(
                isGuest: _isGuest,
                isSigningIn: _isSigningIn,
                onGoogleSignIn: _handleGoogleSignInFromProfile,
                onSignOut: _confirmSignOut,
                defaultUserName: _profile.name,
              ),

              const SizedBox(height: 18),

              // 5. Background Running & Battery Optimization Card
              ProfileBatteryCard(
                isBatteryExempt: _isBatteryExempt,
                onRequestBatteryOptimization: _requestBatteryOptimization,
              ),

              const SizedBox(height: 18),

              // 6. Body Metrics & BMI Dial
              ProfileBiometricsCard(
                profile: _profile,
                bmi: bmi,
                bmiColor: bmiColor,
                weightDiff: weightDiff,
              ),

              const SizedBox(height: 18),

              // 7. Goal Selection Matrix
              ProfileGoalSelectorCard(
                currentGoal: _profile.fitnessGoal,
                onGoalSelected: _updateGoal,
              ),

              const SizedBox(height: 18),

              // 8. Personalized Macro Blueprint
              ProfileMacroBlueprintCard(
                targetMacros: targetMacros,
                userWeight: _profile.weight,
              ),

              const SizedBox(height: 18),

              // 9. App-Wide AI Interconnection Status
              ProfileAiInterconnectionCard(
                profile: _profile,
                getGoalDisplayName: _getGoalDisplayName,
              ),

              const SizedBox(height: AppSpacing.lg),

              // 10. Bottom Sign Out Action (if signed in)
              if (user != null || _isGuest)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLogout01,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    label: Text(
                      LocaleService.tr('sign_out_btn'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
