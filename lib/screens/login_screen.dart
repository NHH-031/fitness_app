import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'main_screen.dart';
import 'onboarding_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().signInWithGoogle();
      if (!mounted) return;

      if (credential != null && credential.user != null) {
        // Đăng nhập thành công -> Xóa cờ khách và đồng bộ dữ liệu với Firestore
        await StorageService.setGuestMode(false);
        await FirestoreService().syncOnLogin();
        MainScreen.reloadTabs();

        final hasOnboarded = await StorageService.hasCompletedOnboarding();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => hasOnboarded
                ? const MainScreen()
                : const OnboardingProfileScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final isVi = LocaleService.isVietnamese;
      String errorMsg = isVi
          ? 'Đăng nhập Google không thành công. Vui lòng thử lại.'
          : 'Google Sign-In failed. Please try again.';
      if (e.toString().contains('network') || e.toString().contains('Connectivity') || e.toString().contains('IOException')) {
        errorMsg = isVi
            ? 'Lỗi kết nối mạng khi xác thực Google. Vui lòng kiểm tra Wifi/4G.'
            : 'Network error during Google sign in. Please check your connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: AppTheme.font(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleContinueAsGuest() async {
    await StorageService.setGuestMode(true);
    final hasOnboarded = await StorageService.hasCompletedOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasOnboarded
            ? const MainScreen()
            : const OnboardingProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = LocaleService.isVietnamese;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Hero App Icon with Gradient Glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFF3B30),
                      Color(0xFF8B0000),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withAlpha(100),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Title & Subtitle
              Text(
                'FITNESS TRACKER',
                style: AppTheme.font(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                isVi
                    ? 'Chinh phục mục tiêu • Đồng bộ dữ liệu mọi lúc mọi nơi'
                    : 'Conquer your fitness goals • Sync data everywhere',
                textAlign: TextAlign.center,
                style: AppTheme.font(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),

              const Spacer(flex: 2),

              // Feature Badges
              _buildFeatureRow(
                icon: Icons.cloud_sync_rounded,
                color: const Color(0xFF00C6FF),
                text: isVi
                    ? 'Tự động sao lưu lịch sử tập & dinh dưỡng'
                    : 'Auto-backup workouts & nutrition history',
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFFFD700),
                text: isVi
                    ? 'Phân tích AI thông minh & tính Macro'
                    : 'AI-powered smart insights & Macro calculations',
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF3B30),
                text: isVi
                    ? 'Duy trì chuỗi Streak & Huy hiệu thành tích'
                    : 'Maintain workout streaks & unlock achievements',
              ),

              const Spacer(flex: 3),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    shadowColor: Colors.black45,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
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
                            // Google Icon
                            _buildGoogleIcon(),
                            const SizedBox(width: 14),
                            Text(
                              isVi ? 'Đăng nhập với Google' : 'Sign in with Google',
                              style: AppTheme.font(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // Guest Mode Button
              TextButton(
                onPressed: _isLoading ? null : _handleContinueAsGuest,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: Text(
                  isVi
                      ? 'Dùng thử không cần đăng nhập (Chế độ Khách)'
                      : 'Continue as Guest (Offline Mode)',
                  style: AppTheme.font(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTheme.font(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(220),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
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
      width: 22,
      height: 22,
      child: SvgPicture.string(googleSvg),
    );
  }
}
