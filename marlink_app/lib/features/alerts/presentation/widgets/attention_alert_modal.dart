import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marlink_app/core/theme/app_colors.dart';
import 'package:marlink_app/core/widgets/marlink_button.dart';
import 'package:marlink_app/core/widgets/marlink_text_field.dart';
import 'package:marlink_app/features/map/providers/location_provider.dart';
import 'package:marlink_app/features/rooms/domain/models/room_member_model.dart';
import 'package:marlink_app/features/rooms/providers/room_provider.dart';
import 'package:marlink_app/features/alerts/providers/alert_provider.dart';

class AttentionAlertModal extends ConsumerStatefulWidget {
  final RoomMemberModel? preselectedTarget;

  const AttentionAlertModal({super.key, this.preselectedTarget});

  @override
  ConsumerState<AttentionAlertModal> createState() => _AttentionAlertModalState();
}

class _AttentionAlertModalState extends ConsumerState<AttentionAlertModal> {
  String _selectedType = 'attention';
  int? _selectedTargetUserId;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  final List<Map<String, dynamic>> _alertTypes = [
    {'type': 'attention', 'label': 'Attention', 'icon': Icons.notifications_active_outlined, 'color': AppColors.alertWarning},
    {'type': 'meet_here', 'label': 'Meet Here', 'icon': Icons.place_outlined, 'color': AppColors.brandBlue},
    {'type': 'leaving', 'label': "I'm Leaving", 'icon': Icons.directions_car_outlined, 'color': AppColors.brandTeal},
    {'type': 'arrived', 'label': "I'm Here", 'icon': Icons.check_circle_outline, 'color': AppColors.statusOnline},
    {'type': 'check_on_me', 'label': 'Check on Me', 'icon': Icons.shield_outlined, 'color': AppColors.alertEmergency},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTargetUserId = widget.preselectedTarget?.userId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final mapState = ref.read(mapNotifierProvider);

    final success = await ref.read(alertNotifierProvider.notifier).sendAttention(
          targetUserId: _selectedTargetUserId,
          alertType: _selectedType,
          message: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          latitude: mapState.myPosition?.latitude,
          longitude: mapState.myPosition?.longitude,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attention alert dispatched!')),
        );
      } else {
        setState(() {
          _error = ref.read(alertNotifierProvider).errorMessage ?? 'Unable to send alert.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRoom = ref.watch(roomsNotifierProvider).currentRoom;
    final members = currentRoom?.members ?? [];

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Send Attention Alert',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Notify room members with a distinct ping and current location.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 18),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
            ],

            // Target Member Selector
            Text(
              'Select Recipient',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Entire Room'),
                    selected: _selectedTargetUserId == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTargetUserId = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...members.map((m) {
                    final isSel = _selectedTargetUserId == m.userId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m.displayName),
                        selected: isSel,
                        onSelected: (selected) {
                          setState(() => _selectedTargetUserId = selected ? m.userId : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Alert Type Selector
            Text(
              'Alert Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _alertTypes.map((item) {
                final isSel = _selectedType == item['type'];
                final color = item['color'] as Color;

                return InkWell(
                  onTap: () => setState(() => _selectedType = item['type']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? color.withValues(alpha: 0.18) : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSel ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item['icon'] as IconData, size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? (isDark ? Colors.white : Colors.black) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            MarLinkTextField(
              controller: _noteController,
              label: 'Optional Note',
              hint: 'e.g. Traffic is heavy, be there in 10 mins',
              prefixIcon: Icons.edit_note,
            ),
            const SizedBox(height: 24),

            MarLinkButton(
              text: 'Dispatch Alert',
              icon: Icons.send,
              onPressed: _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
