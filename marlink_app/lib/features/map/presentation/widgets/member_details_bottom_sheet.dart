import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haversine_calculator.dart';
import '../../../../core/widgets/marlink_avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/member_location_model.dart';

class MemberDetailsBottomSheet extends StatelessWidget {
  final MemberLocationModel member;
  final double? distanceMeters;
  final VoidCallback onSendMessage;
  final VoidCallback onSendAlert;
  final VoidCallback onVoiceCall;
  final VoidCallback? onTraceDirections;

  const MemberDetailsBottomSheet({
    super.key,
    required this.member,
    this.distanceMeters,
    required this.onSendMessage,
    required this.onSendAlert,
    required this.onVoiceCall,
    this.onTraceDirections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final distanceStr = distanceMeters != null
        ? HaversineCalculator.formatDistance(distanceMeters!)
        : 'Distance calculating...';

    final speedStr = HaversineCalculator.formatSpeed(member.speed);
    final directionStr = HaversineCalculator.headingToCardinal(member.heading);
    final relativeTimeStr = HaversineCalculator.formatRelativeTime(member.recordedAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Member Header
          Row(
            children: [
              MarLinkAvatar(
                imageUrl: member.avatarUrl,
                name: member.displayName,
                radius: 28,
                showOnlineIndicator: true,
                isOnline: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${member.username}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(status: 'sharing'),
            ],
          ),
          const SizedBox(height: 20),

          // Telemetry Grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTelemetryTile(
                        icon: Icons.near_me_outlined,
                        label: 'Distance',
                        value: distanceStr,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildTelemetryTile(
                        icon: Icons.speed_outlined,
                        label: 'Speed',
                        value: speedStr,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTelemetryTile(
                        icon: Icons.explore_outlined,
                        label: 'Direction',
                        value: directionStr,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildTelemetryTile(
                        icon: Icons.battery_charging_full_outlined,
                        label: 'Battery',
                        value: member.batteryPct != null ? '${member.batteryPct}%' : 'N/A',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last updated $relativeTimeStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Primary GPS Trace & Direction Button
          if (onTraceDirections != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTraceDirections,
                icon: const Icon(Icons.near_me, size: 20),
                label: const Text(
                  'Trace & GPS Directions',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandSky,
                  foregroundColor: AppColors.brandNavy,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSendMessage,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSendAlert,
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
                  label: const Text('Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertWarning,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onVoiceCall,
                icon: const Icon(Icons.call_outlined),
                tooltip: 'Voice Call',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? AppColors.brandSky : AppColors.brandBlue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
