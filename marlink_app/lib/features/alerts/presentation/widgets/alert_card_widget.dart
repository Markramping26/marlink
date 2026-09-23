import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haversine_calculator.dart';
import '../../../../core/widgets/marlink_avatar.dart';
import '../../domain/models/alert_model.dart';

class AlertCardWidget extends StatelessWidget {
  final AlertModel alert;
  final bool isSenderMe;
  final VoidCallback onAcknowledge;
  final VoidCallback onCancel;

  const AlertCardWidget({
    super.key,
    required this.alert,
    required this.isSenderMe,
    required this.onAcknowledge,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSos = alert.isSos;
    final accentColor = isSos ? AppColors.alertEmergency : AppColors.alertWarning;
    final timeStr = HaversineCalculator.formatRelativeTime(alert.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: alert.isActive
              ? accentColor.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: alert.isActive ? 1.5 : 1.0,
        ),
        boxShadow: alert.isActive
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSos ? Icons.emergency_rounded : Icons.notifications_active_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSos ? 'EMERGENCY SOS BROADCAST' : 'ATTENTION ALERT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: alert.isActive
                      ? accentColor.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                  borderRadius: BorderRadius.circular(8),
                  border: alert.isActive
                      ? Border.all(color: accentColor.withValues(alpha: 0.4))
                      : null,
                ),
                child: Text(
                  alert.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: alert.isActive ? accentColor : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sender information
          Row(
            children: [
              MarLinkAvatar(
                imageUrl: alert.senderAvatar,
                name: alert.senderName,
                radius: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'From: ${alert.senderName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (alert.targetUserName != null)
                Text(
                  'To: ${alert.targetUserName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
            ],
          ),

          if (alert.metadata?['note'] != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                alert.metadata!['note'].toString(),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],

          if (alert.isActive) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSenderMe && isSos)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel SOS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAcknowledge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Acknowledge', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
