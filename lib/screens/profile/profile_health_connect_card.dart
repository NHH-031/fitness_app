import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/health_sync_service.dart';
import '../../services/locale_service.dart';
import '../../theme.dart';

class ProfileHealthConnectCard extends StatefulWidget {
  const ProfileHealthConnectCard({super.key});

  @override
  State<ProfileHealthConnectCard> createState() =>
      _ProfileHealthConnectCardState();
}

class _ProfileHealthConnectCardState extends State<ProfileHealthConnectCard> {
  final HealthSyncService _syncService = HealthSyncService.instance;

  @override
  void initState() {
    super.initState();
    _syncService.addListener(_onSyncUpdate);
    _syncService.init();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) setState(() {});
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _syncService.snapshot;
    final isConnected = snapshot.isConnected;
    final isSyncing = _syncService.isSyncing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.3)
              : Colors.white12,
          width: 1.2,
        ),
        boxShadow: isConnected
            ? [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.05),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.watch_rounded,
                  color: isConnected ? const Color(0xFF00F0FF) : Colors.white60,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('health_connect_title'),
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr('health_connect_sub'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF00FFA3).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected
                        ? const Color(0xFF00FFA3).withValues(alpha: 0.4)
                        : Colors.white24,
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
                        color: isConnected
                            ? const Color(0xFF00FFA3)
                            : Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isConnected
                          ? LocaleService.tr('health_connect_status_connected')
                          : LocaleService.tr('health_connect_status_not_connected'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isConnected
                            ? const Color(0xFF00FFA3)
                            : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Error Message if any
          if (snapshot.errorMessage != null && !isConnected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      snapshot.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Synced Metrics Grid when connected
          if (isConnected) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricChip(
                  label: LocaleService.tr('health_stat_heart_rate'),
                  value: snapshot.heartRateBpm != null
                      ? '${snapshot.heartRateBpm} bpm'
                      : '--',
                  icon: HugeIcons.strokeRoundedFavourite,
                  color: const Color(0xFFFF2D55),
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  label: LocaleService.tr('health_stat_sleep'),
                  value: snapshot.sleepHours != null
                      ? '${snapshot.sleepHours}h'
                      : '--',
                  icon: HugeIcons.strokeRoundedMoon,
                  color: const Color(0xFF9D4EDD),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetricChip(
                  label: LocaleService.tr('health_stat_steps'),
                  value: snapshot.steps != null ? '${snapshot.steps}' : '--',
                  icon: HugeIcons.strokeRoundedRunningShoes,
                  color: const Color(0xFF00F0FF),
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  label: LocaleService.tr('health_stat_active_cal'),
                  value: snapshot.activeCalories != null
                      ? '${snapshot.activeCalories} kcal'
                      : '--',
                  icon: HugeIcons.strokeRoundedFire,
                  color: const Color(0xFFFF9E00),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleService.tr(
                    'health_connect_last_sync',
                    args: {'time': _formatDateTime(snapshot.lastSyncTime)},
                  ),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                TextButton(
                  onPressed: () => _syncService.disconnect(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Ngắt kết nối',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Main Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: isConnected
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFF00F0FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isSyncing ? null : () => _syncService.syncNow(),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00F0FF),
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      isSyncing
                          ? 'ĐANG ĐỒNG BỘ...'
                          : LocaleService.tr('health_connect_sync_now'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _syncService.connect(),
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text(
                      'KẾT NỐI HEALTH CONNECT / WATCH',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required List<List<dynamic>> icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
