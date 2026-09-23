import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LocationPrivacyBar extends StatelessWidget {
  final String sharingStatus; // 'on', 'paused', 'off'
  final VoidCallback onToggleSharing;

  const LocationPrivacyBar({
    super.key,
    required this.sharingStatus,
    required this.onToggleSharing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    switch (sharingStatus.toLowerCase()) {
      case 'on':
        statusColor = AppColors.statusOnline;
        statusTitle = 'Location Sharing: ACTIVE';
        statusSubtitle = 'Members in your active group can see your live position';
        statusIcon = Icons.sensors_rounded;
        break;
      case 'paused':
        statusColor = AppColors.alertWarning;
        statusTitle = 'Location Sharing: PAUSED';
        statusSubtitle = 'Your live location stream is temporarily paused';
        statusIcon = Icons.pause_circle_outline_rounded;
        break;
      case 'off':
      default:
        statusColor = AppColors.alertEmergency;
        statusTitle = 'Location Sharing: OFF';
        statusSubtitle = 'Nobody can see your current location';
        statusIcon = Icons.location_off_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onToggleSharing,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
