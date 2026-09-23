import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status; // 'on', 'paused', 'off', 'online', 'offline'
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String label;

    switch (status.toLowerCase()) {
      case 'on':
      case 'sharing':
        dotColor = AppColors.statusOnline;
        label = 'Sharing Live';
        break;
      case 'paused':
        dotColor = AppColors.alertWarning;
        label = 'Paused';
        break;
      case 'online':
        dotColor = AppColors.statusOnline;
        label = 'Online';
        break;
      case 'off':
      case 'offline':
      default:
        dotColor = AppColors.statusOffline;
        label = 'Offline';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: dotColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
