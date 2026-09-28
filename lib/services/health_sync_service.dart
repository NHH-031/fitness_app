import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/step_repository.dart';

/// Trạng thái kết nối Google Health Connect / Apple Health
enum HealthSyncStatus {
  disconnected,
  connecting,
  connected,
  unsupported,
  error,
}

/// Dữ liệu đo đạc sức khỏe từ thiết bị đeo (Wearables / Smartwatches)
class HealthSnapshot {
  final int? steps;
  final int? heartRateBpm;
  final double? sleepHours;
  final int? activeCalories;
  final DateTime? lastSyncTime;
  final bool isConnected;
  final String? errorMessage;

  const HealthSnapshot({
    this.steps,
    this.heartRateBpm,
    this.sleepHours,
    this.activeCalories,
    this.lastSyncTime,
    this.isConnected = false,
    this.errorMessage,
  });

  HealthSnapshot copyWith({
    int? steps,
    int? heartRateBpm,
    double? sleepHours,
    int? activeCalories,
    DateTime? lastSyncTime,
    bool? isConnected,
    String? errorMessage,
  }) {
    return HealthSnapshot(
      steps: steps ?? this.steps,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      sleepHours: sleepHours ?? this.sleepHours,
      activeCalories: activeCalories ?? this.activeCalories,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Service tích hợp Google Health Connect (Android) và Apple Health (iOS)
/// Hỗ trợ tự động đồng bộ nhịp tim, giấc ngủ, calo tiêu hao và bước chân từ Smartwatch/Wearables
class HealthSyncService extends ChangeNotifier {
  HealthSyncService._();
  static final HealthSyncService instance = HealthSyncService._();

  static const String _prefKeyConnected = 'health_sync_connected';
  static const String _prefKeyLastSync = 'health_sync_last_time';
  static const String _prefKeyLastSteps = 'health_sync_last_steps';
  static const String _prefKeyLastHeartRate = 'health_sync_last_heart_rate';
  static const String _prefKeyLastSleep = 'health_sync_last_sleep';
  static const String _prefKeyLastCal = 'health_sync_last_active_cal';

  HealthSnapshot _snapshot = const HealthSnapshot();
  HealthSnapshot get snapshot => _snapshot;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  HealthSyncStatus _status = HealthSyncStatus.disconnected;
  HealthSyncStatus get status => _status;

  final Health _health = Health();

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
  ];

  static final List<HealthDataAccess> _dataAccess =
      List.filled(_dataTypes.length, HealthDataAccess.READ);

  /// Khởi tạo trạng thái từ lưu trữ cục bộ
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConnected = prefs.getBool(_prefKeyConnected) ?? false;
      final lastSyncStr = prefs.getString(_prefKeyLastSync);
      final steps = prefs.getInt(_prefKeyLastSteps);
      final hr = prefs.getInt(_prefKeyLastHeartRate);
      final sleep = prefs.getDouble(_prefKeyLastSleep);
      final cal = prefs.getInt(_prefKeyLastCal);

      DateTime? lastSync;
      if (lastSyncStr != null) {
        lastSync = DateTime.tryParse(lastSyncStr);
      }

      _snapshot = HealthSnapshot(
        steps: steps,
        heartRateBpm: hr,
        sleepHours: sleep,
        activeCalories: cal,
        lastSyncTime: lastSync,
        isConnected: isConnected,
      );

      _status = isConnected ? HealthSyncStatus.connected : HealthSyncStatus.disconnected;
      notifyListeners();
    } catch (e) {
      debugPrint('HealthSyncService init error: $e');
    }
  }

  /// Yêu cầu cấp quyền và kết nối Health Connect / Apple Health
  Future<bool> connect() async {
    try {
      _status = HealthSyncStatus.connecting;
      notifyListeners();

      // Chỉ chạy trên thiết bị di động thực tế (Android / iOS)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _health.configure();

        if (Platform.isAndroid) {
          final isAvailable = await _health.isHealthConnectAvailable();
          if (!isAvailable) {
            _status = HealthSyncStatus.unsupported;
            _snapshot = _snapshot.copyWith(
              isConnected: false,
              errorMessage: 'Google Health Connect chưa được cài đặt trên thiết bị.',
            );
            notifyListeners();
            return false;
          }
        }

        final granted = await _health.requestAuthorization(
          _dataTypes,
          permissions: _dataAccess,
        );

        if (granted) {
          _status = HealthSyncStatus.connected;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_prefKeyConnected, true);
          _snapshot = _snapshot.copyWith(isConnected: true, errorMessage: null);
          notifyListeners();

          // Thực hiện đồng bộ ngay lần đầu kết nối
          await syncNow();
          return true;
        } else {
          _status = HealthSyncStatus.disconnected;
          _snapshot = _snapshot.copyWith(
            isConnected: false,
            errorMessage: 'Người dùng từ chối quyền truy cập dữ liệu sức khỏe.',
          );
          notifyListeners();
          return false;
        }
      } else {
        // Môi trường desktop / simulator / web mô phỏng kết nối an toàn
        _status = HealthSyncStatus.connected;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKeyConnected, true);
        _snapshot = _snapshot.copyWith(isConnected: true, errorMessage: null);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Health connect error: $e');
      _status = HealthSyncStatus.error;
      _snapshot = _snapshot.copyWith(
        isConnected: false,
        errorMessage: 'Lỗi khi kết nối Health Connect: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// Ngắt kết nối Health Connect
  Future<void> disconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyConnected, false);
      _status = HealthSyncStatus.disconnected;
      _snapshot = _snapshot.copyWith(isConnected: false);
      notifyListeners();
    } catch (e) {
      debugPrint('Health disconnect error: $e');
    }
  }

  /// Đồng bộ dữ liệu mới nhất từ Health Connect / Apple Health
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);

      int? steps;
      int? heartRate;
      double? sleepHours;
      int? activeCalories;

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // 1. Lấy số bước chân trong ngày
        try {
          final totalSteps = await _health.getTotalStepsInInterval(startOfToday, now);
          if (totalSteps != null && totalSteps > 0) {
            steps = totalSteps;
            // Cập nhật số bước vào StepRepository nếu lớn hơn bước hiện tại
            final currentSteps = await StepRepository.instance.getTodaySteps();
            if (steps > currentSteps) {
              await StepRepository.instance.saveTodaySteps(steps);
            }
          }
        } catch (e) {
          debugPrint('Health steps fetch error: $e');
        }

        // 2. Lấy nhịp tim gần nhất (24h qua)
        try {
          final hrData = await _health.getHealthDataFromTypes(
            types: [HealthDataType.HEART_RATE],
            startTime: now.subtract(const Duration(hours: 24)),
            endTime: now,
          );
          if (hrData.isNotEmpty) {
            hrData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
            final latest = hrData.first;
            if (latest.value is NumericHealthValue) {
              heartRate = (latest.value as NumericHealthValue).numericValue.toInt();
            }
          }
        } catch (e) {
          debugPrint('Health heart rate fetch error: $e');
        }

        // 3. Lấy dữ liệu giấc ngủ (24h qua)
        try {
          final sleepData = await _health.getHealthDataFromTypes(
            types: [HealthDataType.SLEEP_SESSION],
            startTime: now.subtract(const Duration(hours: 24)),
            endTime: now,
          );
          if (sleepData.isNotEmpty) {
            int totalSleepMinutes = 0;
            for (final s in sleepData) {
              totalSleepMinutes += s.dateTo.difference(s.dateFrom).inMinutes;
            }
            if (totalSleepMinutes > 0) {
              sleepHours = double.parse((totalSleepMinutes / 60.0).toStringAsFixed(1));
            }
          }
        } catch (e) {
          debugPrint('Health sleep fetch error: $e');
        }

        // 4. Lấy calo tiêu hao hoạt động
        try {
          final calData = await _health.getHealthDataFromTypes(
            types: [HealthDataType.ACTIVE_ENERGY_BURNED],
            startTime: startOfToday,
            endTime: now,
          );
          if (calData.isNotEmpty) {
            double totalCal = 0;
            for (final c in calData) {
              if (c.value is NumericHealthValue) {
                totalCal += (c.value as NumericHealthValue).numericValue.toDouble();
              }
            }
            if (totalCal > 0) {
              activeCalories = totalCal.round();
            }
          }
        } catch (e) {
          debugPrint('Health active cal fetch error: $e');
        }
      }

      // Lưu vào cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastSync, now.toIso8601String());
      if (steps != null) await prefs.setInt(_prefKeyLastSteps, steps);
      if (heartRate != null) await prefs.setInt(_prefKeyLastHeartRate, heartRate);
      if (sleepHours != null) await prefs.setDouble(_prefKeyLastSleep, sleepHours);
      if (activeCalories != null) await prefs.setInt(_prefKeyLastCal, activeCalories);

      _snapshot = HealthSnapshot(
        steps: steps ?? _snapshot.steps,
        heartRateBpm: heartRate ?? _snapshot.heartRateBpm,
        sleepHours: sleepHours ?? _snapshot.sleepHours,
        activeCalories: activeCalories ?? _snapshot.activeCalories,
        lastSyncTime: now,
        isConnected: true,
      );
    } catch (e) {
      debugPrint('Health syncNow error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
