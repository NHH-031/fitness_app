import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/onboarding_profile_screen.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'biometric_gate.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Widget _buildScreenDecider(String sessionKey) {
    return KeyedSubtree(
      key: ValueKey(sessionKey),
      child: FutureBuilder<bool>(
        future: StorageService.hasCompletedOnboarding(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
              ),
            );
          }
          final hasOnboarded = snapshot.data ?? false;
          if (hasOnboarded) {
            return const BiometricGate(child: MainScreen());
          }
          return const OnboardingProfileScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Đang kiểm tra trạng thái khởi tạo Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            ),
          );
        }

        // Đã đăng nhập bằng tài khoản Google
        if (snapshot.hasData && snapshot.data != null) {
          return _buildScreenDecider('user_${snapshot.data!.uid}');
        }

        // Chưa đăng nhập -> Kiểm tra xem có đang ở chế độ Khách (Guest) không
        return FutureBuilder<bool>(
          future: StorageService.isGuestMode(),
          builder: (context, guestSnapshot) {
            if (guestSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                ),
              );
            }

            final isGuest = guestSnapshot.data ?? false;
            if (isGuest) {
              return _buildScreenDecider('guest_mode');
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
