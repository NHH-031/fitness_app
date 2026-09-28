import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/achievements_sheet.dart';
import '../utils/app_haptics.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
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
            const HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: Colors.redAccent, size: 24),
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
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              LocaleService.tr('cancel_btn'),
              style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    if (bmi < 24.9) return const Color(0xFF00F0FF);
    if (bmi < 29.9) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(
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
                  const HugeIcon(icon: HugeIcons.strokeRoundedCloudSavingDone01, color: Color(0xFF00F0FF), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      LocaleService.isVietnamese
                          ? 'Đã lưu hồ sơ & đồng bộ Firebase, AI thành công!'
                          : 'Profile updated & synced to Cloud & AI successfully!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E1E2C),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF00F0FF), width: 0.8),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final targetMacros = _profile.targetMacros;
    final bmi = _profile.bmi;
    final bmiColor = _getBmiColor(bmi);
    final weightDiff = _profile.weight - _profile.targetWeight;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('profile_title'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppTheme.textPrimaryColor,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocaleService.tr('profile_subtitle'),
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            color: Color(0xFF00F0FF),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LocaleService.tr('edit_profile_btn'),
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
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

              const SizedBox(height: 16),

              // 1. Language Selector Card
              _buildLanguageSelectorCard(),

              const SizedBox(height: 16),

              // 2. User Hero Card
              GestureDetector(
                onTap: _showEditProfileDialog,
                behavior: HitTestBehavior.opaque,
                child: _buildUserHeroCard(),
              ),

              const SizedBox(height: 16),

              // 2.3 Achievements & Badges Entry Card
              _buildAchievementsCard(),

              const SizedBox(height: 16),

              // 2.5 Account & Cloud Sync Status Card
              _buildAccountAndSyncCard(),

              const SizedBox(height: 18),

              // 2.6 Background Running & Battery Optimization Card
              _buildBackgroundOptimizationCard(),

              const SizedBox(height: 18),

              // 3. Body Metrics & BMI Dial
              _buildBiometricsCard(bmi, bmiColor, weightDiff),

              const SizedBox(height: 18),

              // 4. Goal Selection Matrix
              _buildGoalSelector(),

              const SizedBox(height: 18),

              // 5. Personalized Macro Blueprint
              _buildMacroBlueprintCard(targetMacros),

              const SizedBox(height: 18),

              // 6. App-Wide AI Interconnection Status
              _buildAiInterconnectionCard(),

              const SizedBox(height: 24),

              // 7. Bottom Sign Out / Exit Action
              _buildBottomAction(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    final isVi = LocaleService.isVietnamese;
    return GestureDetector(
      onTap: () {
        AppHaptics.medium();
        AchievementsSheet.show(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedChampion,
                color: Color(0xFFFFD700),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVi ? 'BẢNG THÀNH TÍCH & HUY HIỆU' : 'ACHIEVEMENTS & BADGES',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVi ? 'Xem huy hiệu đã mở khóa & thử thách' : 'View unlocked badges & challenges',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFD700), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectorCard() {
    final currentLang = LocaleService.currentLanguage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
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
                color: Color(0xFF00F0FF),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                LocaleService.tr('language_section_title'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppTheme.textPrimaryColor,
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
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              _buildLanguageOption(
                flag: '🇬🇧',
                label: 'EN',
                isSelected: currentLang == 'en',
                onTap: () async {
                  await LocaleService.setLanguage('en');
                  await StorageService.saveAppLanguage('en');
                  setState(() {});
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
              ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
              : const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
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
                color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeroCard() {
    final isMale = _profile.gender.toLowerCase() == 'male';
    final user = AuthService().currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Avatar (loads Google photoURL if signed in)
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 72,
                height: 72,
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
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF161622),
                  ),
                  child: ClipOval(
                    child: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                        ? Image.network(
                            user.photoURL!,
                            width: 66,
                            height: 66,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                isMale
                                    ? Icons.sports_gymnastics_rounded
                                    : Icons.fitness_center_rounded,
                                color: const Color(0xFF00F0FF),
                                size: 34,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              isMale
                                  ? Icons.sports_gymnastics_rounded
                                  : Icons.fitness_center_rounded,
                              color: const Color(0xFF00F0FF),
                              size: 34,
                            ),
                          ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isMale ? Colors.blueAccent : Colors.pinkAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(
                  isMale ? Icons.male_rounded : Icons.female_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        (user?.displayName != null && user!.displayName!.isNotEmpty)
                            ? user.displayName!
                            : _profile.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        LocaleService.tr('years_old', args: {'age': _profile.age.toString()}),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                    ),
                    if (_isGuest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          LocaleService.isVietnamese ? 'Khách' : 'Guest',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (user?.email != null && user!.email!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF00F0FF)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.email!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  LocaleService.tr('height_weight_summary', args: {
                    'height': _profile.height.toStringAsFixed(0),
                    'weight': _profile.weight.toStringAsFixed(1),
                    'target': _profile.targetWeight.toStringAsFixed(1),
                  }),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D00FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF9D00FF).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    LocaleService.tr('goal_tag',
                        args: {'goal': _getGoalDisplayName(_profile.fitnessGoal)}),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFFD68BFD),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountAndSyncCard() {
    final user = AuthService().currentUser;
    final isGoogleUser = user != null;

    if (!isGoogleUser || _isGuest) {
      // Guest Mode banner
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1C0C), Color(0xFF1A141A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amberAccent.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.08),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedCloudUpload, color: Colors.amberAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('guest_mode_title'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocaleService.tr('guest_mode_subtitle'),
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
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSigningIn ? null : _handleGoogleSignInFromProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSigningIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleIconSmall(),
                          const SizedBox(width: 10),
                          Text(
                            LocaleService.tr('sign_in_google_btn'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    }

    // Google Signed-In Account Card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedCloudSavingDone01, color: Color(0xFF00F0FF), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        LocaleService.tr('account_section_title'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LocaleService.isVietnamese ? 'Cloud Firestore' : 'Synced',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C853),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildGoogleIconSmall(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? _profile.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _confirmSignOut,
                tooltip: LocaleService.tr('sign_out_btn'),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIconSmall() {
    const String googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';
    return SizedBox(
      width: 18,
      height: 18,
      child: SvgPicture.string(googleSvg),
    );
  }

  Widget _buildBottomAction() {
    final user = AuthService().currentUser;
    if (user == null && !_isGuest) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmSignOut,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedLogout01, size: 18, color: Colors.redAccent),
        label: Text(
          LocaleService.tr('sign_out_btn'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBackgroundOptimizationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isBatteryExempt
              ? const Color(0xFF00FFA3).withValues(alpha: 0.3)
              : const Color(0xFFFF9E00).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isBatteryExempt
                      ? const Color(0xFF00FFA3).withValues(alpha: 0.15)
                      : const Color(0xFFFF9E00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedEnergy,
                  color: _isBatteryExempt
                      ? const Color(0xFF00FFA3)
                      : const Color(0xFFFF9E00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocaleService.tr('background_service_title'),
                  style: AppTheme.font(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _isBatteryExempt
                      ? const Color(0xFF00FFA3).withValues(alpha: 0.15)
                      : const Color(0xFFFF9E00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isBatteryExempt
                        ? const Color(0xFF00FFA3).withValues(alpha: 0.35)
                        : const Color(0xFFFF9E00).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isBatteryExempt
                            ? const Color(0xFF00FFA3)
                            : const Color(0xFFFF9E00),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isBatteryExempt
                          ? LocaleService.tr('battery_optimized_badge')
                          : LocaleService.tr('battery_need_permission_badge'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _isBatteryExempt
                            ? const Color(0xFF00FFA3)
                            : const Color(0xFFFF9E00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isBatteryExempt
                ? LocaleService.tr('battery_optimized_active')
                : LocaleService.tr('battery_optimize_prompt'),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          if (!_isBatteryExempt) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestBatteryOptimization,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedZap,
                  size: 16,
                  color: Colors.black,
                ),
                label: Text(
                  LocaleService.tr('battery_optimize_action'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9E00),
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiometricsCard(double bmi, Color bmiColor, double weightDiff) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedDashboardSpeed01, color: Color(0xFF00F0FF), size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleService.tr('biometrics_card_title'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // BMI & Status Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('bmi_title'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: bmiColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 40, color: Colors.white12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile.bmiCategory,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: bmiColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weightDiff.abs() < 0.5
                            ? LocaleService.tr('weight_diff_perfect')
                            : weightDiff > 0
                                ? LocaleService.tr('weight_diff_lose',
                                    args: {'amount': weightDiff.toStringAsFixed(1)})
                                : LocaleService.tr('weight_diff_gain',
                                    args: {'amount': (-weightDiff).toStringAsFixed(1)}),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // BMR & TDEE 2-column Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: LocaleService.tr('bmr_title'),
                  value: '${_profile.bmr.round()} kcal',
                  subtext: LocaleService.tr('bmr_sub'),
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: LocaleService.tr('tdee_title'),
                  value: '${_profile.tdee.round()} kcal',
                  subtext: LocaleService.tr('tdee_sub'),
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    final goals = [
      {
        'id': 'cutting',
        'name': LocaleService.tr('goal_cutting_name'),
        'hugeIcon': HugeIcons.strokeRoundedTarget01,
        'iconColor': const Color(0xFFFF3B30),
        'sub': LocaleService.tr('goal_cutting_sub'),
      },
      {
        'id': 'bulking',
        'name': LocaleService.tr('goal_bulking_name'),
        'hugeIcon': HugeIcons.strokeRoundedBodyPartMuscle,
        'iconColor': const Color(0xFFFFD700),
        'sub': LocaleService.tr('goal_bulking_sub'),
      },
      {
        'id': 'balanced',
        'name': LocaleService.tr('goal_balanced_name'),
        'hugeIcon': HugeIcons.strokeRoundedBalanceScale,
        'iconColor': const Color(0xFF00F0FF),
        'sub': LocaleService.tr('goal_balanced_sub'),
      },
      {
        'id': 'endurance',
        'name': LocaleService.tr('goal_endurance_name'),
        'hugeIcon': HugeIcons.strokeRoundedRunningShoes,
        'iconColor': const Color(0xFF34C759),
        'sub': LocaleService.tr('goal_endurance_sub'),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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
                  const HugeIcon(icon: HugeIcons.strokeRoundedFlag01, color: Color(0xFF9D00FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    LocaleService.tr('fitness_goal_title'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D00FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  LocaleService.tr('tap_to_change'),
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFFD68BFD), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: goals.map((g) {
              final isSelected = _profile.fitnessGoal == g['id'];
              return GestureDetector(
                onTap: () => _updateGoal(g['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF9D00FF).withValues(alpha: 0.2)
                        : const Color(0xFF14141E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF9D00FF)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (g['iconColor'] as Color).withValues(alpha: isSelected ? 0.25 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: HugeIcon(
                          icon: g['hugeIcon'] as List<List<dynamic>>,
                          color: g['iconColor'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                            Text(
                              g['sub'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? const Color(0xFFD68BFD) : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          color: Color(0xFF00F0FF),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBlueprintCard(Map<String, int> targetMacros) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedPieChart, color: Color(0xFF00F0FF), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleService.tr('macro_blueprint_title'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.textPrimaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${targetMacros['calories']} ${LocaleService.tr('per_day')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00F0FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMacroNutrientTile(
                  name: LocaleService.tr('macro_protein_short'),
                  grams: targetMacros['protein'] ?? 0,
                  color: const Color(0xFF00F0FF),
                  note: '${(_profile.weight > 0 ? (targetMacros['protein']! / _profile.weight).toStringAsFixed(1) : '2.0')}g/kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroNutrientTile(
                  name: LocaleService.tr('macro_carbs_short'),
                  grams: targetMacros['carbs'] ?? 0,
                  color: const Color(0xFFFFB800),
                  note: LocaleService.isVietnamese ? 'Năng lượng' : 'Energy',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroNutrientTile(
                  name: LocaleService.tr('macro_fat_short'),
                  grams: targetMacros['fat'] ?? 0,
                  color: const Color(0xFFFF0055),
                  note: LocaleService.isVietnamese ? 'Nội tiết' : 'Hormones',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocaleService.tr('macro_note'),
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroNutrientTile({
    required String name,
    required int grams,
    required Color color,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${grams}g',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInterconnectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9D00FF).withValues(alpha: 0.15),
            const Color(0xFF00F0FF).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF9D00FF).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedAiSparkles, color: Color(0xFF00F0FF), size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleService.tr('ai_integration_title'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_activity'),
            status: LocaleService.tr('ai_sync_activity', args: {
              'age': _profile.age.toString(),
              'gender': _profile.gender == 'male'
                  ? LocaleService.tr('field_male')
                  : LocaleService.tr('field_female'),
              'goal': _getGoalDisplayName(_profile.fitnessGoal),
            }),
            hugeIcon: HugeIcons.strokeRoundedDumbbell01,
          ),
          const SizedBox(height: 8),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_food'),
            status: LocaleService.tr('ai_sync_food', args: {
              'cal': _profile.targetCalories.toString(),
            }),
            hugeIcon: HugeIcons.strokeRoundedApple01,
          ),
          const SizedBox(height: 8),
          _buildAiSyncItem(
            tabName: LocaleService.tr('nav_dashboard'),
            status: LocaleService.tr('ai_sync_dashboard', args: {
              'bmr': _profile.bmr.round().toString(),
            }),
            hugeIcon: HugeIcons.strokeRoundedHome01,
          ),
        ],
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
            color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HugeIcon(icon: hugeIcon, color: const Color(0xFF00F0FF), size: 14),
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

class _EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onSaved;

  const _EditProfileSheet({
    required this.profile,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
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
    _heightController = TextEditingController(text: widget.profile.height.toStringAsFixed(0));
    _weightController = TextEditingController(text: widget.profile.weight.toStringAsFixed(1));
    _targetWeightController =
        TextEditingController(text: widget.profile.targetWeight.toStringAsFixed(1));
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
      final updated = widget.profile.copyWith(
        name: _nameController.text.trim(),
        gender: _gender,
        age: int.tryParse(_ageController.text) ?? widget.profile.age,
        height: double.tryParse(_heightController.text) ?? widget.profile.height,
        weight: double.tryParse(_weightController.text) ?? widget.profile.weight,
        targetWeight:
            double.tryParse(_targetWeightController.text) ?? widget.profile.targetWeight,
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
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleService.tr('edit_profile_sheet_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                LocaleService.tr('edit_profile_sheet_sub'),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 18),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: LocaleService.tr('field_name'),
                icon: Icons.person_rounded,
                validator: (val) => val == null || val.trim().isEmpty ? LocaleService.tr('please_enter_name') : null,
              ),

              const SizedBox(height: 14),

              // Gender Selector
              Text(
                LocaleService.tr('field_gender'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
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
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        final n = double.tryParse(val ?? '');
                        if (n == null || n < 30 || n > 300) return '30-300';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _targetWeightController,
                      label: LocaleService.tr('field_target_weight'),
                      icon: Icons.flag_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
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

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                  ),
                  child: Text(
                    LocaleService.tr('save_profile_btn'),
                    style: const TextStyle(
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.15) : const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 8),
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
        prefixIcon: Icon(icon, color: const Color(0xFF00F0FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF1E1E2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
        ),
      ),
    );
  }
}
