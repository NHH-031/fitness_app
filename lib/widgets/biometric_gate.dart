import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/biometric_service.dart';
import '../services/locale_service.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';

class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLocked) {
      _promptAuth();
    }
  }

  Future<void> _checkLockStatus() async {
    final enabled = await BiometricService.instance.isAppLockEnabled();
    if (!enabled) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isLocked = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isLocked = true;
      });
      _promptAuth();
    }
  }

  Future<void> _promptAuth() async {
    final success = await BiometricService.instance.authenticate(
      reason: LocaleService.isVietnamese
          ? 'Xác thực sinh trắc học để mở khóa Fitness Tracker'
          : 'Biometric authentication to unlock Fitness Tracker',
    );
    if (success && mounted) {
      AppHaptics.success();
      setState(() {
        _isLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.info)),
      );
    }

    if (_isLocked) {
      final isVi = LocaleService.isVietnamese;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.info.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.info, width: 2),
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedFingerPrint,
                        color: AppColors.info,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isVi ? 'Ứng dụng đã được khóa' : 'App is Locked',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVi
                        ? 'Vui lòng xác thực vân tay hoặc khuôn mặt để tiếp tục'
                        : 'Please authenticate with fingerprint or face to proceed',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton.icon(
                    onPressed: _promptAuth,
                    icon: const Icon(Icons.lock_open_rounded, size: 20),
                    label: Text(
                      isVi ? 'MỞ KHÓA BẰNG VÂN TAY' : 'UNLOCK APP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
