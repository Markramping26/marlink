import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marlink_app/core/theme/app_colors.dart';
import 'package:marlink_app/core/widgets/marlink_button.dart';
import 'package:marlink_app/features/auth/providers/auth_provider.dart';
import 'package:marlink_app/features/map/providers/location_provider.dart';
import 'package:marlink_app/features/rooms/providers/room_provider.dart';
import 'package:marlink_app/features/alerts/providers/alert_provider.dart';
import 'widgets/alert_card_widget.dart';
import 'widgets/attention_alert_modal.dart';
import 'widgets/sos_press_hold_button.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  void _showAttentionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AttentionAlertModal(),
    );
  }

  void _triggerSos(BuildContext context, WidgetRef ref) async {
    final mapNotifier = ref.read(mapNotifierProvider.notifier);
    var mapState = ref.read(mapNotifierProvider);
    var pos = mapState.myPosition;

    if (pos == null) {
      pos = await mapNotifier.captureCurrentPosition(openSettingsIfDisabled: false);
      mapState = ref.read(mapNotifierProvider);
    }

    final lat = pos?.latitude ?? (mapState.myLatLng?.latitude ?? 0.0);
    final lng = pos?.longitude ?? (mapState.myLatLng?.longitude ?? 0.0);
    final speedKmh = (pos != null && pos.speed >= 0) ? pos.speed * 3.6 : null;

    final success = await ref.read(alertNotifierProvider.notifier).triggerSos(
          latitude: lat,
          longitude: lng,
          speed: speedKmh,
          batteryPct: mapState.myBattery,
          note: 'Emergency SOS activated from MarLink Safety Hub',
        );

    if (context.mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('SOS Broadcast Active'),
              ],
            ),
            content: const Text(
              'Your emergency alert and current GPS location have been broadcast to all members in your active room.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertState = ref.watch(alertNotifierProvider);
    final currentUserId = ref.watch(authNotifierProvider).user?.id;
    final currentRoom = ref.watch(roomsNotifierProvider).currentRoom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Send Attention Alert',
            onPressed: () => _showAttentionModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // SOS Emergency Section Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.alertEmergency.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.alertEmergency.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.alertEmergency.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: AppColors.alertEmergency),
                        SizedBox(width: 5),
                        Text(
                          'SAFETY NETWORK COMMAND',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.alertEmergency,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Emergency SOS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Press and hold for 3 seconds to alert "${currentRoom?.name ?? 'your circle'}" with your live coordinates, battery level, and speed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SosPressHoldButton(
                    onActivated: () => _triggerSos(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attention Alert Trigger
            MarLinkButton(
              text: 'Send Attention Alert to Member',
              icon: Icons.notifications_none_rounded,
              variant: MarLinkButtonVariant.secondary,
              onPressed: () => _showAttentionModal(context),
            ),
            const SizedBox(height: 28),

            // Active & Recent Alerts Section
            Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 20, color: AppColors.brandSky),
                const SizedBox(width: 8),
                const Text(
                  'Recent Alerts',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${alertState.activeAlerts.length} recorded',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (alertState.activeAlerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 38,
                      color: AppColors.statusOnline.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All Clear',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No active or recent alerts in this circle.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alertState.activeAlerts.map((alert) {
                final isMe = alert.senderId == currentUserId;
                return AlertCardWidget(
                  alert: alert,
                  isSenderMe: isMe,
                  onAcknowledge: () {
                    ref.read(alertNotifierProvider.notifier).acknowledgeAlert(alert.id);
                  },
                  onCancel: () {
                    ref.read(alertNotifierProvider.notifier).cancelSos(alert.id);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
