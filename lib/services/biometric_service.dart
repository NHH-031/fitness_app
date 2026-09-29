import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKeyAppLock = 'biometric_app_lock_enabled';

  /// Kiểm tra thiết bị có phần cứng sinh trắc học và hỗ trợ không
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Lấy danh sách các loại sinh trắc học có sẵn trên thiết bị (Vân tay, Khuôn mặt)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Xác thực người dùng bằng vân tay / Face ID
  Future<bool> authenticate({
    String reason = 'Xác thực sinh trắc học để mở khóa Fitness Tracker',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        // Nếu thiết bị không có phần cứng, cho phép vượt qua an toàn
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  /// Kiểm tra xem người dùng có kích hoạt khóa ứng dụng bằng sinh trắc học không
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyAppLock) ?? false;
  }

  /// Bật / Tắt khóa ứng dụng bằng sinh trắc học và đồng bộ Firestore
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyAppLock, enabled);
    await FirestoreService().saveAppLockSetting(enabled);
  }
}
